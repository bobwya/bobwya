# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

PYTHON_COMPAT=( python3_4 )

inherit distutils-r1 gnome2-utils

DESCRIPTION="Lutris is an open source gaming platform for GNU/Linux."
HOMEPAGE="http://lutris.net/"

if [[ "${PV}" == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/lutris/${PN}.git"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="https://github.com/lutris/${PN}/archive/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND="
	dev-python/configparser"
RDEPEND="
	${DEPEND}
	dev-python/dbus-python
	dev-python/pygobject:3[threads]
	dev-python/pyyaml
	dev-python/pyxdg
	net-libs/libsoup
	x11-apps/xrandr
	x11-apps/xgamma
	x11-misc/xdg-utils"

# INSTALL contains list of optional deps
DOCS=( AUTHORS README.rst INSTALL.rst )

python_install() {
	distutils-r1_python_install
}

src_prepare() {
	distutils-r1_src_prepare
}

src_compile() {
	distutils-r1_src_compile
}

src_install() {
	distutils-r1_src_install
}

pkg_preinst() {
	gnome2_icon_savelist
	gnome2_schemas_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
	gnome2_schemas_update

	elog "For a list of optional dependencies (runners) see:"
	elog "/usr/share/doc/${PF}/INSTALL.rst"
}

pkg_postrm() {
	gnome2_icon_cache_update
	gnome2_schemas_update
}
