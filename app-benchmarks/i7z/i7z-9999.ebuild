# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic toolchain-funcs

DESCRIPTION="A better i7 (and now i3, i5) reporting tool for Linux"
HOMEPAGE="https://github.com/bobwya/i7z"

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="git://github.com/bobwya/i7z.git"
	EGIT_BRANCH="master"
	EGIT_CHECKOUT_DIR="${S}"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="
	sys-libs/ncurses:*"
DEPEND="${RDEPEND}"

src_unpack() {
	default
	[[ "${PV}" == "9999" ]] && git-r3_src_unpack
}

src_install() {
	emake DESTDIR="${ED}" docdir=/usr/share/doc/${PF} install
}
