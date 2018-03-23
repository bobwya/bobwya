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
usr/share/applications/wineoleview.desktop
usr/share/applications/wineregedit.desktop
usr/share/applications/winemine.desktop
usr/share/applications/winewinhelp.desktop
usr/share/applications/winewordpad.desktop
usr/share/applications/winemsiexec.desktop
usr/share/applications/winemime-msi.desktop
usr/share/applications/winebrowsecdrive.desktop
usr/share/applications/winenotepad.desktop
usr/share/applications/wineuninstaller.desktop
usr/share/applications/wineboot.desktop
usr/share/applications/wineexplorer.desktop
usr/share/applications/winecfg.desktop
usr/share/applications/winefile.desktop
usr/share/applications/winecontrol.desktop
usr/share/applications/winecmd.desktop
usr/share/applications/wineiexplore.desktop
usr/share/applications/winetaskmgr.desktop
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
