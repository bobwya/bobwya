# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

DESCRIPTION="Gminer supports most popular crypto hashing algorithms on AMD+Nvidia platforms"
HOMEPAGE="https://gminer.info/"

MY_PN="${PN%-bin}"
BASE_URI="https://github.com/develsoftware/GMinerRelease"
SRC_URI="${BASE_URI}/releases/download/${PV}/${MY_PN}_$(ver_rs 1 '_')_linux64.tar.xz -> ${P}.tar.xz"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""

DEPEND=""
RDEPEND=""

EXE_DIR="/opt/${MY_PN}"
EXE_PATH="${EXE_DIR}/${MY_PN}"

QA_PREBUILT="${EXE_PATH}"

S="${WORKDIR}"

src_prepare() {
	sed -i -e "s|[.]/miner|${EPREFIX}${EXE_PATH}|g" *.sh \
		|| die "sed failed"
	eapply_user
}

src_install() {
	exeinto "${EXE_DIR}"
	newexe "miner" "${MY_PN}"
	dosym ../.."${EXE_PATH}" "/opt/bin/${MY_PN}"
	doexe *.sh
	insinto "/etc/${MY_PN}"
	newins "sample_config.txt" "config.txt"

	dodoc "readme.txt"

	dostrip -x ${QA_PREBUILT}
}
