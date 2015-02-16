# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit kde4-base

DESCRIPTION="Mozilla KDE Integration"
HOMEPAGE="http://gitorious.org/firefox-kde-opensuse"
SRC_URI="https://build.opensuse.org/source/openSUSE:Factory/mozilla-kde4-integration/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2"
KEYWORDS="amd64 x86"
IUSE=""
SLOT="4"

DEPEND="kde-base/libkworkspace"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}"

pkg_postinst() {
	kde4-base_pkg_postinst
}
