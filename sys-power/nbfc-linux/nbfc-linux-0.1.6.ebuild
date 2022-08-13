# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info systemd toolchain-funcs

DESCRIPTION="Lightweight C port of NoteBook FanControl (no Mono required)"
HOMEPAGE="https://github.com/nbfc-linux/nbfc-linux"

if [[ ${PV} == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/nbfc-linux/${PN}.git"
else
	SRC_URI="https://github.com/nbfc-linux/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND=""

RDEPEND="${DEPEND}
	sys-apps/dmidecode"

BDEPEND="virtual/pkgconfig"

CONFIG_CHECK="ACPI_EC_DEBUGFS HWMON X86_MSR"

PATCHES=( "${FILESDIR}/${PN}-0.1.6-disable_systemd_unit_install.patch" )

src_compile() {
	tc-export CC

	local myemakeargs=(
		CC="${CC}"
		CFLAGS="${CFLAGS}"
	)

	emake -j1 "${myemakeargs[@]}"
}

src_install() {
	emake -j1 "${myemakeargs[@]}" DESTDIR="${D}" install
	einstalldocs

	newinitd "${FILESDIR}/nbfc.initd" nbfc

	systemd_dounit "etc/systemd/system/nbfc_service.service"
}
