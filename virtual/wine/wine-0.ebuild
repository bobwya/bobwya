# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="Virtual for WINE that supports multiple variants and slotting"

SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND="
	|| (
		app-emulation/wine-vanilla
		app-emulation/wine-staging
	)
	!app-emulation/wine:0"
