# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools eutils fdo-mime flag-o-matic gnome2-utils l10n multilib multilib-minimal pax-utils toolchain-funcs virtualx versionator

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="git://source.winehq.org/git/wine.git http://source.winehq.org/git/wine.git"
	inherit git-r3
	MY_PV="${PV}"
	STAGING_PV="${MY_PV}"
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
	[[ "${MY_PV}" =~ ^1\.8\.[[:digit:]]+$ ]] && STAGING_SUFFIX="-unofficial"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://dl.winehq.org/wine/source/${MAJOR_V}/${MY_P}.tar.bz2 -> ${P}.tar.bz2"
fi

GV="2.44"
MV="4.6.0"
STAGING_P="wine-staging-${MY_PV}"
STAGING_DIR="${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}"
STAGING_HELPER="wine-staging-git-helper-0.1.2"
GV_BETA_PATCH="0001-mshtml-Wine-Gecko-2.47-beta1-release.patch"
WINE_GENTOO="wine-gentoo-2015.03.07"
DESCRIPTION="Free implementation of Windows(tm) on Unix"
HOMEPAGE="http://www.winehq.org/"
SRC_URI="${SRC_URI}
	gecko? (
		abi_x86_32? ( https://dl.winehq.org/wine/wine-gecko/${GV}/wine_gecko-${GV}-x86.msi )
		abi_x86_64? ( https://dl.winehq.org/wine/wine-gecko/${GV}/wine_gecko-${GV}-x86_64.msi )
	)
	mono? ( https://dl.winehq.org/wine/wine-mono/${MV}/wine-mono-${MV}.msi )
	https://dev.gentoo.org/~tetromino/distfiles/${PN}/${WINE_GENTOO}.tar.bz2"

if [[ ${PV} == "9999" ]] ; then
	STAGING_EGIT_REPO_URI="git://github.com/wine-compholio/wine-staging.git"
	SRC_URI="${SRC_URI}
	staging? ( https://github.com/bobwya/${STAGING_HELPER%-*}/archive/${STAGING_HELPER##*-}.tar.gz -> ${STAGING_HELPER}.tar.gz )"
else
	SRC_URI="${SRC_URI}
	staging? ( https://github.com/wine-compholio/wine-staging/archive/v${MY_PV}${STAGING_SUFFIX}.tar.gz -> ${STAGING_P}.tar.gz )"
fi

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cups custom-cflags dos elibc_glibc +fontconfig +gecko gphoto2 gsm gstreamer +jpeg +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap pipelight +png prelink pulseaudio +realtime +run-exes s3tc samba scanner selinux +ssl staging test +threads +truetype +udisks v4l vaapi +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	test? ( abi_x86_32 )
	elibc_glibc? ( threads )
	pipelight? ( staging )
	s3tc? ( staging )
	vaapi? ( staging )
	osmesa? ( opengl )" #286560

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	truetype? ( >=media-libs/freetype-2.0.0[${MULTILIB_USEDEP}] )
	capi? ( net-libs/libcapi[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.2:0=[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-plugins/gst-plugins-meta:1.0[${MULTILIB_USEDEP}]
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
	staging? ( sys-apps/attr[${MULTILIB_USEDEP}] )
	xml? (
		dev-libs/libxml2[${MULTILIB_USEDEP}]
		dev-libs/libxslt[${MULTILIB_USEDEP}]
	)
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	vaapi? ( x11-libs/libva[X,${MULTILIB_USEDEP}] )
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
	s3tc? ( >=media-libs/libtxc_dxtn-1.0.1-r1[${MULTILIB_USEDEP}] )
	samba? ( >=net-fs/samba-3.0.25[winbind] )
	selinux? ( sec-policy/selinux-wine )
	udisks? ( sys-fs/udisks:2 )
	pulseaudio? ( realtime? ( sys-auth/rtkit ) )"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	staging? ( dev-lang/perl dev-perl/XML-Simple )
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
	[[ "${MERGE_TYPE}" == "binary" ]] && return 0

	# bug #549768
	if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -le 2 ]]; then
		einfo "Checking for gcc-5.1/gcc-5.2 MS X86_64 ABI compiler bug ..."
		$(tc-getCC) -O2 "${FILESDIR}/pr66838.c" -o "${T}/pr66838" || die "cc compilation failed: pr66838 test"
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

	# bug #574044
	if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -eq 3 ]]; then
		einfo "Checking for gcc-5.3.0 X86_64 misaligned stack compiler bug ..."
		# Compile in subshell to prevent "Aborted" message
		if ! ( $(tc-getCC) -O2 -mincoming-stack-boundary=3 "${FILESDIR}"/pr69140.c -o "${T}"/pr69140 || false )&>/dev/null; then
			eerror "gcc-5.3.0 X86_64 misaligned stack compiler bug detected."
			eerror "Please re-emerge the latest gcc-5.3.0 ebuild, or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/574044"
			eerror
			return 1
		fi
	fi
}

pkg_pretend() {
	wine_build_environment_prechecks || die
	wine_build_environment_pretests || die
}

pkg_setup() {
	wine_build_environment_prechecks || die
	wine_build_environment_pretests || die
}

src_unpack() {
	# Fully Mirror both git trees, Wine & Wine-Staging, so we can access commits in all branches
	[[ ${PV} == "9999" ]] && EGIT_MIN_CLONE_TYPE="mirror"
	if [[ ${PV} == "9999" ]] && ! use staging; then
		EGIT_CHECKOUT_DIR="${S}" git-r3_src_unpack
	elif [[ ${PV} == "9999" ]] && use staging; then
		unpack "${STAGING_HELPER}.tar.gz"
		if [[ ! -z "${EGIT_STAGING_COMMIT}" || ! -z "${EGIT_STAGING_BRANCH}" ]]; then
			# References are relative to Wine-Staging git tree (pre-checkout Wine-Staging git tree)
			# Use env variables "EGIT_STAGING_COMMIT" or "EGIT_STAGING_BRANCH" to reference Wine-Staging git tree
			ebegin "(subshell): you have specified a Wine-Staging git reference (building Wine git with USE +staging) ..."
			(
				source "${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh" || die
				[[ ! -z "${EGIT_STAGING_COMMIT}" ]] && WINE_STAGING_REF="commit EGIT_STAGING_COMMIT"
				[[   -z "${EGIT_STAGING_COMMIT}" ]] && WINE_STAGING_REF="branch EGIT_STAGING_BRANCH"
				ewarn "Building Wine against Wine-Staging git ${WINE_STAGING_REF}=\"${EGIT_STAGING_COMMIT:-${EGIT_STAGING_BRANCH}}\" ."
				EGIT_BRANCH="${EGIT_STAGING_BRANCH:-master}"
				EGIT_COMMIT="${EGIT_STAGING_COMMIT:-}"
				unset ${PN}_LIVE_{REPO,BRANCH,COMMIT};
				EGIT_REPO_URI="${STAGING_EGIT_REPO_URI}" EGIT_CHECKOUT_DIR="${STAGING_DIR}" git-r3_src_unpack
				WINE_STAGING_COMMIT="${EGIT_VERSION}"
				get_upstream_wine_commit  "${STAGING_DIR}" "${WINE_STAGING_COMMIT}" "WINE_COMMIT"
				EGIT_COMMIT="${WINE_COMMIT}"
				EGIT_CHECKOUT_DIR="${S}" git-r3_src_unpack
				einfo "Building Wine commit \"${WINE_COMMIT}\" referenced by Wine-Staging commit \"${WINE_STAGING_COMMIT}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine commit."
		else
			# References are relative to Wine git tree (post-checkout Wine-Staging git tree)
			ebegin "(subshell): You are using a Wine git reference (building Wine git with USE +staging) ..."
			(
				source "${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh" || die
				EGIT_CHECKOUT_DIR="${S}" git-r3_src_unpack
				WINE_COMMIT="${EGIT_VERSION}"
				unset ${PN}_LIVE_{REPO,BRANCH,COMMIT} EGIT_COMMIT;
				EGIT_REPO_URI="${STAGING_EGIT_REPO_URI}" EGIT_CHECKOUT_DIR="${STAGING_DIR}" git-r3_src_unpack
				if ! walk_wine_staging_git_tree "${STAGING_DIR}" "${S}" "${WINE_COMMIT}" "WINE_STAGING_COMMIT" ; then
					find_closest_wine_commit "${STAGING_DIR}" "${S}" "WINE_COMMIT" "WINE_STAGING_COMMIT" "WINE_COMMIT_OFFSET"
					(($? == 0)) && display_closest_wine_commit_message "${WINE_COMMIT}" "${WINE_STAGING_COMMIT}" "${WINE_COMMIT_OFFSET}"
					die "Failed to find Wine-Staging git commit corresponding to supplied Wine git commit \"${WINE_COMMIT}\" ."
				fi
				einfo "Building Wine-Staging commit \"${WINE_STAGING_COMMIT}\" corresponding to Wine commit \"${WINE_COMMIT}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine-Staging commit."
		fi
	else
		unpack ${P}.tar.bz2
		use staging && unpack "${STAGING_P}.tar.gz"
	fi

	unpack "${WINE_GENTOO}.tar.bz2"

	l10n_find_plocales_changes "${S}/po" "" ".po"
}

src_prepare() {
	local md5="$(md5sum server/protocol.def)"
	local PATCHES=(
		"${FILESDIR}"/${PN}-1.5.26-winegcc.patch #260726
		"${FILESDIR}"/${PN}-1.7.12-osmesa-check.patch #429386
		"${FILESDIR}"/${PN}-1.6-memset-O3.patch #480508
		"${FILESDIR}"/${PN}-sysmacros.patch #580046
	)
	if [[ ${PV} != "9999" ]]; then
		PATCHES+=( "${FILESDIR}"/${PN}-1.9.5-multilib-portage.patch ) #395615
	else
		#395615 - run bash/sed script, combining both versions of the multilib-portage.patch
		ebegin "(subshell) script: \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" ..."
		(
			source "${FILESDIR}/${PN}-9999-multilib-portage-sed.sh" || die
		)
		eend $? || die "(subshell) script: \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\"."
	fi
	if use staging; then
		ewarn "Applying the Wine-Staging patchset. Any bug reports to the"
		ewarn "Wine bugzilla should explicitly state that staging was used."

		local STAGING_EXCLUDE=""
		if grep -q "${GV_BETA_PATCH}" "${STAGING_DIR}/patches/patchinstall.sh"; then
			local GV_BETA=$( "${FILESDIR}/beta_patch_conv.sh" "${GV_BETA_PATCH}" )
			STAGING_EXCLUDE="${STAGING_EXCLUDE} -W ${GV_BETA}"
		fi
		use pipelight || STAGING_EXCLUDE="${STAGING_EXCLUDE} -W Pipelight"
		#577198 only affects 1.9.5-r1
		use nls || STAGING_EXCLUDE="${STAGING_EXCLUDE} -W makefiles-Disabled_Rules"

		# Launch wine-staging patcher in a subshell, using epatch as a backend, and gitapply.sh as a backend for binary patches
		ebegin "Running Wine-Staging patch installer"
		(
			set -- DESTDIR="${S}" --backend=epatch --no-autoconf --all ${STAGING_EXCLUDE}
			cd "${STAGING_DIR}/patches"
			source "${STAGING_DIR}/patches/patchinstall.sh"
		)
		eend $? || die "(subshell) script: failed to apply Wine-Staging patches."

		if [[ ! -z "${STAGING_SUFFIX}" ]]; then
			sed -i -e 's/(Staging)/(Staging'"${STAGING_SUFFIX}"')/' libs/wine/Makefile.in || die "sed"
		fi
	fi

	default
	eautoreconf

	# Modification of the server protocol requires regenerating the server requests
	if [[ "$(md5sum server/protocol.def)" != "${md5}" ]]; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die
	if ! use run-exes; then
		sed -i '/^MimeType/d' loader/wine.desktop || die #117785
	fi

	# hi-res default icon, #472990, http://bugs.winehq.org/show_bug.cgi?id=24652
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
		$(use_with gstreamer)
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

	use staging && myconf+=(
		--with-xattr
		$(use_with vaapi va)
	)

	local PKG_CONFIG AR RANLIB
	# Avoid crossdev's i686-pc-linux-gnu-pkg-config if building wine32 on amd64; #472038
	# set AR and RANLIB to make QA scripts happy; #483342
	tc-export PKG_CONFIG AR RANLIB

	if use amd64; then
		if [[ ${ABI} == amd64 ]]; then
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
		ewarn "you will likely need to install an external one, via winetricks."
	fi
	if ! use mono; then
		ewarn "Without Wine Mono, wine prefixes will not have a default"
		ewarn "implementation of .NET.  Many windows applications rely upon"
		ewarn "the existence of a .NET implementation, so you will likely need"
		ewarn "to install an external one, via winetricks."
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}
