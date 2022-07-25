# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit bash-completion-r1 xdg-utils

if [[ "${PV}" = "99999999" ]]; then
	EGIT_REPO_URI="https://github.com/Winetricks/${PN}.git"
	inherit git-r3
	SRC_URI=""
else
	SRC_URI="https://github.com/Winetricks/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

winetricks_gentoo="winetricks-gentoo-2012.11.24"

SRC_URI="${SRC_URI}
	gtk? ( https://dev.gentoo.org/~tetromino/distfiles/wine/${winetricks_gentoo}.tar.bz2 )
	kde? ( https://dev.gentoo.org/~tetromino/distfiles/wine/${winetricks_gentoo}.tar.bz2 )"

DESCRIPTION="Winetricks is an easy way to work around deficiencies in Wine"
HOMEPAGE="https://github.com/Winetricks/winetricks https://wiki.winehq.org/Winetricks"

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="gtk kde rar test"

DEPEND="test? (
		dev-python/bashate
		dev-util/checkbashisms
		|| (
			dev-util/shellcheck-bin
			dev-util/shellcheck
		)
	)"

RDEPEND="
	|| ( net-misc/aria2 net-misc/curl net-misc/wget www-client/fetch )
	app-arch/cabextract
	app-arch/p7zip
	app-arch/unzip
	virtual/wine
	x11-misc/xdg-utils
	gtk? ( gnome-extra/zenity )
	kde? ( kde-apps/kdialog )
	rar? ( app-arch/unrar )"

# Test targets include syntax checks only, not the "heavy duty" tests
# that would require a lot of disk space, as well as network access.

# This uses a non-standard "Wine" category, which is provided by
# app-emulation/wine-desktop-common package.
# https://bugs.gentoo.org/451552
QA_DESKTOP_FILE="usr/share/applications/winetricks.desktop"

src_unpack() {
	if [[ "${PV}" = "99999999" ]]; then
		git-r3_src_unpack

		(use gtk || use kde) && unpack "${winetricks_gentoo}.tar.bz2"
	else
		default
	fi
}

src_install() {
	default
	local _gui

	! use gtk && ! use kde && _gui="none"
	! use gtk &&   use kde && _gui="kdialog"
	! use kde &&   use gtk && _gui="zenity"
	if [[ -n "${_gui}" ]]; then
		newenvd - "90${PN}" <<-_EOF_
		WINETRICKS_GUI="${_gui}"
		_EOF_
	fi

	newbashcomp "src/${PN}.bash-completion" "${PN}"
	if use gtk || use kde; then
		cd "${WORKDIR}/${winetricks_gentoo}" || die "cd failed"
		domenu "winetricks.desktop"
		insinto "/usr/share/icons/hicolor/scalable/apps"
		doins "wine-winetricks.svg"
	fi
}

pkg_preinst() {
	(use gtk || use kde) && xdg_icon_savelist
}

pkg_postinst() {
	(use gtk || use kde) && xdg_icon_cache_update
}

pkg_postrm() {
	(use gtk || use kde) && xdg_icon_cache_update
}
