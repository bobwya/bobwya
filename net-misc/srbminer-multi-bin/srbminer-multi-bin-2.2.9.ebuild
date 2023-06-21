# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

MY_SPN="${PN%-bin}"
MY_PN="SRBMiner-Multi"
MY_EXE="SRBMiner-MULTI"
MY_P="${MY_PN}-$(ver_rs 1- -)"

DESCRIPTION="A cryptocurrency miner that can mine different algorithms on AMD/Nvidia GPUs"
HOMEPAGE="https://www.srbminer.com/"
SRC_URI="https://github.com/doktor83/${MY_PN}/releases/download/${PV}/${MY_P}-Linux.tar.xz"

KEYWORDS="-* ~amd64"
LICENSE="no-source-code"
SLOT="0"

DEPEND=""
RDEPEND=""

PKG_DIR="/opt/${MY_SPN}"
QA_PREBUILT="${PKG_DIR}/*"

S="${WORKDIR}/${MY_P}"

src_install() {
	exeopts -m755
	exeinto "${PKG_DIR}"
	doexe "${MY_EXE}" *".sh"
	dosym -r "${PKG_DIR}/${MY_EXE}" "/opt/bin/${MY_EXE}"

	dodoc "ReadMe.txt"
}
