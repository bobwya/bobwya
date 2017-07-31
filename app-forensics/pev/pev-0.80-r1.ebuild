# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit git-r3

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/merces/${PN}.git
		   git://github.com/merces/${PN}.git"
else
	SRC_URI="https://github.com/merces/${PN}/archive/v${PV}.tar.gz"
	KEYWORDS="~x86 ~amd64"
fi

DESCRIPTION="The PE file analysis toolkit"
HOMEPAGE="http://pev.sourceforge.net/"
LICENSE="GPL-2+"
SLOT="0"

DEPEND="dev-libs/openssl:0"
RDEPEND="${DEPEND}"

src_unpack() {
	if [[ "${PV}" == 9999 ]]; then
		git-r3_src_unpack
	else
		unpack ${A}
		EGIT3_STORE_DIR="${EGIT3_STORE_DIR:-${T}}" \
		EGIT_REPO_URI="https://github.com/merces/libpe.git" \
		EGIT_CHECKOUT_DIR="${S}/lib/libpe/" \
		EGIT_BRANCH="master" \
			git-r3_src_unpack
	fi
}

src_prepare() {
	sed -i '/^prefix = /{s,/local,,g}' "${S}/src/Makefile" "${S}/lib/libpe/Makefile"
	sed -i '/^#define DEFAULT_PLUGINS_PATH /{s,/local,,g}' "${S}/src/config.c"
	local PATCHES
	if [[ "${PV}" == "0.80" ]]; then
		PATCHES+=(
			"${FILESDIR}/${PN}-0.80-fix_compatibility_with_openssl_1.1.0.patch"
			"${FILESDIR}/${PN}-0.80-remove_const_qualifier_from_parent_scope.patch"
		)
	fi
	default
}