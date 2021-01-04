# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=7

inherit java-utils-2

DESCRIPTION="Java-based tools to rename TV shows, download subtitles, and validate checksums"
HOMEPAGE="https://www.filebot.net/"

MY_PN="FileBot"
SRC_URI="https://downloads.sourceforge.net/project/${PN}/${PN}/${MY_PN}_${PV}/${MY_PN}_${PV}-portable.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="
	media-libs/chromaprint
	media-libs/fontconfig
	|| (
		>=virtual/jdk-1.8
		>=virtual/jre-1.8
	)"

S="${WORKDIR}"

pkg_pretend() {
	local java_package
	java_package="$(
		eselect --brief --colour=no java-vm show system 2>/dev/null \
			| sed -e 's@^[[:blank:]]*@dev-java/@' -e 's@[-]\([^-]*\)$@:\1@'
	)"

	if [[ -z "${java_package}" ]]; then
		die "unable to determine active system java-vm"
	fi
	if ! has_version "${java_package}[javafx]"; then
		die "active system java-vm '${java_package}' does not support javafx"
	fi
}

src_install() {
	java-pkg_dojar "${MY_PN}.jar"
	exeopts -m755
	exeinto "/usr/bin"
	newexe "${FILESDIR}/${PN}-4.1.sh" "${PN}"
	insopts -m644
	insinto "/usr/share/pixmaps"
	doins "${FILESDIR}/${PN}.svg"
	insinto "/usr/share/applications"
	doins "${FILESDIR}/${PN}.desktop"
}
