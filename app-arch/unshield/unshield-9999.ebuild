# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit cmake-utils

DESCRIPTION="Tool and library to extract CAB files from InstallShield installers"
HOMEPAGE="https://github.com/twogood/unshield"

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/twogood/${PN}.git"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="https://github.com/twogood/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~hppa ~ppc ~x86"
fi

LICENSE="MIT"
SLOT="0"

IUSE="libressl static-libs"

RDEPEND="
	!libressl? ( dev-libs/openssl:0 )
	libressl? ( dev-libs/libressl )
	sys-libs/zlib"
DEPEND="${RDEPEND}"

src_prepare() {
	if [[ "${PV}" == "1.3" ]]; then
		epatch "${FILESDIR}/${PN}-1.3-fix_cmake_include_paths.patch"
	fi
	cmake-utils_src_prepare
}

src_configure() {
	local mycmakeargs=(
		--with-ssl
		$(cmake-utils_use_with static-libs static) \
	)
	cmake-utils_src_configure
}

pkg_preinst() {
	find "${D}" -name '*.la' -exec rm -f {} +
}
