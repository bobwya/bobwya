# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PLOCALES="be bg cs de el en es eu fr hu it pl pt_BR ru sk sr sr@latin sv_SE uk vi zh_CN"

inherit cmake-utils l10n gnome2-utils xdg-utils

DESCRIPTION="Qt based client for DirectConnect and ADC protocols, based on DC++ library"
HOMEPAGE="https://github.com/eiskaltdcpp/eiskaltdcpp"

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	KEYWORDS=""
else
	SRC_URI="https://github.com/${PN}/${PN}/archive/v${PV}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE="cli daemon dbus +dht +emoticons examples -gtk2 -gtk3 idn -javascript json libcanberra libnotify lua +minimal pcre qml qt4 +qt5 sound spell sqlite upnp -xmlrpc"

GTK_REQUIRED_USE="
	gtk2? ( !gtk3 )
	gtk3? ( !gtk2 )
	libcanberra? ( ^^ ( gtk2 gtk3 ) )
	libnotify? ( ^^ ( gtk2 gtk3 ) )
"
QT_REUIRED_USE="
	dbus? ( ^^ ( qt4 qt5 ) )
	javascript? ( ^^ ( qt4 qt5 ) )
	qml? ( ^^ ( qt4 qt5 ) )
	qt4? ( !qt5 )
	qt5? ( !qt4 )
	spell? ( ^^ ( qt4 qt5 ) )
	sqlite? ( ^^ ( qt4 qt5 ) )
"
REQUIRED_USE="
	${GTK_REQUIRED_USE}
	${QT_REUIRED_USE}
	cli? ( ^^ ( json xmlrpc ) )
	emoticons? ( ^^ ( gtk2 gtk3 qt4 qt5 ) )
	json? ( !xmlrpc )
	sound? ( ^^ ( gtk2 gtk3 qt4 qt5 ) )
"

GTK_COMMON_DEPEND="
	>=dev-libs/glib-2.24:2
	x11-libs/pango
	x11-themes/hicolor-icon-theme
	libcanberra? ( media-libs/libcanberra )
	libnotify? ( >=x11-libs/libnotify-0.4.1 )
"
RDEPEND="
	app-arch/bzip2
	>=dev-libs/boost-1.38:=
	>=dev-libs/openssl-0.9.8:=
	sys-apps/attr
	sys-libs/zlib
	virtual/libiconv
	virtual/libintl
	idn? ( net-dns/libidn )
	lua? ( >=dev-lang/lua-5.1:= )
	pcre? ( >=dev-libs/libpcre-4.2 )
	upnp? ( >=net-libs/miniupnpc-1.6 )
	cli? (
		>=dev-lang/perl-5.10
		virtual/perl-Getopt-Long
		dev-perl/Data-Dump
		dev-perl/Term-ShellUI
		json? ( dev-perl/JSON-RPC )
		xmlrpc? ( dev-perl/RPC-XML )
	)
	daemon? ( xmlrpc? ( >=dev-libs/xmlrpc-c-1.19.0[abyss,cxx] ) )
	gtk2? (
		${GTK_COMMON_DEPEND}
		>=x11-libs/gtk+-2.24:2
	)
	gtk3? (
		${GTK_COMMON_DEPEND}
		x11-libs/gtk+:3
	)
	qt4? (
		>=dev-qt/qtcore-4.7.0:4
		>=dev-qt/qtgui-4.7.0:4
		dbus? ( >=dev-qt/qtdbus-4.6.0:4 )
		javascript? (
			>=dev-qt/qtscript-4.6.0:4
			x11-libs/qtscriptgenerator
		)
		qml? ( >=dev-qt/qtdeclarative-4.7.0:4 )
		spell? ( app-text/aspell )
		sqlite? ( >=dev-qt/qtsql-4.6.0:4[sqlite] )
	)
	qt5? (
		>=dev-qt/qtwidgets-5.0.2:5
		>=dev-qt/qtxml-5.0.2:5
		>=dev-qt/qtnetwork-5.0.2:5
		>=dev-qt/qtmultimedia-5.0.2:5
		>=dev-qt/qtconcurrent-5.0.2:5
		dbus? ( >=dev-qt/qtdbus-5.0.2:5 )
		javascript? (
			dev-qt/qtscript:5
			x11-libs/qtscriptgenerator
		)
		qml? ( >=dev-qt/qtquickcontrols-5.3.2:5[widgets] )
		spell? ( app-text/aspell )
		sqlite? ( dev-qt/qtsql:5[sqlite] )
	)
