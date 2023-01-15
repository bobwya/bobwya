# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit toolchain-funcs

DESCRIPTION="C++ header-only library allowing iostream access ZLib-compressed streams"
HOMEPAGE="https://github.com/mateidavid/zstr.git"

if [ "${PV}" = "9999" ]; then
	EGIT_REPO_URI="https://github.com/mateidavid/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/mateidavid/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="examples"

RDEPEND=""
DEPEND="${RDEPEND}"

# FIXME
src_test() {
	cd "${S}/examples"
	local myemakeargs=(
		"CXX=$(tc-getCXX)"
		"CXXFLAGS=${CXXFLAGS}"
	)
	# shellcheck disable=SC2068
	emake all ${myemakeargs[@]}
}

src_install() {
	doheader "src/strict_fstream.hpp"
	doheader "src/zstr.hpp"
	if use examples; then
		docinto examples/
		dodoc -r examples/*
	fi
	default
}
