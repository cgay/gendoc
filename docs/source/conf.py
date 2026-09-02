# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Dylan Package Documentation'
copyright = '2024, Dylan Hackers'
author = 'Dylan Hackers'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

import os
import sys
sys.path.insert(0, os.path.abspath('../../../_packages/sphinx-extensions/current/src/sphinxcontrib'))
extensions = [
    'dylan.domain',
    'sphinx.ext.graphviz',
    'sphinx.ext.intersphinx',
    'sphinx_copybutton',
]
primary_domain = 'dylan'
exclude_patterns = [
    '**/README.*',
]
show_authors = True
templates_path = ['_templates']

# Work around https://github.com/sphinx-doc/sphinx/issues/13904 Specifically, I (cgay)
# didn't want to spend time bisecting the corba-guide docs to figure out what was causing
# them to trigger the bug.
#
# Setting this default role has the benefit of surfacing more warnings than when it is
# unset, the main case being when we use `foo` where we should use ``foo``.
default_role = 'any'


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'             # https://pradyunsg.me/furo/customisation/

# Without this Furo adds the word "documentation" to the project name.
html_title = project
