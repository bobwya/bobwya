# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools toolchain-funcs

DESCRIPTION="Extracts files from Microsoft cabinet archive files"
HOMEPAGE="https://www.cabextract.org.uk/"
if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/kyz/libmspack.git"
	S="${WORKDIR}/${P}/${PN}"
else
	SRC_URI="https://github.com/kyz/libmspack/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE="extras"

RDEPEND="extras? ( dev-lang/perl )"

src_prepare() {
	[[ "${PV}" == "9999" ]] && ./autogen.sh
	default
	# the code attempts to set up a fnmatch replacement, but then fails to code
	# it properly leading to undefined references to rpl_fnmatch().  This may be
	# removed in the future if building still works by setting "yes" to "no".
	export ac_cv_func_fnmatch_works=yes
	[[ "${PV}" == "9999" ]] &&  eautoreconf
}

src_compile() {
	emake AR="$(tc-getAR)"
}

src_install() {
	local DOCS=( AUTHORS ChangeLog INSTALL NEWS README TODO doc/magic )
	default
	docinto html
	dodoc doc/wince_cab_format.html
	if use extras; then
		dobin src/{wince_info,wince_rename,cabinfo,cabsplit}
	fi
}
