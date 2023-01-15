# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

DESCRIPTION="Wine Mono is a replacement for the .NET runtime and class libraries in Wine"
HOMEPAGE="https://www.winehq.org/"
SRC_URI="https://dl.winehq.org/wine/${PN}/${PV}/${PN}-bin-${PV}.tar.gz"

LICENSE="BSD-2 GPL-2 LGPL-2.1 MIT MPL-1.1"
SLOT="${PV}"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}"

src_install() {
	insinto "/usr/share/wine/mono"
	doins -r "${S}/${P}"
}
