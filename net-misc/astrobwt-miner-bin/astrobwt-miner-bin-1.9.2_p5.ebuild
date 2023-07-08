# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

MY_EXE="astrominer"
MY_PN="${PN%-bin}"
MY_PV="V${PV/_p/.R}"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="An optimized CPU miner for the AstroBWTv3 hashing algorithm"
HOMEPAGE="https://github.com/dero-am/astrobwt-miner"
BASE_URI="${HOMEPAGE}/releases/download/${MY_PV}/astrominer-${MY_PV}"
SRC_URI="amd64? ( ${BASE_URI}_amd64_linux.tar.gz -> ${P}_amd64.tar.gz )
		arm64? ( ${BASE_URI}_aarch64_linux.tar.gz -> ${P}_arm64.tar.gz )"

KEYWORDS="-* ~amd64 ~arm64"
LICENSE="all-rights-reserved"
SLOT="0"

DEPEND=""
RDEPEND=""

PKG_DIR="/opt/${MY_PN}"
QA_PREBUILT="${PKG_DIR}/*"

S="${WORKDIR}/${MY_EXE}"

src_install() {
	exeopts -m755
	exeinto "${PKG_DIR}"
	doexe "${MY_EXE}"
	dosym -r "${PKG_DIR}/${MY_EXE}" "/opt/bin/${MY_EXE}"
}
