# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

MY_SPN="${PN%-bin}"
MY_PN="SRBMiner-Multi"
MY_EXE="SRBMiner-MULTI"
MY_P="${MY_PN}-$(ver_rs 1- -)"

DESCRIPTION="A cryptocurrency miner for CPU and GPU (AMD, NVIDIA, INTEL) devices"
HOMEPAGE="https://www.srbminer.com/"
SRC_URI="https://github.com/doktor83/SRBMiner-Multi/releases/download/${PV}/${MY_P}-Linux.tar.gz"

KEYWORDS="-* ~amd64"
LICENSE="no-source-code"
SLOT="0/$(ver_rs 0- '')"

IUSE="cuda opencl"

RDEPEND="
	cuda? ( dev-util/nvidia-cuda-toolkit )
	opencl? ( virtual/opencl )
"

PKG_DIR="/opt/${MY_SPN}"
QA_PREBUILT="${PKG_DIR}/*"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	sed -i -e "s|[.]/${MY_EXE}|${EPREFIX}${PKG_DIR}/${MY_EXE}|g" *.sh \
		|| die "sed failed"
	eapply_user
}

src_install() {
	exeopts -m755
	exeinto "${PKG_DIR}"
	doexe "${MY_EXE}" *".sh"
	dosym -r "${PKG_DIR}/${MY_EXE}" "/opt/bin/${MY_EXE}"

	dodoc "ReadMe.txt"
}
