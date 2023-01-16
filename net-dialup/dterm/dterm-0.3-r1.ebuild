# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Simple serial terminal emulator"
HOMEPAGE="http://www.knossos.net.nz/resources/free-software/dterm"
SRC_URI="http://www.knossos.net.nz/downloads/${P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="net-dialup/lrzsz"

PATCHES=(
	"${FILESDIR}/${PN}-0.3-fix-error-unused-result.patch"
	"${FILESDIR}/${PN}-0.3-makefile-fix.patch"
)

src_install() {
	emake BIN="${ED}/usr/bin" COPT="${CFLAGS}" install
	einstalldocs
}
