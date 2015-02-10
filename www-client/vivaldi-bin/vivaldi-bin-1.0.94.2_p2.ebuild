# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-client/vivaldi/vivaldi-1.0.94.2_p2.ebuild,v 1.1 2015/02/04 15:15:36 jer Exp $

EAPI=5
CHROMIUM_LANGS="
	 am ar bg bn ca cs da de el en_GB en_US es_419 es et fa fil fi fr gu he hi
	 hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt_BR pt_PT ro ru sk sl sr sv
	 sw ta te th tr uk vi zh_CN zh_TW
"
inherit chromium multilib unpacker toolchain-funcs

MY_PN="${PN%-bin}"
MY_PF="${MY_PN}-${PVR}"
DESCRIPTION="A new browser for our friends"
HOMEPAGE="http://vivaldi.com/"
SRC_URI="
	amd64? ( ${HOMEPAGE}download/${MY_PN^}_TP${PV/*_p}_${PV/_p*}_amd64.deb )
"

LICENSE="Vivaldi"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="bindist mirror"

S=${WORKDIR}

RDEPEND="
	${DEPEND}
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	>=dev-libs/openssl-1.0.1:0
	gnome-base/gconf:2
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	net-misc/curl
	net-print/cups
	sys-apps/dbus
	sys-libs/libcap
	virtual/libudev
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/gtk+:2
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/pango[X]
	!www-client/vivaldi
"
DEPEND=""

QA_PREBUILT="*"
S=${WORKDIR}
VIVALDI_HOME="opt/${MY_PN}"

src_unpack() {
	unpack_deb ${A}
}

src_prepare() {
	# install icons
	sizes="16 22 24 32 48 64 128 256"
	icon_path="usr/share/icons/hicolor"
	for size in ${sizes}; do
		mkdir -p "${icon_path}/${size}x${size}/apps"
	    mv "opt/vivaldi/product_logo_${size}.png" "${icon_path}/${size}x${size}/apps/vivaldi.png"
	done

	sed -i \
		-e 's|vivaldi-stable|vivaldi|g' \
		usr/share/applications/${MY_PN}.desktop \
		usr/share/xfce4/helpers/${MY_PN}.desktop || die

	mv usr/share/doc/${MY_PN}-stable usr/share/doc/${MY_PF} || die
	rm usr/bin/${MY_PN}-stable || die
	rm _gpgbuilder || die

	pushd "${VIVALDI_HOME}/locales" > /dev/null || die
	chromium_remove_language_paks
	popd > /dev/null || die
}

src_install() {
	mv * "${D}" || die
	dosym /${VIVALDI_HOME}/${MY_PN} /usr/bin/${MY_PN}

	dodir /${VIVALDI_HOME}/lib
	dosym /usr/$(get_libdir)/libudev.so /${VIVALDI_HOME}/lib/libudev.so.0

	fperms 4711 /${VIVALDI_HOME}/${MY_PN}-sandbox
}
