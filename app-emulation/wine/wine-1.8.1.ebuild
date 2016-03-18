# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

AUTOTOOLS_AUTORECONF=1
PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools-utils eutils fdo-mime flag-o-matic gnome2-utils l10n multilib multilib-minimal pax-utils toolchain-funcs virtualx versionator

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://source.winehq.org/git/wine.git http://source.winehq.org/git/wine.git"
	inherit git-r3
	MY_PV="${PV}"
	MY_P="${P}"
	SRC_URI=""
	#KEYWORDS=""
else
	MAJOR_V=$(get_version_component_range 1-2)
	MINOR_V=$(get_version_component_range 2)
	STABLE_RELEASE=$((1-MINOR_V%2))
	MY_PV="${PV}"
	if [[ "$(get_version_component_range 3)" =~ ^rc ]]; then
		MY_PV=$(replace_version_separator 2 '''-''')
	elif [[ ${STABLE_RELEASE} == 1 ]]; then
		KEYWORDS="-* amd64 x86 x86-fbsd"
	else
		KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
	fi
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://dl.winehq.org/wine/source/${MAJOR_V}/${MY_P}.tar.bz2 -> ${P}.tar.bz2"
fi

GV="2.40"
MV="4.5.6"
WINE_GENTOO="wine-gentoo-2015.03.07"
GST_P="wine-1.7.55-gstreamer-v5"
DESCRIPTION="Free implementation of Windows(tm) on Unix"
HOMEPAGE="http://www.winehq.org/"
SRC_URI="${SRC_URI}
	gecko? (
		abi_x86_32? ( https://dl.winehq.org/wine/wine-gecko/${GV}/wine_gecko-${GV}-x86.msi )
		abi_x86_64? ( https://dl.winehq.org/wine/wine-gecko/${GV}/wine_gecko-${GV}-x86_64.msi )
	)
	mono? ( https://dl.winehq.org/wine/wine-mono/${MV}/wine-mono-${MV}.msi )
	gstreamer010? ( https://dev.gentoo.org/~np-hardass/distfiles/${PN}/${GST_P}.patch.bz2 )
	https://dev.gentoo.org/~tetromino/distfiles/${PN}/${WINE_GENTOO}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cups custom-cflags dos elibc_glibc +fontconfig +gecko gphoto2 gsm gstreamer010 +jpeg +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap +png prelink pulseaudio +realtime +run-exes samba scanner selinux +ssl test +threads +truetype +udisks v4l +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	test? ( abi_x86_32 )
	elibc_glibc? ( threads )
	mono? ( abi_x86_32 )
	osmesa? ( opengl )" #286560

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	truetype? ( >=media-libs/freetype-2.0.0[${MULTILIB_USEDEP}] )
	capi? ( net-dialup/capi4k-utils )
	ncurses? ( >=sys-libs/ncurses-5.2:0=[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	gstreamer010? (
		media-libs/gstreamer:0.10[${MULTILIB_USEDEP}]
		media-libs/gst-plugins-base:0.10[${MULTILIB_USEDEP}]
	)
	X? (
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	)
	xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	cups? ( net-print/cups:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/glu[${MULTILIB_USEDEP}]
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	gsm? ( media-sound/gsm:=[${MULTILIB_USEDEP}] )
	jpeg? ( virtual/jpeg:0=[${MULTILIB_USEDEP}] )
	ldap? ( net-nds/openldap:=[${MULTILIB_USEDEP}] )
	lcms? ( media-libs/lcms:2=[${MULTILIB_USEDEP}] )
	mp3? ( >=media-sound/mpg123-1.5.0[${MULTILIB_USEDEP}] )
	netapi? ( net-fs/samba[netapi(+),${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	odbc? ( dev-db/unixODBC:=[${MULTILIB_USEDEP}] )
	osmesa? ( media-libs/mesa[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	xml? (
		dev-libs/libxml2[${MULTILIB_USEDEP}]
		dev-libs/libxslt[${MULTILIB_USEDEP}]
	)
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	xcomposite? ( x11-libs/libXcomposite[${MULTILIB_USEDEP}] )
	abi_x86_32? (
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-baselibs-20140508-r14
		!app-emulation/emul-linux-x86-db[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-db-20140508-r3
		!app-emulation/emul-linux-x86-medialibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-medialibs-20140508-r6
		!app-emulation/emul-linux-x86-opengl[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-opengl-20140508-r1
		!app-emulation/emul-linux-x86-sdl[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-sdl-20140508-r1
		!app-emulation/emul-linux-x86-soundlibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-soundlibs-20140508
		!app-emulation/emul-linux-x86-xlibs[-abi_x86_32(-)]
		!<app-emulation/emul-linux-x86-xlibs-20140508
	)"

RDEPEND="${COMMON_DEPEND}
	dos? ( games-emulation/dosbox )
	perl? ( dev-lang/perl dev-perl/XML-Simple )
	samba? ( >=net-fs/samba-3.0.25 )
	selinux? ( sec-policy/selinux-wine )
	udisks? ( sys-fs/udisks:2 )
	pulseaudio? ( realtime? ( sys-auth/rtkit ) )"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	X? (
		x11-proto/inputproto
		x11-proto/xextproto
		x11-proto/xf86vidmodeproto
	)
	xinerama? ( x11-proto/xineramaproto )
	prelink? ( sys-devel/prelink )
	>=sys-kernel/linux-headers-2.6
	virtual/pkgconfig
	virtual/yacc
	sys-devel/flex"

# These use a non-standard "Wine" category, which is provided by
# /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="usr/share/applications/wine-browsedrive.desktop
usr/share/applications/wine-notepad.desktop
usr/share/applications/wine-uninstaller.desktop
usr/share/applications/wine-winecfg.desktop"

S="${WORKDIR}/${MY_P}"

wine_build_environment_prechecks() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	if use abi_x86_64 && [[ $(( $(gcc-major-version) * 100 + $(gcc-minor-version) )) -lt 404 ]]; then
		eerror "You need gcc-4.4+ to build 64-bit wine"
		eerror
		return 1
	fi

	if use abi_x86_32 && use opencl && [[ x$(eselect opencl show 2> /dev/null) = "xintel" ]]; then
		eerror "You cannot build wine with USE=opencl because intel-ocl-sdk is 64-bit only."
		eerror "See https://bugs.gentoo.org/487864 for more details."
		eerror
		return 1
	fi
}

wine_build_environment_pretests() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	# bug #549768
	if use abi_x86_64 && [[ $(gcc-major-version) = 5 && $(gcc-minor-version) -le 2 ]]; then
		einfo "Checking for gcc-5.1/5.2 MS X86_64 ABI compiler bug ..."
		$(tc-getCC) -O2 "${FILESDIR}/pr66838.c" -o "${T}/pr66838" || die "compilation failed: pr66838 test"
		# Run in subshell to prevent "Aborted" message
		if ! ( "${T}/pr66838" || false )&>/dev/null; then
			eerror "gcc-5.1/5.2 MS X86_64 ABI compiler bug detected."
			eerror "64-bit wine cannot be built with affected versions of gcc."
			eerror "Please re-emerge wine using an unaffected version of gcc or apply"
			eerror "Upstream (backport) patch to your current version of gcc-5.1/5.2."
			eerror "See https://bugs.gentoo.org/549768"
			eerror
			return 1
		fi
	fi
}

wine_build_environment_setup_tests() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	# bug #574044
	if use abi_x86_64 && [[ $(gcc-major-version) = 5 && $(gcc-minor-version) = 3 ]]; then
		einfo "Checking for gcc-5.3.0 X86_64 misaligned stack compiler bug ..."
		# Compile in subshell to prevent "Aborted" message
		if ! ( $(tc-getCC) -O2 -mincoming-stack-boundary=3 "${FILESDIR}"/pr69140.c -o "${T}"/pr69140 || false )&>/dev/null; then
			eerror "gcc-5.3.0 X86_64 misaligned stack compiler bug detected."
			CFLAGS_X86_64="-fno-omit-frame-pointer"
			test-flags-CC "${CFLAGS_X86_64}" &>/dev/null || die "CFLAGS+='${CFLAGS_X86_64}' not supported by selected gcc compiler"
			ewarn "abi_x86_64.amd64 compilation phase (workaround automatically applied):"
			ewarn "  CFLAGS+='${CFLAGS_X86_64}'"
			ewarn "See https://bugs.gentoo.org/574044"
			ewarn
		fi
	fi
}

pkg_pretend() {
	wine_build_environment_prechecks || die
	wine_build_environment_pretests || die
}

pkg_setup() {
	wine_build_environment_setup_tests || die

	if [[ ${PV} == "9999" ]] && [[ -z "${EGIT_BRANCH}" ]] && [[ -z "${EGIT_COMMIT}" ]]; then
		einfo "By default the Wine git tree branch master will be used."
	fi
}

src_unpack() {
	if [[ ${PV} == "9999" ]] ; then
		EGIT_BRANCH=${EGIT_BRANCH:-master}
		EGIT_CHECKOUT_DIR="${S}" git-r3_src_unpack
	else
		unpack ${P}.tar.bz2
	fi

	unpack "${WINE_GENTOO}.tar.bz2"
	use gstreamer010 && unpack "${GST_P}.patch.bz2"

	l10n_find_plocales_changes "${S}/po" "" ".po"
}

src_prepare() {
	local md5="$(md5sum server/protocol.def)"
	local PATCHES=(
		"${FILESDIR}"/${PN}-1.5.26-winegcc.patch #260726
		"${FILESDIR}"/${PN}-1.7.12-osmesa-check.patch #429386
		"${FILESDIR}"/${PN}-1.6-memset-O3.patch #480508
	)
	if [[ ${PV} != "9999" ]]; then
		PATCHES+=( "${FILESDIR}"/${PN}-1.4_rc2-multilib-portage.patch ) #395615
	else
		# Do not patch wine live ebuild - allows building against older Wine / Wine-Staging commits
		# bug #395615
		ebegin "Running \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" ..."
		(
			source "${FILESDIR}/${PN}-9999-multilib-portage-sed.sh" ||
				die "Failed bash script: \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\""
		)
		eend $?
	fi
	if use gstreamer010; then
		ewarn "Applying experimental patch to fix GStreamer support. Note that"
		ewarn "this patch has been reported to cause crashes in certain games."

		PATCHES+=( "${WORKDIR}/${GST_P}.patch" )
	fi
	autotools-utils_src_prepare

	if [[ "$(md5sum server/protocol.def)" != "${md5}" ]]; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die
	if ! use run-exes; then
		sed -i '/^MimeType/d' loader/wine.desktop || die #117785
	fi

	cp "${WORKDIR}"/${WINE_GENTOO}/icons/oic_winlogo.ico dlls/user32/resources/ || die

	l10n_get_locales > po/LINGUAS # otherwise wine doesn't respect LINGUAS
}

src_configure() {
	export LDCONFIG=/bin/true
	use custom-cflags || strip-flags

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myconf=(
		--sysconfdir=/etc/wine
		$(use_with alsa)
		$(use_with capi)
		$(use_with lcms cms)
		$(use_with cups)
		$(use_with ncurses curses)
		$(use_with udisks dbus)
		$(use_with fontconfig)
		$(use_with ssl gnutls)
		$(use_enable gecko mshtml)
		$(use_with gphoto2 gphoto)
		$(use_with gsm)
		$(use_with gstreamer010 gstreamer)
		--without-hal
		$(use_with jpeg)
		$(use_with ldap)
		$(use_enable mono mscoree)
		$(use_with mp3 mpg123)
		$(use_with netapi)
		$(use_with nls gettext)
		$(use_with openal)
		$(use_with opencl)
		$(use_with opengl)
		$(use_with osmesa)
		$(use_with oss)
		$(use_with pcap)
		$(use_with png)
		$(use_with pulseaudio pulse)
		$(use_with threads pthread)
		$(use_with scanner sane)
		$(use_enable test tests)
		$(use_with truetype freetype)
		$(use_with v4l)
		$(use_with X x)
		$(use_with xcomposite)
		$(use_with xinerama)
		$(use_with xml)
		$(use_with xml xslt)
	)

	local PKG_CONFIG AR RANLIB
	# Avoid crossdev's i686-pc-linux-gnu-pkg-config if building wine32 on amd64; #472038
	# set AR and RANLIB to make QA scripts happy; #483342
	tc-export PKG_CONFIG AR RANLIB

	if use amd64; then
		if [[ ${ABI} == amd64 ]]; then
			# bug #574044
			if [[ -n "${CFLAGS_X86_64}" ]]; then
				append-cflags "${CFLAGS_X86_64}"
				einfo "CFLAGS='${CFLAGS}'"
				unset CFLAGS_X86_64
			fi
			myconf+=( --enable-win64 )
		else
			myconf+=( --disable-win64 )
		fi

		# Note: using --with-wine64 results in problems with multilib.eclass
		# CC/LD hackery. We're using separate tools instead.
	fi

	ECONF_SOURCE=${S} \
	econf "${myconf[@]}"
	emake depend
}

multilib_src_test() {
	# FIXME: win32-only; wine64 tests fail with "could not find the Wine loader"
	if [[ ${ABI} == x86 ]]; then
		if [[ $(id -u) == 0 ]]; then
			ewarn "Skipping tests since they cannot be run under the root user."
			ewarn "To run the test ${PN} suite, add userpriv to FEATURES in make.conf"
			return
		fi

		WINEPREFIX="${T}/.wine-${ABI}" \
		Xemake test
	fi
}

multilib_src_install_all() {
	local DOCS=( ANNOUNCE AUTHORS README )
	local l
	add_locale_docs() {
		local locale_doc="documentation/README.$1"
		[[ ! -e ${locale_doc} ]] || DOCS+=( ${locale_doc} )
	}
	l10n_for_each_locale_do add_locale_docs

	einstalldocs
	prune_libtool_files --all

	emake -C "../${WINE_GENTOO}" install DESTDIR="${D}" EPREFIX="${EPREFIX}"
	if use gecko ; then
		insinto /usr/share/wine/gecko
		use abi_x86_32 && doins "${DISTDIR}"/wine_gecko-${GV}-x86.msi
		use abi_x86_64 && doins "${DISTDIR}"/wine_gecko-${GV}-x86_64.msi
	fi
	if use mono ; then
		insinto /usr/share/wine/mono
		doins "${DISTDIR}"/wine-mono-${MV}.msi
	fi
	if ! use perl ; then # winedump calls function_grep.pl, and winemaker is a perl script
		rm "${D}"usr/bin/{wine{dump,maker},function_grep.pl} "${D}"usr/share/man/man1/wine{dump,maker}.1 || die
	fi

	use abi_x86_32 && pax-mark psmr "${D}"usr/bin/wine{,-preloader} #255055
	use abi_x86_64 && pax-mark psmr "${D}"usr/bin/wine64{,-preloader}

	if use abi_x86_64 && ! use abi_x86_32; then
		dosym /usr/bin/wine{64,} # 404331
		dosym /usr/bin/wine{64,}-preloader
	fi

	# respect LINGUAS when installing man pages, #469418
	for l in de fr pl; do
		use linguas_${l} || rm -r "${D}"usr/share/man/${l}*
	done
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update

	if ! use gecko; then
		ewarn "Without Wine Gecko, wine prefixes will not have a default"
		ewarn "implementation of iexplore.  Many older windows applications"
		ewarn "rely upon the existence of an iexplore implementation, so"
		ewarn "you will likely need to install an external one, like via winetricks"
	fi
	if ! use mono; then
		ewarn "Without Wine Mono, wine prefixes will not have a default"
		ewarn "implementation of .NET.  Many windows applications rely upon"
		ewarn "the existence of a .NET implementation, so you will likely need"
		ewarn "to install an external one, like via winetricks"
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}
