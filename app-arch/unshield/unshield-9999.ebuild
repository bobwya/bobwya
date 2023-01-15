# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Tool and library to extract CAB files from InstallShield installers"
HOMEPAGE="https://github.com/twogood/unshield"

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/twogood/${PN}.git"
	inherit git-r3
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
	eapply_user
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_STATIC=$(usex static-libs)
	)
	cmake_src_configure
}
