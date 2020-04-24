# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=7

inherit java-utils-2

DESCRIPTION="Java-based tools to rename TV shows, download subtitles, and validate checksums"
HOMEPAGE="https://www.filebot.net/"

MY_PN="FileBot"
SRC_URI="https://get.filebot.net/${PN}/${MY_PN}_${PV}/${MY_PN}_${PV}-portable.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""

RDEPEND="
	media-libs/chromaprint[tools]
	media-libs/fontconfig
	media-libs/libmediainfo[curl,mms]
	|| (
		>=virtual/jdk-11
		>=virtual/jre-11
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
		die "active system java-vm ${java_package}, does not have javafx support"
	fi
}

src_install() {
	if use x86; then
		lib_arch="Linux-i686"
	elif use amd64; then
		lib_arch="Linux-x86_64"
	fi
	insinto /usr/share/filebot/lib
	doins "lib/${lib_arch}/libjnidispatch.so"
	doins "lib/${lib_arch}/lib7-Zip-JBinding.so"
	for i in jar/*;do java-pkg_dojar "$i";done
	exeopts -m755
	exeinto "/usr/bin"
	newexe "${FILESDIR}/filebot-4.8.5.sh" "${PN}"
	insopts -m644
	insinto "/usr/share/pixmaps"
	doins "${FILESDIR}/${PN}.svg"
	insinto "/usr/share/applications"
	doins "${FILESDIR}/${PN}.desktop"
}
