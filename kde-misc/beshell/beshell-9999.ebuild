# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit cmake-utils eutils multilib git-r3
EGIT_REPO_URI="git://git.code.sf.net/p/be-shell/code"

DESCRIPTION="BE::Shell is a simple desktop shell on KDE technology (namely KIO and Solid) for the rest of us"
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
	mkdir -p "${D}/usr/share/${PN}"
	if use scripts ; then
		cp -r "${S}/scripts" "${D}/usr/share/${PN}/"
	fi
	if use wallpapers ; then
		cp -r "${S}/wallpaper" "${D}/usr/share/${PN}/"
	fi
	if use examples ; then
		cp -r "${S}/examples" "${D}/usr/share/${PN}/"
		cp -r "${S}/be.idle.imap" "${D}/usr/share/${PN}/examples"
		cp -r "${S}/be.watched" "${D}/usr/share/${PN}/examples"
		insinto "/usr/share/${PN}/examples"
		insopts -m0644
		doins "krunner.desktop"
		doins "plasma-desktop.desktop"
	fi
	dodoc README
}
