# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit gnome2-utils

DESCRIPTION="Core desktop menu entries and icons for Wine"
HOMEPAGE="https://github.com/bobwya/wine-desktop-common
	http://dev.gentoo.org/~tetromino/distfiles/wine
	http://bazaar.launchpad.net/~ubuntu-wine/wine/ubuntu-debian-dir/files/head:/debian/"
SRC_URI="http://github.com/bobwya/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="-* amd64 x86 x86-fbsd"
IUSE=""

RDEPEND=""

# These use a non-standard "Wine" category, which is provided by
# /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="usr/share/applications/wine-browsedrive.desktop
usr/share/applications/wine-notepad.desktop
usr/share/applications/wine-uninstaller.desktop
usr/share/applications/wine-winecfg.desktop"

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
