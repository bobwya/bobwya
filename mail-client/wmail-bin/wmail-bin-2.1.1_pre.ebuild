# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit versionator

DESCRIPTION="The missing desktop client for Gmail & Google Inbox"
HOMEPAGE="https://github.com/Thomas101/${PN%-bin}"

MY_PN="WMail"
MY_PV=$(replace_all_version_separators '_')
MAIN_VERISON="${PV}"
if [[ "${PV}" =~ _pre ]]; then
	MY_PV="${MY_PV/_pre/_prerelease}"
	MAIN_VERISON="v${PV%_pre*}"
fi
SRC_URI="amd64? ( ${HOMEPAGE}/releases/download/${MAIN_VERISON}/${MY_PN}_${MY_PV}_linux_x86_64.tar.gz -> ${PN}-${PV}-amd64.tar.gz )
		x86? ( ${HOMEPAGE}/releases/download/${MAIN_VERISON}/${MY_PN}_${MY_PV}_linux_ia32.tar.gz -> ${PN}-${PV}-x86.tar.gz )"

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