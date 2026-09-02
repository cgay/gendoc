Module: gendoc

/* To be documented: command-interface, lisp-to-dylan, pacman-catalog, peg-parser,
   priority-queue, sequence-stream, serialization, shootout, skip-list, slot-visitor,
   uri, vscode-dylan, web-framework, wrapper-streams, xml-parser, xml-rpc

  skip-list has some docs in the Hackers Guide, used as example doc.

 */

define command-line <gendoc-command-line> ()
  option gendoc-directory :: <string>,
    names: #("gendoc-directory"),
    help: "Pathname to the root directory of the gendoc repository checkout. [default: .]",
    kind: <positional-option>,
    required?: #f,
    default: ".";
end;

define function verbose (fmt, #rest args)
  apply(io/format-out, concatenate(fmt, "\n"), args);
  io/force-out();
end function;

define function main
    (name :: <string>, args :: <sequence>) => (status :: false-or(<integer>))
  let parser = make(<gendoc-command-line>,
                    help: "Generate docs for packages in the Dylan catalog");
  block ()
    parse-command-line(parser, application-arguments());
    let gendoc-dir = fs/resolve-file(as(<directory-locator>, parser.gendoc-directory));
    let excludes-file = file-locator(gendoc-dir, "exclude-list.txt");
    let excludes = if (fs/file-exists?(excludes-file))
                     parse-excludes-file(excludes-file)
                   else
                     io/format-out("Excludes file %s not found; no packages will"
                                     " be excluded.\n", excludes-file);
                     #()
                   end;
    verbose("excludes: %s", excludes);
    // Put everything under one build subdirectory so the repo isn't spammed with garbage
    // files.
    let build-dir = subdirectory-locator(gendoc-dir, "_gendoc-build");
    fs/ensure-directories-exist(build-dir);
    let source-docs-dir = subdirectory-locator(gendoc-dir, "docs");
    // Copy the docs dir to the build dir before modifying it.
    let cp-command = concatenate("/bin/cp -RP ",
                                 as(<string>, file-locator(gendoc-dir, "docs")), // remove trailing slash
                                 " ",
                                 as(<string>, build-dir));                       // keep trlailing slash
    verbose("%s", cp-command);
    let status = os/run-application(cp-command);
    if (status ~== 0)
      error("Copy command failed with exit status %=: %=", status, cp-command);
    else
      gendoc(build-dir, excludes);
    end;
  exception (err :: <abort-command-error>)
    let status = exit-status(err);
    if (status ~== 0)
      io/format-err("Error: %s\n", err);
    end;
    status
  end
end function;

define function parse-excludes-file (file :: fs/<pathname>) => (_ :: <sequence>)
  fs/with-open-file (stream = file)
    iterate loop (excludes = #())
      let line = io/read-line(stream, on-end-of-stream: #f);
      if (~line)
        excludes
      else
        let line = strip(line);
        if (empty?(line) | starts-with?(line, "#"))
          loop(excludes)
        else
          loop(pair(line, excludes))
        end
      end
    end iterate
  end
end function;

define function gendoc
    (build-dir :: <directory-locator>, excludes :: <sequence>)
  dynamic-bind (deft-*verbose?* = #t)
    let target-docs-dir = subdirectory-locator(build-dir, "docs");
    let root-index-file = file-locator(target-docs-dir, "source", "index.rst");
    let packages = fetch-packages(build-dir, target-docs-dir, excludes);
    let template = fs/with-open-file(stream = root-index-file)
                     io/read-to-end(stream)
                   end;
    let body = generate-body-rst(packages);
    let toctree = generate-toctree-rst(packages);
    fs/with-open-file(stream = root-index-file,
                      direction: #"output", if-exists: #"replace")
      // Be careful to write the markers back out to the file so that this code
      // is idempotent. (Which is why the markers are RST comments.)
      iterate loop (lines = as(<list>, split-lines(template)), drop-lines? = #f)
        if (~empty?(lines))
          let line = lines.head;
          if (drop-lines?)
            let keep? = starts-with?(line, ".. end-");
            loop(if (keep?) lines else lines.tail end, ~keep?)
          else
            io/format(stream, "%s\n", line);
            select (line by \=)
              ".. begin-body" =>
                io/write(stream, body);
                loop(lines.tail, #t);
              ".. begin-toctree" =>
                io/write(stream, toctree);
                loop(lines.tail, #t);
              otherwise =>
                loop(lines.tail, #f);
            end;
          end;
        end;
      end iterate;
    end;
    io/format-out("Generated docs for %d packages.\n", packages.size);
  end;
end function;

define function generate-body-rst
    (packages :: <sequence>) => (body :: <string>)
  io/with-output-to-string (stream)
    io/format(stream, "\n");    // Need blank line after ".. begin-body" comment.
    for (package in packages)
      let pkg-name = package.pm/package-name;
      io/format(stream, "* :doc:`%s <%s/index>`", pkg-name, pkg-name);
      let description = package.pm/package-description;
      if (description)
        // Remove newlines so the reST is valid.
        io/format(stream, " - %s", join(split-lines(description), " "));
      end;
      io/format(stream, "\n");
    end;
    io/format(stream, "\n");    // Need blank line before ".. end-body" comment.
  end
end function;

define function generate-toctree-rst
    (packages :: <sequence>) => (toctree :: <string>)
  io/with-output-to-string (stream)
    io/format(stream, """

                      .. toctree::
                         :hidden:
                         :maxdepth: 1

                         opendylan.org <https://opendylan.org>

                      .. toctree::
                         :hidden:
                         :maxdepth: 1
                         :caption: Packages


                      """);
    for (package in packages)
      let pkg-name = package.pm/package-name;
      io/format(stream, "   %s <%s/index>\n", pkg-name, pkg-name);
    end;
    io/format(stream, "\n");    // Need blank line before ".. end-toctree" comment.
  end
end function;

// Fetch all packages listed in the pacman catalog unless they're excluded. In order to
// simplify the documentation URLs to https://package.opendylan.org/<pkg>/index.html we
// remove the documentation/source/ part of the URL by downloading to a temp directory
// and renaming all doc files in documentation/source/ to the package subdirectory where
// docs will be generated.
define function fetch-packages
    (build-dir :: <directory-locator>,
     target-docs-dir :: <directory-locator>,
     excludes :: <sequence>)
 => (packages :: <sequence>)
  let all-packages
    = sort(pm/load-all-catalog-packages(pm/catalog()),
           test: method (a, b)
                   a.pm/package-name < b.pm/package-name
                 end);
  let doc-packages = make(<stretchy-vector>);
  let download-dir = subdirectory-locator(build-dir, "_downloaded-packages");
  fs/ensure-directories-exist(download-dir);
  for (package in all-packages)
    let pkg-name = pm/package-name(package);
    if (member?(pkg-name, excludes, test: string-equal-ic?))
      io/format-out("Skipping download of excluded package %=\n", pkg-name);
      io/force-out();
    else
      let pkg-dir = subdirectory-locator(download-dir, pkg-name);
      if (fs/file-exists?(pkg-dir))
        fs/delete-directory(pkg-dir, recursive?: #t);
      end;
      let doc-dir = subdirectory-locator(target-docs-dir, "source", pkg-name);
      if (fs/file-exists?(doc-dir))
        fs/delete-directory(doc-dir, recursive?: #t);
      end;
      fs/ensure-directories-exist(doc-dir);
      let release = %pm/find-release(package, pm/$latest);
      pm/download(release, pkg-dir, update-submodules?: #f);

      // For DPG, source/index.rst. For others, documentation/source/index.rst
      iterate loop (files = list(file-locator(pkg-dir, "source", "index.rst"),
                                 file-locator(pkg-dir, "documentation", "source", "index.rst"),
                                 file-locator(pkg-dir, "doc",           "source", "index.rst"),
                                 file-locator(pkg-dir, "docs",          "source", "index.rst")))
        if (empty?(files))
          io/format-out("%s: no documentation; skipping.\n", pkg-name);
        else
          let index = head(files);
          if (~fs/file-exists?(index))
            loop(tail(files))
          else
            add!(doc-packages, package);
            fs/ensure-directories-exist(pkg-dir);
            let source-dir = index.locator-directory;
            for (file in fs/directory-contents(source-dir))
              let rel = relative-locator(file, source-dir);
              let dest = merge-locators(rel, doc-dir);
              verbose("Renaming %s -> %s", file, dest);
              fs/rename-file(file, dest);
            end;
          end;
        end if
      end iterate;
      io/force-out();
    end;
  end;
  doc-packages
end function;

main(application-name(), application-arguments())
