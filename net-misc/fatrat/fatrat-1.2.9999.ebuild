# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="https://github.com/LubosD/fatrat.git"
EGIT_BRANCH="1.2"

inherit cmake-utils eutils git-2

DESCRIPTION="Qt4 (C++) based download manager with support for HTTP, FTP, SFTP, BitTorrent, rapidshare and more"
HOMEPAGE="http://fatrat.dolezel.info https://github.com/LubosD/fatrat"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="bittorrent +curl doc jabber jplugins nls webinterface"

RDEPEND="dev-qt/qtdbus:4
	dev-qt/qtgui:4
	dev-qt/qtsvg:4
	bittorrent? ( <net-libs/rb_libtorrent-1.0.0
				>=dev-cpp/asio-1.1.0
				dev-qt/qtwebkit:4 )
	curl? ( >=net-misc/curl-7.18.2 )
	doc? ( dev-qt/assistant:4 )
	jabber? ( >=net-libs/gloox-0.9 )
	jplugins? ( >=virtual/jre-1.6:* )
	webinterface? ( dev-qt/qtscript:4
					>=dev-cpp/pion-5.0.0 )"
DEPEND=">=dev-util/cmake-2.6.0
		${RDEPEND}"

S="${WORKDIR}/${PN}"

src_configure() {
	local mycmakeargs="
		$(cmake-utils_use_with bittorrent) \
		$(cmake-utils_use_with curl) \
		$(cmake-utils_use_with doc DOCUMENTATION) \
		$(cmake-utils_use_with jabber) \
		$(cmake-utils_use_with jplugins) \
		$(cmake-utils_use_with nls) \
		$(cmake-utils_use_with webinterface)"
	if use jplugins; then
		if [ "${ARCH}" == "amd64" ]; then
			mycmakeargs+=( -DJAVA_AWT_LIBRARY="${JAVA_HOME}/jre/lib/${ARCH}/libjawt.so;${JAVA_HOME}/jre/lib/${ARCH}/xawt/libmawt.so" )
		else
			mycmakeargs+=( -DJAVA_AWT_LIBRARY="${JAVA_HOME}/jre/lib/i386/libjawt.so;${JAVA_HOME}/jre/lib/i386/xawt/libmawt.so" )
		fi
	fi
	cmake-utils_src_configure
}

src_install() {
	use bittorrent && echo "MimeType=application/x-bittorrent;" >> "${S}"/data/${PN}.desktop
	cmake-utils_src_install
}

pkg_postinst() {
	# this is a completely optional and NOT automagic dependency
	if ! has_version dev-libs/geoip; then
		elog "If you want the GeoIP support, then emerge dev-libs/geoip."
	fi
}
