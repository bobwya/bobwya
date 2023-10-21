# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

MY_PN="${PN%-bin}"
BIN_FILE="6abfdd7f707d155da0ecef6242593c19.bin"

BASE_URI="https://github.com/OneZeroMiner/onezerominer/releases/download"
DESCRIPTION="Nvidia/CUDA optimized GPU miner for crypto projects"
HOMEPAGE="https://github.com/OneZeroMiner/onezerominer"
SRC_URI="${BASE_URI}/v${PV}/${MY_PN}-linux-${PV}.tar.gz -> ${P}.tar.gz"
KEYWORDS="-* ~amd64"
LICENSE="all-rights-reserved"
SLOT="0"

RDEPEND="
	dev-util/nvidia-cuda-toolkit"

PKG_DIR="/opt/${MY_PN}"
QA_PREBUILT="${PKG_DIR}"

S="${WORKDIR}/${MY_PN}-linux"

src_prepare() {
	sed -i -e "s|[.]/${MY_PN}|${EPREFIX}${PKG_DIR}/${MY_PN}|g" "mine.sh" \
		|| die "sed failed"
	eapply_user
}

src_install() {
	exeopts -m755
	exeinto "${PKG_DIR}"
	doexe "${MY_PN}" "${BIN_FILE}"
	newexe "mine.sh" "mine_dynex.sh"
	dosym -r "${PKG_DIR}/${MY_PN}" "/opt/bin/${MY_PN}"
}
