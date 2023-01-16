# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit bash-completion-r1 linux-info systemd toolchain-funcs

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

PATCHES=( "${FILESDIR}/${PN}-0.1.7-disable_systemd+bash_completion_install.patch" )

src_compile() {
	tc-export CC

	myemakeargs=(
		CC="${CC}"
		CFLAGS="${CFLAGS}"
		PREFIX="${EPREFIX}/usr"
		confdir="${EPREFIX}/etc"
	)

	emake -j1 "${myemakeargs[@]}"
}

src_install() {
	emake -j1 "${myemakeargs[@]}" DESTDIR="${ED}" install-c

	for completion in "ec_probe" "nbfc" "nbfc_service"; do
		dobashcomp "${S}/completion/bash/${completion}"
	done

	einstalldocs

	newinitd "${FILESDIR}/nbfc.initd" nbfc
	systemd_dounit "nbfc_service.service"
}
