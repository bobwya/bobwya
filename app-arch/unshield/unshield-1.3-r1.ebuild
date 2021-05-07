# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake

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

IUSE="static-libs"

RDEPEND="
	dev-libs/openssl:=
	sys-libs/zlib"
DEPEND="${RDEPEND}"

src_prepare() {
	local PATCHES=( "${FILESDIR}/${PN}-1.3-fix_cmake_include_paths.patch" )
	eapply_user
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		--with-ssl
		$(use_with static-libs static)
	)
	cmake_src_configure
}
