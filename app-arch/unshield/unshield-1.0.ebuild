# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools

DESCRIPTION="Tool and library to extract CAB files from InstallShield installers"
HOMEPAGE="https://github.com/twogood/unshield"
SRC_URI="https://github.com/twogood/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~x86"
IUSE="libressl static-libs"

RDEPEND="
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	sys-libs/zlib"
DEPEND="${RDEPEND}"

src_prepare() {
	local PATCHES=( "${FILESDIR}/${PN}-1.0-bootstrap.patch" )
	default
	"${S}/bootstrap" || die "bootstrap script failed"
	eautoreconf
}

src_configure() {
	econf $(use_enable static-libs static)
}

pkg_preinst() {
	find "${D}" -name '*.la' -exec rm -f {} +
}
