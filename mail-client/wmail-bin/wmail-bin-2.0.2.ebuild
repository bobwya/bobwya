# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

DESCRIPTION="The missing desktop client for Gmail & Google Inbox"
HOMEPAGE="https://github.com/Thomas101/${PN%-bin}"

MY_PN="WMail"
SRC_URI="amd64? ( ${HOMEPAGE}/releases/download/v${PV}/${MY_PN}_${PV//./_}_prerelease_linux_x86_64.tar.gz -> wmail-${PV}-amd64.tar.gz )
		x86? ( ${HOMEPAGE}/releases/download/v${PV}/${MY_PN}_${PV//./_}_prerelease_linux_ia32.tar.gz -> wmail-${PV}-x86.tar.gz )"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="dev-libs/nss
		gnome-base/gconf
		media-libs/alsa-lib
		x11-libs/gtk+:2
		x11-libs/libXtst
		x11-misc/xssstate"

S="${WORKDIR}"

src_install() {
	[[ "${ABI}" == "amd64" ]]	&& local pkg_dir="${S}/${MY_PN}-linux-x64"
	[[ "${ABI}" == "x86" ]]		&& local pkg_dir="${S}/${MY_PN}-linux-ia32"

	dodir "/opt/${PN%-bin}"
	dodir "/opt/bin"
	dodir "/usr/share/applications"
	rsync -ach --safe-links "${pkg_dir}"/ "${D}/opt/${PN%-bin}"/
	ln -s "${D}/opt/${PN%-bin}/${MY_PN}" "${D}/opt/bin/${PN%-bin}"
	insinto "/usr/share/applications"
	doins "${FILESDIR}/${PN%-bin}.desktop"
}