"
DEPEND="${RDEPEND}
	sys-devel/gettext
	virtual/pkgconfig
"
DOCS=( AUTHORS ChangeLog.txt )

eiskaltdcpp_gcc_specific_pretests() {
	( [[ "${MERGE_TYPE}" = "binary" ]] || ! tc-is-gcc ) && return 0

	local gcc_major_version=$(gcc-major-version) gcc_minor_version=$(gcc-minor-version)
	if (( gcc_major_version < 4 || ( gcc_major_version == 4 && gcc_minor_version < 6) )); then
		eerror ">=sys-devel/gcc-4.6.0 is required to build ${CATEGORY}/${PN}."
		return 1
	fi
}

eiskaltdcpp_clang_specific_pretests() {
	( [[ "${MERGE_TYPE}" = "binary" ]] || ! tc-is-clang ) && return 0

	local clang_major_version=$(clang-major-version) clang_minor_version=$(clang-minor-version)
	if (( clang_major_version < 3 || ( clang_major_version == 3 && clang_minor_version < 2 ) )); then
		eerror ">=sys-devel/clang-3.2.0 is required to build ${CATEGORY}/${PN}."
		return 1
	fi
}

pkg_pretend() {
	eiskaltdcpp_gcc_specific_pretests || die "eiskaltdcpp_gcc_specific_pretests() failed"
	eiskaltdcpp_clang_specific_pretests || die "eiskaltdcpp_clang_specific_pretests() failed"
}

src_prepare() {
	l10n_find_plocales_changes 'eiskaltdcpp-qt/translations' '' '.ts'
	use qt5 && local PATCHES=( "${FILESDIR}/${PN}"-fix_qt5_qml_qtquickcontrols1_dependency.patch )
	default
}

src_configure() {
	local mycmakeargs=(
		-DLIB_INSTALL_DIR="$(get_libdir)"
		-Dlinguas="$(l10n_get_locales)"
		-DLOCAL_MINIUPNP=OFF
		-DUSE_LIBGNOME2=OFF
		-DUSE_CLI_JSONRPC=$(usex json)
		-DUSE_CLI_XMLRPC=$(usex xmlrpc)
		-DNO_UI_DAEMON=$(usex daemon)
		-DJSONRPC_DAEMON=$(use daemon && usex json)
		-DUSE_CLI_XMLRPC=$(use daemon && usex xmlrpc)
		-DDBUS_NOTIFY=$(usex dbus)
		-DWITH_DHT=$(usex dht)
		-DWITH_EMOTICONS=$(usex emoticons)
		-DWITH_EXAMPLES=$(usex examples)
		-DUSE_GTK=$(usex gtk2)
		-DUSE_GTK3=$(usex gtk3)
		-DUSE_IDNA=$(usex idn)
		-DUSE_JS=$(usex javascript)
		-DUSE_LIBCANBERRA=$(usex libcanberra)
		-DUSE_LIBNOTIFY=$(usex libnotify)
		-DLUA_SCRIPT=$(usex lua)
		-DWITH_LUASCRIPTS=$(use examples && usex lua)
		-DWITH_DEV_FILES=$(usex !minimal)
		-DPERL_REGEX=$(usex pcre)
		-DUSE_QT=$(usex qt4)
		-DUSE_QT5=$(usex qt5)
		-DUSE_QT_QML=$(usex qml)
		-DWITH_SOUNDS=$(usex sound)
		-DUSE_ASPELL=$(usex spell)
		-DUSE_QT_SQLITE=$(usex sqlite)
		-DUSE_MINIUPNP=$(usex upnp)
	)
	cmake-utils_src_configure
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	xdg-utils_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	xdg-utils_desktop_database_update
	gnome2_icon_cache_update
}
