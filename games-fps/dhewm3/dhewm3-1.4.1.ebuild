# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/dhewm/${PN}.git"
	SRC_URI=""
else
	MY_RC=$(get_version_component_range 4)
	if [[ ! "${MY_RC}" =~ ^rc[[:digit:]]+$ ]]; then
		KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
	fi
	MY_PV="${PV/_rc/_RC}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://github.com/dhewm/${PN}/archive/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	S="${WORKDIR}/${MY_P}"
fi

DESCRIPTION="A Doom 3 GPL source modification."
HOMEPAGE="https://github.com/dhewm/dhewm3"

LICENSE="GPL-3"
SLOT="0"
IUSE="curl dedicated sdl2"

DEPEND="virtual/jpeg:*
	media-libs/libogg
	!sdl2? ( >=media-libs/libsdl-1.2[opengl,video] )
	sdl2? ( media-libs/libsdl2[opengl,video] )
	media-libs/libvorbis
	media-libs/openal
	curl? ( net-misc/curl )
	sys-libs/zlib"
RDEPEND="${DEPEND}"

src_prepare() {
	CMAKE_USE_DIR="${S}/neo"
	default
}

src_configure() {
	mycmakeargs=(
		"-DDEDICATED=ON"
		"-DSDL2=$(usex sdl2)"
		"-DCORE=$(usex !dedicated)"
		"-DBASE=$(usex !dedicated)"
		"-DD3XP=$(usex !dedicated)"
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	dodir "/usr/share/${PN}"
	cmake-utils_src_install
}

pkg_postinst() {
	einfo "Install game data files to \"${ROOT%/}/usr/share/${PN}\" ."
	ewarn "${PN} is only compatible with Doom 3 (/mod) data files."
	ewarn
}
