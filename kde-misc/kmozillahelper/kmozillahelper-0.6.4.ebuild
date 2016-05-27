# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"

inherit kde4-base

DESCRIPTION="Mozilla KDE Desktop Integration"
HOMEPAGE="https://github.com/openSUSE/kmozillahelper"

DESCRIPTION="Mozilla KDE Integration"

SRC_URI="https://github.com/openSUSE/${PN}/archive/${PV}.tar.gz"
KEYWORDS="amd64 x86"

LICENSE="MIT"
SLOT="4"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

pkg_postinst() {
	kde4-base_pkg_postinst
}
