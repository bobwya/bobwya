# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=7

inherit bash-completion-r1 xdg-utils

if [ "${PV}" = "99999999" ]; then
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

winetricks_disable_gui_component() {
	(($# == 2)) || die "Invalid parameter count: ${#} (2)"
	[[ -f "${1}" ]] || die "winetricks script file not valid: \"${1}\""

	local awk_file

	mv "${1}" "${1}.bak" || die "mv failed"
	if [[ "${2}" == true ]]; then
		awk_file="disable_gui"
	else
		awk_file="disable_gui_component"
	fi
	awk -vgtk_use="$(use gtk && echo 1)" \
		-vkde_use="$(use kde && echo 1)" \
		-f "${FILESDIR}/${PN}-${awk_file}.awk" \
		"${1}.bak" > "${1}" || die "awk failed"
}

winetricks_disable_version_check() {
	(($# == 1)) || die "Invalid parameter count: ${#} (1)"
	[[ -f "${1}" ]] || die "winetricks script file not valid: \"${1}\""

	local awk_file="disable_version_check"

	mv "${1}" "${1}.bak" || die "mv failed"
	awk -f "${FILESDIR}/${PN}-${awk_file}.awk" \
		"${1}.bak" > "${1}" || die "awk failed"
}

src_unpack() {
	if [[ "${PV}" = "99999999" ]]; then
		git-r3_src_unpack

		(use gtk || use kde) && unpack "${winetricks_gentoo}.tar.bz2"
	else
		default
	fi
}

src_prepare() {
	local PATCHES
	if [[ "${PV}" = "99999999" ]] && [[ ! -z "${EGIT_VERSION}" ]]; then
		sed -i -e '/WINETRICKS_VERSION=/{s/=/=\"/;s/$/ '"${EGIT_VERSION}"'\"/}' \
			"${S}/src/winetricks" || die "sed failed"
	fi
	if use gtk || use kde; then
		winetricks_disable_gui_component "${S}/src/winetricks" false
	else
		winetricks_disable_gui_component "${S}/src/winetricks" true
	fi
	winetricks_disable_version_check "${S}/src/winetricks"
	default
}

src_test() {
	./tests/shell-checks || die "test(s) failed"
}

src_install() {
	default
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
