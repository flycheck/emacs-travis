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
EMACS_VERSION ?= 25.2
VERBOSE ?= no
MAKE_JOBS ?= 2
# Build a minimal Emacs with no special flags, to build as fast as possible
EMACSCONFFLAGS ?= --with-x-toolkit=no --without-x --without-all --with-xml2 \
	CFLAGS='-O2 -march=native' CXXFLAGS='-O2 -march=native'

ifeq ($(VERBOSE),yes)
SILENT=
else
SILENT=> /dev/null
endif

# Tear the version apart
VERSION_PARTS = $(subst -, ,$(EMACS_VERSION))
VERSION_PART = $(word 1,$(VERSION_PARTS))
PRE_RELEASE_PART = $(word 2,$(VERSION_PARTS))
# Whether the version is a release candidate
IS_RC = $(findstring rc,$(PRE_RELEASE_PART))

# Clone Emacs from the Github mirror because it's way faster than upstream
EMACS_GIT_URL = https://github.com/emacs-mirror/emacs.git
# Emacs FTP URL.  Prereleases are on alpha.gnu.org
ifeq ($(PRE_RELEASE_PART),)
EMACS_FTP_URL = "https://ftp.gnu.org/gnu/emacs"
else
EMACS_FTP_URL = "http://alpha.gnu.org/pub/gnu/emacs/pretest"
endif
# URL of the TAR file
EMACS_TAR_URL = $(EMACS_FTP_URL)/emacs-$(EMACS_VERSION).tar.xz

# If it's an RC the real reported Emacs version is the version without the
# prerelease postfix.  Otherwise it's just the version that we get.
ifneq ($(IS_RC),)
REPORTED_EMACS_VERSION = $(VERSION_PART)
else
REPORTED_EMACS_VERSION = $(EMACS_VERSION)
endif

# Tell recipe processes about the reported Emacs version
export REPORTED_EMACS_VERSION

.PHONY: download_emacs_stable clone_emacs_snapshot
.PHONY: configure_emacs install_emacs install_cask install_texinfo
.PHONY: test

download_emacs_stable:
	@echo "Download Emacs $(EMACS_VERSION) from $(EMACS_TAR_URL)"
	@curl -o "/tmp/emacs-$(EMACS_VERSION).tar.xz" "$(EMACS_TAR_URL)"
	@tar xf "/tmp/emacs-$(EMACS_VERSION).tar.xz" -C /tmp
	@mkdir -p `dirname "$(EMACS_DIR)"`
	@mv /tmp/emacs-$(REPORTED_EMACS_VERSION) "$(EMACS_DIR)"

clone_emacs_snapshot:
	@echo "Clone Emacs from Git"
	git clone --depth=1 '$(EMACS_GIT_URL)' $(EMACS_DIR)
# Create configure
	cd $(EMACS_DIR) && ./autogen.sh

configure_emacs:
	@echo "Configure Emacs $(EMACS_VERSION)"
	@cd "$(EMACS_DIR)" && ./configure --quiet --enable-silent-rules \
		--prefix="$(HOME)" $(EMACSCONFFLAGS) $(SILENT)

ifeq ($(EMACS_VERSION),snapshot)
EMACS_DIR = /tmp/emacs
configure_emacs: clone_emacs_snapshot
else
EMACS_DIR = $(HOME)/emacs/$(EMACS_VERSION)
configure_emacs: download_emacs_stable
endif

install_emacs:
	@echo "Install Emacs $(EMACS_VERSION)"
	@make -j$(MAKE_JOBS) -C "$(EMACS_DIR)" V=0 install $(SILENT)

# Run configure (and download) only if directory is absent
ifeq ($(wildcard $(EMACS_DIR)/.),)
install_emacs: configure_emacs
endif

install_cask:
	@echo "Install Cask"
	@git clone --depth=1 https://github.com/cask/cask.git "$(HOME)/.cask"
	@ln -s "$(HOME)/.cask/bin/cask" "$(HOME)/bin/cask"

install_texinfo:
	@echo "Install Texinfo $(TEXINFO_VERSION)"
	@curl -sS -o "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" \
		'http://ftp.gnu.org/gnu/texinfo/texinfo-$(TEXINFO_VERSION).tar.gz'
	@tar xzf "/tmp/texinfo-$(TEXINFO_VERSION).tar.gz" -C /tmp
	@cd "/tmp/texinfo-$(TEXINFO_VERSION)" && \
		CFLAGS="$(CFLAGS) -Wno-unused-result" ./configure --quiet --enable-silent-rules --prefix="$(HOME)" $(SILENT)
# Patching Makefile to inhibit unexpected warnings.
# See: https://github.com/flycheck/emacs-travis/pull/9
	@sed -i -e "s/^CFLAGS =\(.*\)/CFLAGS = \1 -Wno-unused-result/g" "/tmp/texinfo-$(TEXINFO_VERSION)/info/Makefile"
	@make -j$(MAKE_JOBS) -C "/tmp/texinfo-$(TEXINFO_VERSION)" V=0 install $(SILENT)

test:
	bundle exec rspec --color --format doc
