# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

DESCRIPTION="Manage active wine version"
HOMEPAGE="http://github.com/bobwya/eselect-wine"
SRC_URI="https://github.com/bobwya/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
IUSE=""

RDEPEND="app-admin/eselect
		dev-util/desktop-file-utils
		!!app-emulation/wine:0"

src_install() {
	keepdir "/etc/eselect/wine"

	insinto "/usr/share/eselect/modules"
	doins "wine.eselect"
	doman "man/wine.eselect.5"
}

pkg_prerm() {
	# Avoid conflicts with app-emulation/wine:0 - if this is installed later on
	if [[ -z "${REPLACED_BY_VERSION}" ]]; then
		elog "${CATEGORY}/${PN} is being uninstalled, removing symlinks"
		eselect wine unset --all --clean || die "eselect wine unset failed"
	else
		einfo "${CATEGORY}/${PN} is being updated/reinstalled, not modifying symlinks"
	fi
}
