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
# which is provided by: /etc/xdg/applications-merged/winehq-wine.menu
QA_DESKTOP_FILE="
usr/share/applications/winehq-oleview.desktop
usr/share/applications/winehq-regedit.desktop
usr/share/applications/winehq-winemine.desktop
usr/share/applications/winehq-winhelp.desktop
usr/share/applications/winehq-wordpad.desktop
usr/share/applications/winehq-msiexec.desktop
usr/share/applications/winehq-mime-msi.desktop
usr/share/applications/winehq-browsecdrive.desktop
usr/share/applications/winehq-notepad.desktop
usr/share/applications/winehq-uninstaller.desktop
usr/share/applications/winehq-wineboot.desktop
usr/share/applications/winehq-explorer.desktop
usr/share/applications/winehq-winecfg.desktop
usr/share/applications/winehq-winefile.desktop
usr/share/applications/winehq-control.desktop
usr/share/applications/winehq-cmd.desktop
usr/share/applications/winehq-iexplore.desktop
usr/share/applications/winehq-taskmgr.desktop
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
