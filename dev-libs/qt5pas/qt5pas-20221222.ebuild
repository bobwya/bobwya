# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit qmake-utils

BASE_URI="https://gitlab.com/freepascal.org/lazarus/lazarus"
if [[ "${PV}" == "99999999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="${BASE_URI}.git"
else
	[[ "${PV}" == "20221116" ]] && LAZARUS_COMMIT="4a24daea09306b8f4712f35bbaaf708da18bcb06" # QtPas version: 1.2.11
	[[ "${PV}" == "20221222" ]] && LAZARUS_COMMIT="70bc333d28c19f6c87c87a60fe55426c0f2ac8d6" # QtPas version: 1.2.12
	SRC_URI="${BASE_URI}/-/archive/${LAZARUS_COMMIT}/lazarus-main.tar.bz2?path=lcl/interfaces/qt5/cbindings -> ${P}.tar.bz2"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Free Pascal Qt5 bindings library updated by lazarus IDE."
HOMEPAGE="https://www.lazarus-ide.org/"

LICENSE="LGPL-3"
SLOT="0"

DEPEND="
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtprintsupport:5
	dev-qt/qtx11extras:5
"
RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES="${FILESDIR}/01_inlines-hidden.patch"

src_unpack() {
	default

	qt5pas_directory="$(find "${WORKDIR}" -type f -iname "qt5pas.pro" -printf "%h")"
	eerror "qt5pas_directory: '${qt5pas_directory}'"
	[[ -d "${qt5pas_directory}" ]] || die "directory not found: '${qt5pas_directory}'"
	rsync -ach "${qt5pas_directory}/" "${T}/qt5pas/" || die "rsync failed"
	rm -rf "${S}"/* || die "rm failed"
	rsync -ach "${T}/qt5pas/" "${S}/" || die "rsync failed"
}

src_configure() {
	eqmake5 "QT += x11extras" Qt5Pas.pro
}

src_install() {
	emake INSTALL_ROOT="${D}" install
}
