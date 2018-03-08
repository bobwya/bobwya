# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

inherit gnome2-utils

DESCRIPTION="Core desktop menu entries and icons for Wine"
HOMEPAGE="https://github.com/bobwya/wine-desktop-common"

if [ "${PV}" = "99999999" ]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/bobwya/${PN}.git"
	SRC_URI=""
else
	KEYWORDS="-* amd64 x86 ~x86-fbsd"
	SRC_URI="https://github.com/bobwya/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="LGPL-2.1"
SLOT="0"
IUSE=""

RDEPEND=""

# These desktop files use a non-standard "Wine" category,
# which is provided by: /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="
usr/share/wine-iexplore.desktop
usr/share/wine-explorer.desktop
usr/share/wine-cmd.desktop
usr/share/wine-winecfg.desktop
usr/share/wine-notepad.desktop
usr/share/wine-wordpad.desktop
usr/share/wine-regedit.desktop
usr/share/wine-uninstaller.desktop
usr/share/wine-msiexec.desktop
usr/share/wine-winhelp.desktop
usr/share/wine-wineboot.desktop
usr/share/wine-mime-msi.desktop
usr/share/wine-winemine.desktop
usr/share/wine-control.desktop
usr/share/wine-winefile.desktop
usr/share/wine-taskmgr.desktop
usr/share/wine-browsecdrive.desktop
usr/share/wine-oleview.desktop
"

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
