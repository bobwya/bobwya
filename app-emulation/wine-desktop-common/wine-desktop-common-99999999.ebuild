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

# These use a non-standard "Wine" category, which is provided by
# /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="/usr/share/applications/wine-browsecdrive.desktop
/usr/share/applications/wine-cmd.desktop
/usr/share/applications/wine-control.desktop
/usr/share/applications/wine-explorer.desktop
/usr/share/applications/wine-iexplore.desktop
/usr/share/applications/wine-mime-msi.desktop
/usr/share/applications/wine-msiexec.desktop
/usr/share/applications/wine-oleview.desktop
/usr/share/applications/wine-regedit.desktop
/usr/share/applications/wine-taskmgr.desktop
/usr/share/applications/wine-uninstaller.desktop
/usr/share/applications/wine-wineboot.desktop
/usr/share/applications/wine-winecfg.desktop
/usr/share/applications/wine-winefile.desktop
/usr/share/applications/wine-winhelp.desktop
/usr/share/applications/wine-wordpad.desktop
"

pkg_pretend() {
	einfo ">=${CATEGORY}/${PN}-20180822 introduces a full set of scalable icons"
	einfo "and desktop files for all Wine builtin utilities and helpers."
	einfo "If your DE menus shows the older low-resolution icons for Wine desktop"
	einfo "entries - then you may want to purge these older, lower resolution png icons:"
	einfo "from your local user XDG directories, e.g.:"
	einfo
	einfo "find \"\${HOME}/.local/share/icons/hicolor\" -type f -iregex \".*\(iexplore\|notepad\|wordpad\)\.0\.png\""
	einfo "# find \"\${HOME}/.local/share/icons/hicolor\" -type f -iregex \".*\(iexplore\|notepad\|wordpad\)\.0\.png\" | xargs rm"
	einfo
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
