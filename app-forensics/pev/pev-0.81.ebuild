# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

LIBPE_PN="libpe"

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/merces/${PN}.git"
	EGIT_REPO_MERCES_LIBPE_URI="https://github.com/merces/${LIBPE_PN}.git"
	EGIT_SUBMODULES=()
	inherit git-r3
else
	[[ "${PV}" == "0.81" ]] && LIBPE_COMMIT="ce39b127328e3863e08163962f7ecc768eb2555e"
	SRC_URI="
		https://github.com/merces/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/merces/${LIBPE_PN}/archive/${LIBPE_COMMIT}.tar.gz -> ${LIBPE_PN}-${LIBPE_COMMIT}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

DESCRIPTION="The PE file analysis toolkit"
HOMEPAGE="https://pev.sourceforge.net/"
LICENSE="GPL-2+"
SLOT="0"

DEPEND="dev-libs/openssl:0"
RDEPEND="${DEPEND}"

src_unpack() {
	if [[ "${PV}" == "9999" ]]; then
		git-r3_src_unpack
		EGIT_REPO_URI="${EGIT_REPO_MERCES_LIBPE_URI}" \
		EGIT_CHECKOUT_DIR="${S}/lib/${LIBPE_PN}/" \
		git-r3_src_unpack
	else
		default
		local LIBPE_DIR="${S}/lib/libpe"
		rmdir "${LIBPE_DIR}" || die "rm failed"
		mv -f "${WORKDIR}/${LIBPE_PN}-${LIBPE_COMMIT}" "${LIBPE_DIR}" || die "mv failed"
	fi
}

src_compile() {
	emake prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)" all
}

src_install() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" libdir="${EPREFIX}/usr/$(get_libdir)" install
}
