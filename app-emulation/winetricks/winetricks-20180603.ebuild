# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit gnome2-utils

if [[ ${PV} == "99999999" ]] ; then
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
		dev-util/shellcheck
	)"

RDEPEND="app-arch/cabextract
	app-arch/p7zip
	app-arch/unzip
	net-misc/wget
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
	(($# == 1)) || die "Invalid parameter count: ${#} (1)"
	[[ -f "${1}" ]] || die "winetricks script file not valid: \"${1}\""

	mv "${1}" "${1}.bak" || die "mv failed"
	awk -vgtk_use="$(use gtk && echo 1)" \
		-vkde_use="$(use kde && echo 1)" \
		-f "${FILESDIR}/${PN}-disable_gui_component.awk" \
		"${1}.bak" > "${1}" || die "awk failed"
}

src_unpack() {
	if [ "${PV}" = "99999999" ]; then
		git-r3_src_unpack
		(use gtk || use kde) && unpack "${winetricks_gentoo}.tar.bz2"
	else
		default
	fi
}

src_prepare() {
	local PATCHES=(
		"${FILESDIR}/${PN}-20180513_add_bashcomp.patch"
		"${FILESDIR}/${PN}-20180603_fix_multislot_wine64_variants.patch"
	)
	if use gtk || use kde; then
		winetricks_disable_gui_component "${S}/src/winetricks"
	else
		PATCHES+=( "${FILESDIR}/${PN}-20180513_disable_gui.patch" )
	fi
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
	(use gtk || use kde) && gnome2_icon_savelist
}

pkg_postinst() {
	(use gtk || use kde) && gnome2_icon_cache_update
}

pkg_postrm() {
	(use gtk || use kde) && gnome2_icon_cache_update
}
