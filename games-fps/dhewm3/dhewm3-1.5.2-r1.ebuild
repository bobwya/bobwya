# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit cmake

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/dhewm/${PN}.git"
	SRC_URI=""
else
	MY_PV="${PV/_rc/_RC}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://github.com/dhewm/${PN}/archive/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~x86 ~x86-linux"
	S="${WORKDIR}/${MY_P}"
fi

DESCRIPTION="A Doom 3 GPL source modification."
HOMEPAGE="https://dhewm3.org/"

LICENSE="GPL-3"
SLOT="0"
IUSE="curl dedicated sdl2"

DEPEND="media-libs/libjpeg-turbo:=
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
	if ! use sdl2; then
		PATCHES=( "${FILESDIR}/${PN}-1.5.2_rc1-fix_sdl1_threads_compatibility.patch" )
	fi
	cmake_src_prepare
}

src_configure() {
	mycmakeargs=(
		"-DDEDICATED=ON"
		"-DSDL2=$(usex sdl2)"
		"-DCORE=$(usex !dedicated)"
		"-DBASE=$(usex !dedicated)"
		"-DD3XP=$(usex !dedicated)"
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile
}

src_install() {
	dodir "/usr/share/${PN}"
	cmake_src_install
}

pkg_postinst() {
	einfo "Install game data files to \"${ROOT}/usr/share/${PN}\" ."
	ewarn "${PN} is only compatible with Doom 3 (/mod) data files."
	ewarn
}
