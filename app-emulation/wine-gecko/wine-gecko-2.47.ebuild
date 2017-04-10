# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator

MY_PN="${PN/-/_}"
MY_PV="$(replace_version_separator '_' '''-''')"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="A Mozilla Gecko based version of Internet Explorer for Wine"
HOMEPAGE="https://winehq.org"
SRC_URI="
	abi_x86_32? ( https://dl.winehq.org/wine/${PN}/${MY_PV}/${MY_P}-x86.msi )
	abi_x86_64? ( https://dl.winehq.org/wine/${PN}/${MY_PV}/${MY_P}-x86_64.msi )
"

LICENSE="Apache-2.0 BSD BSD-2 MIT MPL-2.0"
SLOT="${PV}"
KEYWORDS="~amd64 ~x86"
IUSE="abi_x86_32 abi_x86_64"

S="${WORKDIR}"

src_install(){
	insinto "/usr/share/wine/gecko"
	use abi_x86_32 && doins "${DISTDIR}/${MY_P}-x86.msi"
	use abi_x86_64 && doins "${DISTDIR}/${MY_P}-x86_64.msi"
}
