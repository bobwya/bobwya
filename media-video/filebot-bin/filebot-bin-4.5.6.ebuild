# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils

DESCRIPTION="Java-based GUI and console tools to rename TV/anime shows, download subtitles, and validate checksums"
HOMEPAGE="http://filebot.sourceforge.net/"

MY_PN="${PN%-bin}"
PACKAGE_NAME="FileBot"
SRC_URI="http://downloads.sourceforge.net/project/${MY_PN}/${MY_PN}/${PACKAGE_NAME}_${PV}/${PACKAGE_NAME}_${PV}-portable.zip"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND=">=virtual/jre-1.8
		!media-video/filebot"

S="${WORKDIR}"
QA_PREBUILT="/opt/${MY_PN}/"


src_install() {
	exeopts -m644
	exeinto "/opt/${MY_PN}"
	doexe "${PACKAGE_NAME}.jar"
	exeopts -m755
	exeinto "/usr/bin"
	newexe "${FILESDIR}/${MY_PN}.sh" "${MY_PN}"
	insopts -m644
	insinto "/usr/share/pixmaps"
	doins "${FILESDIR}/${MY_PN}.svg"
	insinto "/usr/share/applications"
	doins "${FILESDIR}/${MY_PN}.desktop"
}

