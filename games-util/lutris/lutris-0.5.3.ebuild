# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=7

PYTHON_COMPAT=( python3_{6,7} )
PYTHON_REQ_USE="sqlite,threads(+)"

inherit distutils-r1 virtualx xdg

DESCRIPTION="An open source gaming platform for GNU/Linux"
HOMEPAGE="https://lutris.net/"

if [[ "${PV}" == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/lutris/lutris.git"
	inherit git-r3
else
	SRC_URI="https://lutris.net/releases/${P/-/_}.tar.xz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${PN}"
fi

LICENSE="GPL-3"
SLOT="0"

RESTRICT="!test? ( test )"

BDEPEND="
	test? ( dev-python/nose[${PYTHON_USEDEP}] )
"

RDEPEND="
	app-arch/cabextract
	app-arch/p7zip
	app-arch/unrar
	app-arch/unzip
	dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	dev-python/python-evdev[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-python/setuptools[${PYTHON_USEDEP}]
	gnome-base/gnome-desktop:3[introspection]
	media-sound/fluid-soundfont
	net-libs/libsoup
	net-libs/webkit-gtk:4[introspection]
	sys-auth/polkit
	sys-process/psmisc
	x11-apps/mesa-progs
	x11-apps/xgamma
	x11-apps/xrandr
	x11-libs/gdk-pixbuf[introspection]
	x11-libs/gtk+:3[introspection]
	x11-libs/pango[introspection]
	x11-libs/libnotify
"

list_optional_dependencies() {
	local i package IFS
	local -a optional_packages_sorted_array \
			 optional_packages_array

	optional_packages_array=( "${@}" )
	# shellcheck disable=SC2068
	for i in ${!optional_packages_array[@]}; do
		has_version "${optional_packages_array[i]}" || continue
		unset -v 'optional_packages_array[i]'
	done
	# shellcheck disable=SC2207
	IFS=$'\n' optional_packages_sorted_array=( $(sort <<<"${optional_packages_array[*]}") )
	(( ${#optional_packages_sorted_array[@]} )) || return

	elog "Recommended additional packages:"
	# shellcheck disable=SC2068
	for package in ${optional_packages_sorted_array[@]}; do
		elog "  ${package}"
	done
}

python_install_all() {
	local DOCS=( "AUTHORS" "README.rst" "docs/installers.rst" )
	distutils-r1_python_install_all
}

python_test() {
	virtx nosetests -v || die "nosetests failed"
}

pkg_preinst() {
	xdg_pkg_preinst
}

pkg_postinst() {
	local -a optional_packages_array=(
		"app-emulation/winetricks"
		"dev-util/gtk-update-icon-cache"
		"games-util/xboxdrv"
		"sys-apps/pciutils"
		"virtual/wine"
		"x11-base/xorg-server[xephyr]"
	)

	xdg_pkg_postinst

	list_optional_dependencies "${optional_packages_array[@]}"

	elog "For a list of optional dependencies (runners) see:"
	elog "/usr/share/doc/${PF}/README.rst.bz2"

	# Quote README.rst
	elog "Lutris installations are fully automated through scripts, which can"
	elog "be written in either JSON or YAML. The scripting syntax is described"
	elog "in ${EROOT}/usr/share/doc/${PF}/installers.rst.bz2, and is also"
	elog "available online at lutris.net."
}

pkg_postrm() {
	xdg_pkg_postrm
}
