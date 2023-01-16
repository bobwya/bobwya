# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

MY_PN="${PN%-nofuse}"
MY_P="${MY_PN}-${PV}"

inherit linux-info

if [[ "${PV}" == "9999" ]]; then
	inherit autotools git-r3
	EGIT_REPO_URI="https://github.com/relan/exfat.git"
else
	SRC_URI="https://github.com/relan/exfat/releases/download/v${PV}/${MY_P}.tar.gz"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc64 ~s390 ~sparc ~x86 ~arm-linux ~x86-linux"
	S="${WORKDIR}/${MY_P}"
fi

DESCRIPTION="exFAT filesystem utilities (without fuse)"
HOMEPAGE="https://github.com/relan/exfat"

LICENSE="GPL-2+"
SLOT="0"

RDEPEND="!sys-fs/exfat-utils"
DEPEND="${RDEPEND}"

DOCS=( "ChangeLog" )

CONFIG_CHECK="~EXFAT_FS"
ERROR_MTRR="EXFAT_FS not enabled in kernel"

src_prepare() {
	# exclude fuse directory
	sed -i 's/fuse label mkfs/label mkfs/' "${S}/Makefile.am" \
		|| die "sed failed"
	[[ "${PV}" == "9999" ]] && eautoreconf --install
	default
}

src_install() {
	default
	dosym exfatfsck.8 "/usr/share/man/man8/fsck.exfat.8"
	dosym mkexfatfs.8 "/usr/share/man/man8/mkfs.exfat.8"
}
