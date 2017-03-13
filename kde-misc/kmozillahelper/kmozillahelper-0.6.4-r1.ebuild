# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit kde4-base

DESCRIPTION="Mozilla KDE Desktop Integration"
HOMEPAGE="https://github.com/openSUSE/kmozillahelper"

DESCRIPTION="Mozilla KDE Integration"

SRC_URI="https://github.com/openSUSE/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="amd64 x86"

LICENSE="MIT"
SLOT="4"
IUSE=""

DEPEND="
	!kde-misc/kmozillahelper:5"
RDEPEND="${DEPEND}"

src_prepare() {
	# Don't allow running as root: may break sandboxing during Portage-based
	# install of Mozilla applications (Firefox)
	# See https://github.com/bobwya/bobwya/issues/7#issuecomment-243017441
	local PATCHES=(
		"${FILESDIR}/${PN}-0.6.4-dont_run_as_root.patch"
		"${FILESDIR}/${PN}-0.6.4-use-x-icon.patch"
	)
	default
}

pkg_postinst() {
	kde4-base_pkg_postinst
}
