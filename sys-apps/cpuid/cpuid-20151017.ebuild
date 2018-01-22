# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit toolchain-funcs

DESCRIPTION="Utility to get detailed information about CPU(s) using the
CPUID instruction"
HOMEPAGE="http://www.etallen.com/cpuid.html"
SRC_URI="http://www.etallen.com/${PN}/${P}.src.tar.gz"

KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="GPL-2"
IUSE=""

src_prepare() {
	PATCHES+=(
		"${FILESDIR}"/${PN}-20150606-Makefile.patch
		"${FILESDIR}"/${PN}-20110305-fPIC.patch #376245
	)
	default
}

src_install() {
	emake BUILDROOT="${D}" install
}
