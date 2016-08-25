# Copyright (c) 2015-2016 Sebastian Wiesner <swiesner@lunaryorn.com>

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

# These variables may be overridden by the user
TEXINFO_VERSION ?= 6.1
EMACS_VERSION ?= 24.5
VERBOSE ?= no
# Build a minimal Emacs with no special flags, to build as fast as possible
EMACSCONFFLAGS ?= --with-x-toolkit=no --without-x --without-all --with-xml2 \
	CFLAGS='-O2 -march=native' CXXFLAGS='-O2 -march=native'

ifeq ($(VERBOSE),yes)
SILENT=
else
SILENT=> /dev/null
endif

# Clone Emacs from the Github mirror because it's way faster than upstream
EMACS_GIT_URL = https://github.com/emacs-mirror/emacs.git
# URL of Emacs' FTP server
EMACS_FTP_URL = https://ftp.gnu.org/gnu/emacs

.PHONY: download_emacs_stable clone_emacs_snapshot
.PHONY: install_emacs install_cask install_texinfo
.PHONY: show_version

download_emacs_stable:
	@echo "Download Emacs $(EMACS_VERSION)"
	@curl -o "/tmp/emacs-$(EMACS_VERSION).tar.gz" \
		"$(EMACS_FTP_URL)/emacs-$(EMACS_VERSION).tar.gz"
	@tar xzf "/tmp/emacs-$(EMACS_VERSION).tar.gz" -C /tmp
	@mv /tmp/emacs-$(EMACS_VERSION) /tmp/emacs

clone_emacs_snapshot:
	@echo "Clone Emacs from Git"
	git clone --depth=1 '$(EMACS_GIT_URL)' /tmp/emacs
	# Create configure
	cd /tmp/emacs && ./autogen.sh

install_emacs:
	@echo "Install Emacs $(EMACS_VERSION)"
	@cd '/tmp/emacs' && ./configure --quiet --enable-silent-rules \
		--prefix="$(HOME)" $(EMACSCONFFLAGS) $(SILENT)
	@make -j2 -C '/tmp/emacs' V=0 install $(SILENT)

ifeq ($(EMACS_VERSION),snapshot)
install_emacs: clone_emacs_snapshot
else
install_emacs: download_emacs_stable
endif

install_cask:
	@echo "Install Cask"
	@git clone --depth=1 https://github.com/cask/cask.git "$(HOME)/.cask"
	@ln -s "$(HOME)/.cask/bin/cask" "$(HOME)/bin/cask"

install_texinfo:
	@echo "Install Texinfo $(TEXINFO_VERSION)"
	@curl -o "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" \
		'http://ftp.gnu.org/gnu/texinfo/texinfo-$(TEXINFO_VERSION).tar.gz'
	@tar xzf "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" -C /tmp
	@cd "/tmp/texinfo-$(TEXINFO_VERSION)" && \
		./configure --quiet --enable-silent-rules --prefix="$(HOME)" $(SILENT)
	@make -j2 -C "/tmp/texinfo-$(TEXINFO_VERSION)" V=0 install $(SILENT)
