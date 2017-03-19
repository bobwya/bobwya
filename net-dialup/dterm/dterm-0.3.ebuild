# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Simple serial terminal emulator"
HOMEPAGE="http://www.knossos.net.nz/resources/free-software/dterm"
SRC_URI="http://www.knossos.net.nz/downloads/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="net-dialup/lrzsz"

src_prepare() {
	sed -i	-e '\@^BIN@{s@/usr/local/bin@${D}${EROOT}usr/bin@}' \
			-e '\@^COPT@{s@=.*$@= $(CFLAGS)@}' \
			-e '\@^VERSION@a\ dummy_build_folder := $(shell mkdir -p ${BIN})' \
		"${S}/Makefile" || die "sed failed"
	local PATCHES=( "${FILESDIR}"/${P}-fix-error-unused-result.patch )
	default
}