# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/merces/${PN}.git
				   git://github.com/merces/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/merces/${PN}/archive/v${PV}.tar.gz"
	KEYWORDS="~x86 ~amd64"
fi

DESCRIPTION="The PE file analysis toolkit"
HOMEPAGE="http://pev.sourceforge.net/"
LICENSE="GPL-3+"
SLOT="0"

DEPEND=""
RDEPEND="${DEPEND}"

src_install() {
	exeinto "/usr/bin"
	doexe "pev"
	doman "pev.1"
}
