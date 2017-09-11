# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit git-r3

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/merces/${PN}.git"
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
	if [[ "${PV}" = "9999" ]]; then
		git-r3_src_unpack
		return
	fi

	local PE_GIT_COMMIT
	# shellcheck disable=SC2086
	unpack ${A}
	case "${PV}" in
		0.80)
			PE_GIT_COMMIT="71880441da80bbf38d3b0987e97dafe3e1258725";;
		*)
			return;;
	esac
	EGIT3_STORE_DIR="${EGIT3_STORE_DIR:-${T}}" \
	EGIT_REPO_URI="https://github.com/merces/libpe.git" \
	EGIT_CHECKOUT_DIR="${S}/lib/libpe/" \
	EGIT_COMMIT="${PE_GIT_COMMIT}" \
		git-r3_src_unpack
}

src_prepare() {
	local PATCHES
	if [[ "${PV}" == "0.80" ]]; then
		PATCHES+=(
			"${FILESDIR}/${PN}-0.80-fix_destdir_and_prefix.patch"
			"${FILESDIR}/${PN}-0.80-fix_compatibility_with_openssl_1.1.0.patch"
			"${FILESDIR}/${PN}-0.80-remove_const_qualifier_from_parent_scope.patch"
		)
	fi
	default
}

src_compile() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)"
}

src_install() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)" install
}