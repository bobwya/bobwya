# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PV="$(ver_cut 1-3)-$(ver_cut 5)"
MY_P="${PN}-${MY_PV}"

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..12} pypy3 )

inherit distutils-r1 pypi

DESCRIPTION="Provides a python interface to the database stored in sys-apps/hwdata package"
HOMEPAGE="https://github.com/xsuchy/python-hwdata"
SRC_URI="https://github.com/xsuchy/${PN}/archive/refs/tags/${PN}-${MY_PV}.tar.gz -> ${MY_P}.gh.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux"
RDEPEND="sys-apps/hwdata"

S="${WORKDIR}/${PN}-${MY_P}"

python_compile() {
	distutils-r1_python_compile
}
