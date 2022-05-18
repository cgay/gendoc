Module: gendoc-impl


// The directory into which packages are cloned.
define constant $packages-subdirectory = "packages";

// Each element takes one of two forms: (1) a string, in which case it's the
// name of a package that has one top-level document in the standard location,
// <repo>/documentation/source/index.rst, or (2) a <doc> instance.
define constant $libraries-to-document
  = vector("binary-data",
           "command-line-parser",
           "concurrency",
           "http",
           "logging",
           "strings",
           make(<doc>,
                name: "testworks",
                roots: #["documentation/users-guide/source/index.rst"]),
           "uuid",
           "melange",
           "dylan-tool");

/*
.. To be documented: anaphora, atom-language-dylan, base64, command-interface,
   json, mime, pacman-catalog, peg-parser, priority-queue, sequence-stream,
   serialization, shootout, skip-list, slot-visitor, sphinx-extensions (tools),
   uncommon-dylan, uri, uuid, web-framework, wrapper-streams, xml-parser,
   xml-rpc, zlib

.. To be moved out of OD: collection-extensions, command-line-parser,
   dylan-emacs-support (under tools), hash-algorithms, lisp-to-dylan (tools),
   lsp-dylan (tools), regular-expressions, strings, vscode-dylan
   (tools)

.. Move testworks docs out of user-guide subdirectory
*/

define command-line <gendoc-command-line> ()
  option source-directory :: <string>,
    names: #("source-directory", "o"),
    help: "Root directory of the generated output",
    kind: <parameter-option>,
    default: ".";
end;

define function main
    (name :: <string>, args :: <sequence>) => (status :: false-or(<integer>))
  let parser = make(<gendoc-command-line>,
                    help: "Generate docs for packages in the Dylan catalog");
  block ()
    parse-command-line(parser, application-arguments());
    let dir = as(<directory-locator>, source-directory(parser));
    gendoc(directory: dir);
  exception (err :: <abort-command-error>)
    let status = exit-status(err);
    if (status ~= 0)
      format-err("Error: %s\n", err);
    end;
    status
  exception (err :: <error>)
    log-error("%s", condition-to-string(err));
  end
end function;

define class <doc> (<object>)
  constant slot doc-package-name :: <string>,
    required-init-keyword: name:;
  // Root docs are relative to the repository root. e.g.,
  // "documentation/source/user-guide/index.rst"
  constant slot doc-roots :: <sequence>,
    required-init-keyword: roots:;
  slot doc-package :: false-or(pm/<package>) = #f;
end class;

// Canonicalize the given document specs into <doc> objects with their
// doc-package slot filled in.
define function documents
    (#key document-specs = $libraries-to-document) => (docs :: <sequence>)
  let catalog = pm/catalog();
  map(method (spec)
        let doc = spec;
        if (instance?(spec, <string>))
          doc := make(<doc>,
                      name: spec,
                      roots: #["documentation/source/index.rst"]);
        end;
        doc-package(doc)
          := pm/find-package(catalog, doc-package-name(doc));
        doc
      end,
      document-specs)
end function;

define function gendoc
    (#key directory :: <directory-locator> = fs/working-directory,
          docs :: <sequence> = documents())
  let package-dir = subdirectory-locator(directory, $packages-subdirectory);
  fetch-packages(docs, package-dir);

  let index-file = merge-locators(as(<file-locator>, "index.rst"), directory);
  fs/with-open-file(stream = index-file,
                    direction: #"output", if-exists?: #"replace")
    gendoc-to-stream(stream, docs)
  end;
end function;

define function fetch-packages
    (docs :: <sequence>, directory :: <directory-locator>)
  for (doc in docs)
    let package = doc-package(doc);
    let release = %pm/find-release(package, pm/$latest);
    let pkg-dir = subdirectory-locator(directory, pm/package-name(package));
    fs/ensure-directories-exist(pkg-dir);
    pm/download(release, pkg-dir, update-submodules?: #f);
  end;
end function;

define function string-parser (s) => (s) s end;

define constant $toctree-template = #:string:"
.. toctree::
   :maxdepth: 1
   :caption: %s:

";

define function gendoc-to-stream
    (stream :: <stream>, docs :: <sequence>)
  format(stream, #:string:"
Dylan Library and Tool Reference
================================

Documentation for all libraries in the Dylan package catalog.

");
  gendoc-toctrees(stream, docs);
  format(stream, #:string:"

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
");
end function;

define function gendoc-toctrees
    (stream :: <stream>, docs :: <sequence>)
  let docs-by-category = make(<istring-table>);
  for (doc in docs)
    let package = doc-package(doc);
    let category = pm/package-category(package);
    let cat-docs = element(docs-by-category, category, default: #());
    docs-by-category[category] := pair(doc, cat-docs);
  end;
  for (category in sort(key-sequence(docs-by-category)))
    let cat-docs = docs-by-category[category];
    // TODO: there's no provision here for a single package having doc roots in
    // more than one category. Seems like it would be rare?
    format(stream, $toctree-template, category);
    for (doc in cat-docs)
      for (path in doc-roots(doc))
        if (ends-with?(path, ".rst"))
          path := copy-sequence(path, end: path.size - 4);
        end;
        format(stream, "   %s/%s\n", $packages-subdirectory, path);
      end for;
    end for;
  end for;
end function;
