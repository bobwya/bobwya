# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils flag-o-matic qt4-r2 toolchain-funcs

DESCRIPTION="A better i7 (and now i3, i5) reporting tool for Linux"

if [[ ${PV} == "9999" ]] ; then
		HOMEPAGE="https://github.com/bobwya/i7z"
		EGIT_REPO_URI="git://github.com/bobwya/i7z.git"
		EGIT_BRANCH="master"
		inherit git-r3
		SRC_URI=""
		#KEYWORDS=""
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="X"

RDEPEND="
	sys-libs/ncurses:*
	X? ( dev-qt/qtgui:4 )"
DEPEND="${RDEPEND}"

src_compile() {
	emake
	if use X; then
		cd GUI
		eqmake4 ${PN}_GUI.pro
		emake clean && emake
	fi
}

src_install() {
	emake DESTDIR="${ED}" docdir=/usr/share/doc/${PF} install
	use X && dosbin GUI/i7z_GUI
}
