# Copyright (c) 2015 Sebastian Wiesner <swiesner@lunaryorn.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ifeq ($(origin TRAVIS_BUILD), undefined)
$(error "TRAVIS_BUILD not set")
endif

# These variables may be overridden by the user
TEXINFO_VERSION ?= 6.0
EMACS_VERSION ?= 24.5
EMACSBUILDFLAGS ?= --with-x-toolkit=no --without-x --without-all --with-xml2
EMACSBUILDVARS ?= CFLAGS='' CXXFLAGS=''

.PHONY: download_emacs_stable clone_emacs_snapshot
.PHONY: install_emacs install_cask install_texinfo
.PHONY: show_version

download_emacs_stable:
	@echo "Download Emacs $(EMACS_VERSION)"
	@curl -o "/tmp/emacs-$(EMACS_VERSION).tar.gz" \
		"https://ftp.gnu.org/gnu/emacs/emacs-$(EMACS_VERSION).tar.gz"
	@tar xzf "/tmp/emacs-$(EMACS_VERSION).tar.gz" -C /tmp
	@mv /tmp/emacs-$(EMACS_VERSION) /tmp/emacs

clone_emacs_snapshot:
	@echo "Clone Emacs from Git"
	git clone --depth=1 'http://git.sv.gnu.org/r/emacs.git' /tmp/emacs
	# Create configure
	cd /tmp/emacs && ./autogen.sh

ifdef EMACS_VERSION
install_emacs:
	@echo "Install Emacs $(EMACS_VERSION)"
	@cd '/tmp/emacs' && ./configure --quiet --enable-silent-rules \
		$(EMACSBUILDFLAGS) --prefix="$(HOME)" $(EMACSBUILDVARS)
	@make -j2 -C '/tmp/emacs' V=0 install

ifeq ($(EMACS_VERSION),snapshot)
install_emacs: clone_emacs_snapshot
else
install_emacs: download_emacs_stable
endif

install_cask:
	@echo "Install Cask"
	@git clone --depth=1 https://github.com/cask/cask.git "$(HOME)/.cask"
	@ln -s "$(HOME)/.cask/bin/cask" "$(HOME)/bin/cask"

else
install_emacs:
	$(info "Skipping Emacs installation, $EMACS_VERSION not set")

install_cask:
	$(info "Skipping Cask installation, $EMACS_VERSION not set")
endif

ifdef TEXINFO_VERSION
install_texinfo:
	@echo "Install Texinfo $(TEXINFO_VERSION)"
	@curl -o "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" \
		'http://ftp.gnu.org/gnu/texinfo/texinfo-$(TEXINFO_VERSION).tar.gz'
	@tar xzf "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" -C /tmp
	@cd "/tmp/texinfo-$(TEXINFO_VERSION)" && \
		./configure --quiet --enable-silent-rules --prefix="$(HOME)"
	@make -j2 -C "/tmp/texinfo-$(TEXINFO_VERSION)" V=0 install
else
install_texinfo:
	$(info "Skipping Texinfo installation, $TEXINFO_VERSION not set")
endif

show_versions:
	@echo "Installed versions"
ifdef EMACS_VERSION
	@emacs --version
else
	@echo "Emacs not installed"
endif
ifdef TEXINFO_VERSION
	@texi2any --version
else
	@echo "Texinfo not installed"
endif
