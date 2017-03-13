# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils

DESCRIPTION="Dockmanager scripts for various KDE 4 applications"
HOMEPAGE="http://kde-look.org/content/show.php/dockmanager-kde_and_extra?content=151511"

SRC_URI="http://kde-look.org/CONTENT/content-files/151511-${P}.tgz"

RESTRICT="mirror strip"
LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"

S="${WORKDIR}"
TARGET_DIR="/usr/share/dockmanager"

DEPEND=""
RDEPEND=">=kde-apps/kdebase-runtime-meta-4.8.0
		x11-misc/dockmanager"

src_install() {
	diropts -m755
	dodir "${TARGET_DIR}"
	# hack to make sure python2 is loaded instead of python3
	sed -i -e 's|^\#\!\/usr\/bin\/env python$|#!/usr/bin/env python2|' "${S}/scripts"/*.py || die "sed failed"
	into "${TARGET_DIR}"
	doins -r "${S}/metadata"
	doins -r "${S}/scripts"
}
