# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

DESCRIPTION="Cryptocurrency miner for NVIDIA hardware, supporting a variety of algorithms"
HOMEPAGE="https://trex-miner.com/"

MY_PN="${PN%-bin}"
MY_P="${MY_PN}-${PV}"

SRC_URI="https://trex-miner.com/download/${MY_P}-linux.tar.gz -> ${P}.tar.gz"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"

RDEPEND="elibc_glibc? ( dev-util/nvidia-cuda-toolkit )"

EXE_DIR="/opt/${MY_PN}"
EXE_PATH="${EXE_DIR}/${MY_PN}"

QA_PREBUILT="${EXE_PATH}"

S="${WORKDIR}"

src_prepare() {
	sed -i -e "s|[.]/${MY_PN}|${EPREFIX}${EXE_PATH}|g" *.sh \
		|| die "sed failed"
	eapply_user
}

src_install() {
	exeinto "${EXE_DIR}"
	doexe "${MY_PN}"
	dosym ../.."${EXE_PATH}" "/usr/bin/${MY_PN}"
	doexe *.sh

	insinto "/etc/${MY_PN}"
	newins "config_example" "config.json"

	dodoc "help/"*".md" "README.md"

	dostrip -x ${QA_PREBUILT}
}
