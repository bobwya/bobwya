# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop gnome2-utils qmake-utils

DESCRIPTION="Qt5-based GPU overclocking tool"
HOMEPAGE="https://github.com/Lurkki14/tuxclocker"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/Lurkki14/${PN}.git"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	SRC_URI="https://github.com/Lurkki14/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

COMMON_DEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
	x11-drivers/nvidia-drivers[driver,static-libs,tools]
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}"

DOC=( "README.md" )

src_configure() {
	eqmake5
}

src_install() {
	newicon -s scalable "gpuonfire.svg" "${PN}.svg"
	make_desktop_entry "${PN}"
	dobin "${PN}"
	dodoc
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
