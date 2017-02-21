# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools

DESCRIPTION="Flexible filesystem archiver for backup and deployment tool"
HOMEPAGE="http://www.fsarchiver.org"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/fdupoux/${PN}.git"
	EGIT3_STORE_DIR="${T:-EGIT3_STORE_DIR}"
	inherit git-r3
	SRC_URI=""
else
	SRC_URI="https://github.com/fdupoux/${PN}/releases/download/${PV}/${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="debug lzma lzo static"

DEPEND="dev-libs/libgcrypt:0=
	sys-apps/util-linux:0=
	>=sys-fs/e2fsprogs-1.41.4
	lzma? ( >=app-arch/xz-utils-4.999.9_beta )
	lzo? ( >=dev-libs/lzo-2.02 )
	static? ( lzma? ( app-arch/xz-utils[static-libs] ) )"
RDEPEND="${DEPEND}"

src_prepare() {
	default
	sed -i -e 's/^\([a-z]*_CFLAGS.*\)-ggdb/\1/' src/Makefile.am || die "sed	failed"
	eautoreconf
}

src_configure() {
	myeconfargs=(
		$(use_enable lzma)
		$(use_enable lzo)
		$(use_enable static)
		$(use_enable debug devel)
	)
	econf "${myeconfargs[@]}"
}
