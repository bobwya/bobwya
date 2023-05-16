# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/mentebinaria/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/mentebinaria/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

DESCRIPTION="The PE file analysis toolkit"
HOMEPAGE="https://pev.sourceforge.net/"
LICENSE="GPL-2+"
SLOT="0"

DEPEND="dev-libs/openssl:0"
RDEPEND="!app-forensics/pev
		${DEPEND}"

src_compile() {
	emake prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)" all
}

src_install() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)" install
}
