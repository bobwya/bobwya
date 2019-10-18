# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://git.linuxtv.org/${PN}.git"
	inherit git-r3
fi

DESCRIPTION="EDID decoder and conformance tester"
HOMEPAGE="https://git.linuxtv.org/edid-decode.git/about/"
KEYWORDS="-* ~amd64 ~ppc ~x86 ~amd64-linux ~arm-linux ~x86-linux"
LICENSE="MIT"

SLOT="0"
IUSE=""

CDEPEND=""
DEPEND="${CDEPEND}"
RDEPEND="${CDEPEND}"

src_prepare() {
	default

	sed -e "s| -g||" -i -- Makefile || die "sed failed"
}

src_install() {
	dobin "${PN}"
	doman "${PN}.1"

	default
}
