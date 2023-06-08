gendoc
======

This is a tool to generate the docs for all packages in the Dylan package
catalog, with the ultimate goal of replacing most or all of [the current
library reference](http://opendylan.org/documentation/library-reference).

Why?  Because it shouldn't be necessary to include your library docs in the
Open Dylan repository or the [opendylan.org
repo](https://github.com/dylan-lang/website) in order to have them
published. You should be able to make a package, write docs, and get it added
to the shared documentation pages.

There are two problems:

1.  Not all libraries in the catalog have docs. We should fix that!

2.  Some docs (e.g., [logging](https://github.com/dylan-lang/logging)) are in
    the Open Dylan repo instead of in their own repo. We _will_ fix that.

3.  Some libraries *and* their docs should be moved out of the
    [opendylan](https://github.com/dylan-lang/opendylan) repo so that clients
    aren't tied to the same versions that are contained in a particular Open
    Dylan release.

ok. Three problems.

Usage
-----

Summary:

1.  First time setup:
    1.  `sudo apt install plantuml`
    2.  `pip install sphinxcontrib-plantuml` (for v3d library, so far)
    3.  `cd /var/www/docs.opendylan.org`
    4.  `mkdir _images _plantuml`
    5.  `chown foo:foo _images _plantuml` where foo is the user your web
         server is running as.
2.  `make` -- build gendoc
3.  `_build/bin/gendoc -o output`
4.  `cd output; make html`
5.  `cp -r -p _build/html/* /var/www/docs.opendylan.org/`

Keep reading for a few extra details....

The Sphinx project files (conf.py, Makefile, etc.) already exist in the
"output" subdirectory. Run `gendoc` like so:

```
$ _build/bin/gendoc -o output
```

`gendoc` will

1.  Create a `output/packages` subdirectory and populate it with all the
    packages in the Dylan catalog that have documentation. (This list is
    hard-coded...update it and rebuild if necessary.)

2.  Create `output/index.rst` file that references the top-level `index.rst` file
    in each package's documentation. By default this is
    `<pkg>/documentation/source/index.rst`, but this can be overridden manually
    in `gendoc.dylan` if necessary.

It is up to you to run `make html` in the `output` directory and verify that
everything looks good. There should be zero errors during the build. If there
are errors something went wrong or a package's documentation is broken.

On the docs.opendylan.org machine, the generated HTML files can be installed
with this command:

```shell
cp -r -p _build/html/* /var/www/docs.opendylan.org/
```
