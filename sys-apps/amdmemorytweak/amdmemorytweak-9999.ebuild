# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Read and modify memory timings on AMD graphics cards"
HOMEPAGE="https://github.com/Eliovp/amdmemorytweak"

MY_PN="AmdMemTweak"

if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/Eliovp/${PN}.git"
else
	SRC_URI="https://github.com/Eliovp/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND="sys-apps/pciutils"
RDEPEND="${DEPEND}"

src_configure() {
	tc-export CXX
}

src_compile() {
	( ${CXX} -o "linux/${PN}" "linux/${MY_PN}.cpp" ${CXXFLAGS} -lpci -lresolv || false ) \
		|| die "${CXX}: unable to compile ${PN}"
}

src_install() {
	dobin "linux/${PN}"
}
