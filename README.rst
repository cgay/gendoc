gendoc
======

This is a tool to generate the docs for all packages in the Dylan package
catalog. How it works, in a nutshell:

* Load the package catalog.
* Download each package to a temp directory.
* Copy package ResTructured Text docs into a combined directory tree.
* Modify :file:`docs/source/index.rst` to list each package in the top-level
  ``toctree`` directive.

.. note:: The "docs" subdirectory in this repository is intentionally not named
          "documentation" in order to prevent gendoc itself from showing up in
          the package catalog since it has no documentation other than this
          README. Eventually we should have a setting in :file:`dylan-package.json`
          to exclude the package from combined docs.

Usage
-----

To generate package docs in the :file:`docs/source` directory::

.. code-block:: shell

   $ git clone https://github.com/dylan-lang/gendoc
   $ cd gendoc
   $ dylan update
   $ dylan build -a
   $ _build/bin/gendoc --excludes-file excludes.txt docs/source/index.rst

See `opendylan/documentation/README.rst
<https://github.com/dylan-lang/opendylan/blob/master/documentation/README.rst>`_
for details on how to build the full website including the package docs.
