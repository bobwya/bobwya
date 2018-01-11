# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit qmake-utils

DESCRIPTION="Wine Wizard is a new GUI for Wine written in Qt"
HOMEPAGE="https://github.com/LLIAKAJL/WineWizard"

MY_PN="WineWizard"
MY_P="${MY_PN}-${PV}"
if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/LLIAKAJL/${MY_PN}.git"
	EGIT3_STORE_DIR="${T:-EGIT3_STORE_DIR}"
	inherit git-r3
else
	SRC_URI="https://github.com/LLIAKAJL/${PN}/archive/${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

CDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtsingleapplication[qt5,X]
	dev-qt/qtwidgets:5
"
DEPEND="${CDEPEND}
"
RDEPEND="${CDEPEND}
"

src_prepare() {
	local PATCHES=( "${FILESDIR}/${PN}-3.0.0_purge_ad_support.patch" )
	default
}

src_configure() {
	eqmake5 . PREFIX="${ED}/usr"
	default
}

src_install() {
	emake install INSTALL_ROOT=""
}
