# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit cmake-utils games git-2

DESCRIPTION="A Doom 3 GPL source modification."
HOMEPAGE="https://github.com/dhewm/dhewm3"
#SRC_URI="mirror://gentoo/doom3.png"
EGIT_REPO_URI="https://github.com/dhewm/dhewm3.git"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS=""
IUSE="cdinstall curl dedicated roe"

# TODO There declared SDL2 support...
DEPEND="virtual/jpeg
	media-libs/libogg
	>=media-libs/libsdl-1.2
	media-libs/libvorbis
	media-libs/openal
	curl? ( net-misc/curl )
	sys-libs/zlib"
RDEPEND="${DEPEND}
	cdinstall? (
		>=games-fps/doom3-data-1.1.1282-r1
		roe? ( games-fps/doom3-roe )
	)"

CMAKE_USE_DIR="${S}/neo"

src_prepare() {
	sed -i -e 's:\(${CMAKE_INSTALL_FULL_DATADIR}\)/dhewm3:\1:' neo/CMakeLists.txt
}

src_configure() {
	# TODO There declared SDL2 support...
	mycmakeargs=(
		"-DDEDICATED=ON"
		$(cmake-utils_use_disable dedicated CORE)
		$(cmake-utils_use_disable dedicated BASE)
		$(cmake-utils_use_disable dedicated D3XP)
		"-DCMAKE_INSTALL_BINDIR=${GAMES_BINDIR}"
		"-DCMAKE_INSTALL_DATADIR=${GAMES_DATADIR}/doom3"
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	DOCS="README.md" cmake-utils_src_install
#	newicon doom3.png ${PN}.png
#	make_desktop_entry ${PN} "Doom 3 - dhewm"
	prepgamesdirs
}

pkg_postinst() {
	games_pkg_postinst
	if ! use cdinstall; then
		elog "You need to copy *.pk4 from either your installation media or your hard drive to"
		elog "${GAMES_DATADIR}/doom3/base before running the game,"
		elog "or 'emerge games-fps/doom3-data' to install from CD."
		echo
		if use roe ; then
			elog "To use the Resurrection of Evil expansion pack, you also need	to copy *.pk4"
			elog "to ${GAMES_DATADIR}/doom3/d3xp from the RoE CD before running the game,"
			elog "or 'emerge doom3-roe' to install from CD."
		fi
	fi

	echo
	elog "To play the game, run:"
	elog " ${PN}"
	echo
}
