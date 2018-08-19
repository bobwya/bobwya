# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-mod git-r3

DESCRIPTION="Non-fuse kernel driver for exFat and VFat file systems"
HOMEPAGE="https://github.com/dorimanx/exfat-nofuse"

EGIT_REPO_URI="https://github.com/dorimanx/exfat-nofuse.git"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS=""
IUSE=""

RDEPEND="!sys-fs/fuse-exfat"
DEPEND="${RDEPEND}"

MODULE_NAMES="exfat(kernel/fs:${S})"
BUILD_TARGETS="all"

src_prepare(){
	sed -i -e "/^KREL/,2d" Makefile || die "sed failed"
	if kernel_is eq 4 18; then
		local PATCHES=( "${FILESDIR}/${P}-kernel_18.1_timespec_fix.patch" )
	fi
	default
}

src_compile(){
	BUILD_PARAMS="KDIR=${KV_OUT_DIR} M=${S}"
	linux-mod_src_compile
}
