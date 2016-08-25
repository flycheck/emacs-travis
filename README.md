emacs-travis.mk
===============

Install Emacs and its tooling on Travis CI.

`emacs-travis.mk` is a small Makefile which provides targets to install Emacs
stable and emacs-snapshot, Texinfo and Cask on the Docker-based infrastructure
of Travis CI.  It compiles a minimal Emacs and Texinfo from source and installs
them into `$HOME/bin`.

Usage
=====

Add the following to your `.travis.yml`:

``` yaml
language: emacs-lisp
sudo: false
# Allow Emacs snapshot builds to fail and don’t wait for these as they can take
# a looooong time
matrix:
  fast_finish: true
  allow_failures:
    - env: EMACS_VERSION=snapshot
env:
  - EMACS_VERSION=24.3
  - EMACS_VERSION=24.5
  - EMACS_VERSION=25.1-rc2
  - EMACS_VERSION=snapshot
before_install:
  # Configure $PATH: Executables are installed to $HOME/bin
  - export PATH="$HOME/bin:$PATH"
  # Download the makefile to emacs-travis.mk
  - wget 'https://raw.githubusercontent.com/flycheck/emacs-travis/master/emacs-travis.mk'
  # Install Emacs (according to $EMACS_VERSION) and Cask
  - make -f emacs-travis.mk install_emacs
  - make -f emacs-travis.mk install_cask
  # Install Texinfo, if you need to build info manuals for your project
  - make -f emacs-travis.mk install_texinfo
install:
  # Install your dependencies
  - cask install
script:
  # Run your tests
  - cask exec ert-runner
```

This setup builds and tests your Emacs Lisp project on Emacs 24.3, 24.5 and the
current Emacs snapshot from Git.

Reference
---------

To install, download the `emacs-travis.mk` script in your `.travis.yml`, and run
it with `make -f` as in the example above.

Environment variables (set these in the `env:` section of your `.travis.yml`):

- `$EMACS_VERSION`: The Emacs version to install.  Supports any released version
  of GNU Emacs (tested with 24.1 and upwards), release candidates
  (e.g. `25.1-rc2`) or the special value `snapshot` to clone the latest `master`
  from Emacs’ Git.  Defaults to the latest stable release of GNU Emacs.
- `$TEXINFO_VERSION`: The Texinfo version to install.  Supports any released
  version of GNU Texinfo (tested with 5.2 and upwards).  Defaults to the latest
  stable release of GNU Texinfo.

Additional environment variables (for special purposes):

- `$EMACSCONFFLAGS`: Flags for `./configure` when building Emacs.  Defaults to
  building a minimal Emacs, without almost all features

Targets (for use in `before_install`):

- `install_cask`: Install Cask
- `install_emacs`: Install GNU Emacs, as per `$EMACS_VERSION`
- `install_texinfo`: Install GNU Texinfo, as per `$TEXINFO_VERSION`

License
-------

Copyright © 2015 Sebastian Wiesner <swiesner@lunaryorn.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
