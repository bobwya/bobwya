# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

inherit perl-module

DESCRIPTION="A tool to probe system hardware, check operability and upload results"
HOMEPAGE="https://github.com/linuxhw/hw-probe"

if [[ ${PV} == 9999 ]]; then
	EGIT_REPO_URI="https://github.com/linuxhw/${PN}.git"
	SRC_URI=""
	KEYWORDS=""
	inherit git-r3
else
	SRC_URI="https://github.com/linuxhw/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~ppc ~x86 ~arm-linux ~x86-linux"
fi

LICENSE="LGPL-2.1+"
SLOT="0"

DEPEND=""
RDEPEND="${DEPEND}
	>=dev-lang/perl-5.20
	net-misc/curl
	sys-apps/dmidecode
	sys-apps/hwinfo
	sys-apps/pciutils
	sys-apps/smartmontools
	sys-apps/usbutils
	virtual/perl-Data-Dumper
	virtual/perl-Digest-SHA
	x11-misc/edid-decode
"

src_prepare() {
	# shellcheck disable=SC2016
	sed -i '\:^prefix :a\ dummy_build_folder := $(shell mkdir -p ${prefix})' \
		"${S}/Makefile" || die "sed failed"
	default
}

src_compile() {
	emake prefix="${D}usr"
}

src_install() {
	emake install prefix="${D}usr"
	default
}

pkg_postinst() {
	einfo "Recommended addtional packages to provide better hardware detection:"
	einfo "app-admin/mcelog"
	einfo "app-admin/sysstat"
	einfo "dev-libs/opensc"
	einfo "dev-util/vulkan-tools"
	einfo "net-wireless/rfkill"
	einfo "sys-apps/cpuid"
	einfo "sys-apps/hdparm"
	einfo "sys-apps/i2c-tools"
	einfo "sys-apps/inxi"
	einfo "sys-apps/memtester"
	einfo "x11-apps/mesa-progs"
	einfo "x11-apps/xinput"
	einfo "x11-apps/xvinfo"
	einfo
	einfo "Additional suggested packages:"
	einfo "media-gfx/sane-backends"
	einfo "net-print/hplip"
	einfo
}
