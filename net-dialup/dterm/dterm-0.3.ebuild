# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils

DESCRIPTION="Simple serial terminal emulator"
HOMEPAGE="http://www.knossos.net.nz/resources/free-software/dterm"
SRC_URI="http://www.knossos.net.nz/downloads/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="net-dialup/lrzsz"

DOCS="README.txt"

src_prepare() {
	epatch "${FILESDIR}"/${P}-fix-error-unused-result.patch
}

src_install() {
	bininto "/usr/bin"
	dobin "${PN}"
	dodoc "${DOCS}"
}