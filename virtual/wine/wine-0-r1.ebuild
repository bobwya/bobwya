# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Virtual for WINE that supports multiple variants and slotting"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+abi_x86_32 +abi_x86_64"

REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

RDEPEND="
	|| (
		app-emulation/wine-vanilla[abi_x86_32=,abi_x86_64=]
		app-emulation/wine-staging[abi_x86_32=,abi_x86_64=]
	)
	!app-emulation/wine:0"
