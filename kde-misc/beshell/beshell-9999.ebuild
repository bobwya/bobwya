# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit cmake-utils eutils multilib git-r3
EGIT_REPO_URI="git://git.code.sf.net/p/be-shell/code"

DESCRIPTION="BE::Shell is a simple desktop shell on KDE technology for the rest of us"
HOMEPAGE="http://sourceforge.net/p/be-shell/"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="examples scripts wallpapers"

RDEPEND="
	dev-qt/qtcore:4
	kde-base/kdelibs
	media-libs/phonon
	dev-qt/qtgui:4
	dev-qt/qtdbus:4
	"

DEPEND="${RDEPEND}"

src_install() {
	dodir "/usr/share/${PN}"
	insinto "/usr/share/${PN}"
	insopts -m0644
	if use scripts ; then
		rm scripts/{be.apt,be.pacman}
		doins -r "scripts"
		"${FILESDIR}"/chmod_scripts_exec.sh "${D}/usr/share/beshell/scripts"
	fi
	if use wallpapers ; then
		doins -r "wallpaper"
	fi
	if use examples ; then
		doins -r "examples"
		insinto "/usr/share/${PN}/examples"
		doins -r "be.idle.imap"
		doins -r "be.watched"
		doins "krunner.desktop"
		doins "plasma-desktop.desktop"
	fi
	dodoc README
}
