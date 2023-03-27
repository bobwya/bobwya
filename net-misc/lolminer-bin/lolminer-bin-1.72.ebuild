# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker

MY_SPN="${PN%-bin}"
MY_PN="lolMiner"
MY_PV="${PV/_beta/b}"
MY_PV="${PV/_alpha/a}"

BASE_URI="https://github.com/Lolliedieb/lolMiner-releases"
DESCRIPTION="A multi algorithm crypto miner client supporting AMD & Nvidia GPUs"
HOMEPAGE="https://github.com/Lolliedieb/lolMiner-releases"
SRC_URI="${BASE_URI}/releases/download/${MY_PV}/${MY_PN}_v${MY_PV}_Lin64.tar.gz -> ${P}.tar.gz"

KEYWORDS="-* ~amd64"
LICENSE="Boost-1.0 BSD lolMiner MIT"
SLOT="0"

DEPEND=""
RDEPEND=""

PKG_DIR="/opt/${MY_SPN}"
QA_PREBUILT="${PKG_DIR}/*"

S="${WORKDIR}/${MY_PV}"

src_prepare() {
	sed -i -e "s|[.]/${MY_PN}|${EPREFIX}${PKG_DIR}/${MY_PN}|g" *.sh \
		|| die "sed failed"
	eapply_user
}

src_install() {
	exeopts -m755
	exeinto "${PKG_DIR}"
	doexe "${MY_PN}" *".sh"
	dosym -r "${PKG_DIR}/${MY_PN}" "/opt/bin/${MY_PN}"

	insinto "/etc/${MY_SPN}"
	doins "${MY_PN}.cfg"

	dodoc "readme.txt"
}
