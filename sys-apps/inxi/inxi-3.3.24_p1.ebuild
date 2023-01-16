# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit optfeature

DESCRIPTION="Perl script that collects and displays system information."
HOMEPAGE="https://github.com/smxi/inxi"

if [ "${PV}" = "9999" ]; then
	inherit git-r3
	MY_P="${P}"
	EGIT_REPO_URI="https://github.com/smxi/${PN}.git"
else
	MY_PV="${PV/_p/-}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://github.com/smxi/${PN}/archive/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="
	app-text/tree
	dev-lang/perl:0=
	dev-perl/Cpanel-JSON-XS
	sys-apps/pciutils
	sys-apps/usbutils
	virtual/perl-HTTP-Tiny
	virtual/perl-IO-Socket-IP
	virtual/perl-Time-HiRes
	"

S="${WORKDIR}/${MY_P}"

src_install() {
	dobin "${PN}"
	doman "${PN}.1"
}

pkg_postinst() {
	optfeature_header "Recommended system programs:"
	optfeature "blockdev" sys-apps/util-linux
	optfeature "bt-adapter" net-wireless/bluez-tools
	optfeature "dig" net-dns/bind-tools
	optfeature "dmidecode" sys-apps/dmidecode
	optfeature "doas" app-admin/doas
	optfeature "fdisk" sys-apps/util-linux
	optfeature "file" sys-apps/file
	optfeature "hciconfig" net-wireless/bluez[deprecated,extra-tools]
	optfeature "hddtemp" app-admin/hddtemp
	optfeature "ifconfig" sys-apps/net-tools
	optfeature "ip" sys-apps/net-tools
	optfeature "ipmitool" sys-apps/ipmitool
	optfeature "ipmi-sensors" sys-libs/freeipmi
	optfeature "lsblk" sys-apps/util-linux
	optfeature "lvs" sys-fs/lvm2[lvm]
	optfeature "mdadm" sys-fs/mdadm
	optfeature "modinfo" sys-apps/kmod
	optfeature "runlevel" sys-apps/openrc sys-apps/systemd
	optfeature "sensors" sys-apps/lm-sensors
	optfeature "smartctl" sys-apps/smartmontools
	optfeature "sudo" app-admin/sudo
	optfeature "upower" sys-power/upower
	optfeature "uptime" sys-process/procps
	optfeature_header "Recommended display information programs:"
	optfeature "glxinfo" x11-apps/mesa-progs
	optfeature "wmctrl" x11-misc/wmctrl
	optfeature "xdpyinfo" x11-apps/xdpyinfo
	optfeature "xprop" x11-apps/xprop
	optfeature "xdriinfo" x11-apps/xdriinfo
	optfeature "xrandr" x11-apps/xrandr
	optfeature_header "Recommended downloader programs (only one needed):"
	optfeature "curl" net-misc/curl
	optfeature "dig" net-dns/bind-tools
	optfeature "wget" net-misc/wget
}
