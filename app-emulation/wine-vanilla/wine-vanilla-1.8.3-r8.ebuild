# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools flag-o-matic gnome2-utils l10n multilib multilib-minimal pax-utils toolchain-funcs virtualx versionator xdg-utils

MY_PN="${PN%%-*}"
MY_PV="${PV}"
version_component_count=$(get_version_component_count)
# Hack, using Portage patch versioning, to implement multiple slots per single unique slotted version
# (of the multislot wine-vanilla package)
last_component="$( get_version_component_range $((version_component_count)) )"
if [[ "${last_component}" =~ ^p[[:digit:]]+$ ]]; then
	MY_PV="${MY_PV%_${last_component}}"
	: $(( --version_component_count ))
fi
MY_P="${MY_PN}-${MY_PV}"
if [[ "${MY_PV}" == "9999" ]]; then
	#KEYWORDS=""
	EGIT_REPO_URI="https://source.winehq.org/git/wine.git"
	inherit git-r3
	SRC_URI=""
else
	KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
	last_component="$( get_version_component_range $((version_component_count)) )"
	rc_version=0
	if [[ "${last_component}" =~ ^rc[[:digit:]]+$ ]]; then
		rc_version=1
		: $(( --version_component_count ))
		MY_PV=$(replace_version_separator $((version_component_count)) '''-''')
		MY_P="${MY_PN}-${MY_PV}"
	fi
	major_version=$(get_major_version)
	minor_version=$(get_version_component_range 2)
	stable_version=$(( (major_version == 1 && (minor_version % 2 == 0)) || (major_version >= 2 && minor_version == 0) ))
	base_version=$(( stable_version && (version_component_count == 2) ))
	if (( stable_version && rc_version && !base_version )); then
		# Pull Wine RC intermediate stable versions from alternate Github repository...
		STABLE_PREFIX="wine-stable"
		MY_P="${STABLE_PREFIX}-${MY_P}"
		SRC_URI="https://github.com/mstefani/wine-stable/archive/${MY_PN}-${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	elif (( (major_version < 2) || ((version_component_count == 2) && (major_version == 2) && (minor_version == 0)) )); then
		# The base Wine 2.0 release tarball was bzip2 compressed - switching to xz shortly after...
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.${minor_version}/${MY_P}.tar.bz2 -> ${MY_P}.tar.bz2"
	elif (( (major_version >= 2) && (minor_version == 0) )); then
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.0/${MY_P}.tar.xz -> ${MY_P}.tar.xz"
	else
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.x/${MY_P}.tar.xz -> ${MY_P}.tar.xz"
	fi
fi
unset -v base_version last_component minor_version major_version rc_version stable_version version_component_count

GENTOO_WINE_EBUILD_COMMON_P="gentoo-wine-ebuild-common-20171106"
GENTOO_WINE_EBUILD_COMMON_PN="${GENTOO_WINE_EBUILD_COMMON_P%-*}"
GENTOO_WINE_EBUILD_COMMON_PV="${GENTOO_WINE_EBUILD_COMMON_P##*-}"

WINE_STAGING_GIT_HELPER_P="wine-staging-git-helper-0.1.9"
WINE_STAGING_GIT_HELPER_PN="${WINE_STAGING_GIT_HELPER_P%-*}"
WINE_STAGING_GIT_HELPER_PV="${WINE_STAGING_GIT_HELPER_P##*-}"

DESCRIPTION="Free implementation of Windows(tm) on Unix, without any external patchsets"
HOMEPAGE="https://www.winehq.org/"
SRC_URI="${SRC_URI}
	https://github.com/bobwya/${GENTOO_WINE_EBUILD_COMMON_PN}/archive/${GENTOO_WINE_EBUILD_COMMON_PV}.tar.gz -> ${GENTOO_WINE_EBUILD_COMMON_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="${PV}"

IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cups custom-cflags dos elibc_glibc +fontconfig +gecko gphoto2 gsm gstreamer +jpeg kernel_FreeBSD +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap +png prelink pulseaudio +realtime +run-exes samba scanner selinux +ssl test +threads +truetype +udisks v4l +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	X? ( truetype )
	elibc_glibc? ( threads )
	mono? ( abi_x86_32 )
	osmesa? ( opengl )
	test? ( abi_x86_32 )" #286560 osmesa-opengl  #551124 X-truetype

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	>=app-emulation/wine-desktop-common-20170822
	X? (
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	!x86-fbsd? (
		capi? ( net-libs/libcapi[${MULTILIB_USEDEP}] )
	)
	cups? ( net-print/cups:=[${MULTILIB_USEDEP}] )
	fontconfig? ( media-libs/fontconfig:=[${MULTILIB_USEDEP}] )
	gphoto2? ( media-libs/libgphoto2:=[${MULTILIB_USEDEP}] )
	gsm? ( media-sound/gsm:=[${MULTILIB_USEDEP}] )
	gstreamer? (
		media-libs/gstreamer:1.0[${MULTILIB_USEDEP}]
		media-plugins/gst-plugins-meta:1.0[${MULTILIB_USEDEP}]
	)
	jpeg? ( virtual/jpeg:0=[${MULTILIB_USEDEP}] )
	lcms? ( media-libs/lcms:2=[${MULTILIB_USEDEP}] )
	ldap? ( net-nds/openldap:=[${MULTILIB_USEDEP}] )
	mp3? ( >=media-sound/mpg123-1.5.0[${MULTILIB_USEDEP}] )
	ncurses? ( >=sys-libs/ncurses-5.2:0=[${MULTILIB_USEDEP}] )
	!x86-fbsd? (
		netapi? ( net-fs/samba[netapi(+),${MULTILIB_USEDEP}] )
	)
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	odbc? ( dev-db/unixODBC:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/glu[${MULTILIB_USEDEP}]
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	osmesa? ( >=media-libs/mesa-13[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	truetype? ( >=media-libs/freetype-2.0.5[${MULTILIB_USEDEP}] )
	!x86-fbsd? (
		udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	)
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	xcomposite? ( x11-libs/libXcomposite[${MULTILIB_USEDEP}] )
	xinerama? ( x11-libs/libXinerama[${MULTILIB_USEDEP}] )
	xml? (
		dev-libs/libxml2[${MULTILIB_USEDEP}]
		dev-libs/libxslt[${MULTILIB_USEDEP}]
	)
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
	!app-emulation/wine:0
	!x86-fbsd? (
		dos? ( >=games-emulation/dosbox-0.74_p20160629 )
		samba? ( >=net-fs/samba-3.0.25[winbind] )
		udisks? ( sys-fs/udisks:2 )
	)
	>=app-eselect/eselect-wine-1.5.3
	gecko? ( app-emulation/wine-gecko:2.40[abi_x86_32?,abi_x86_64?] )
	mono? ( app-emulation/wine-mono:4.5.6 )
	perl? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	pulseaudio? (
		realtime? ( sys-auth/rtkit )
	)
	selinux? ( sec-policy/selinux-wine )
"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	!x86-fbsd? (
		>=sys-kernel/linux-headers-2.6
		prelink? ( sys-devel/prelink )
	)
	dev-util/patchbin
	dev-lang/perl
	dev-perl/XML-Simple
	>=sys-devel/flex-2.5.33
	virtual/pkgconfig
	virtual/yacc
	X? (
		x11-proto/inputproto
		x11-proto/xextproto
		x11-proto/xf86vidmodeproto
	)
	xinerama? ( x11-proto/xineramaproto )"

S="${WORKDIR}/${MY_P}"

wine_env_vcs_variable_prechecks() {
	local pn_live_variable="${MY_PN//[-+]/_}_LIVE_COMMIT"
	local pn_live_value="${!pn_live_variable}"
	local env_error=0

	[[ ! -z ${EGIT_COMMIT} || ! -z ${EGIT_BRANCH} ]] \
		&& env_error=1
	if (( env_error )); then
		eerror "Git commit (and branch) overrides must now be specified"
		eerror "using ONE of following the environmental variables:"
		eerror "  EGIT_WINE_COMMIT or EGIT_WINE_BRANCH (Wine)"
		eerror
		return 1
	fi
}

wine_build_environment_prechecks() {
	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	local using_gcc using_clang gcc_major_version gcc_minor_version clang_major_version clang_minor_version
	using_gcc=$(tc-is-gcc)
	using_clang=$(tc-is-clang)
	gcc_major_version=$(gcc-major-version)
	gcc_minor_version=$(gcc-minor-version)
	clang_major_version=$(clang-major-version)
	clang_minor_version=$(clang-minor-version)

	if use abi_x86_64; then
		if (( using_gcc && ( gcc_major_version < 4 || (gcc_major_version == 4 && gcc_minor_version < 4) ) )); then
			eerror "You need >=sys-devel/gcc-4.4.x to compile 64-bit Wine"
			die "wine_build_environment_prechecks() failed"
		elif (( using_clang && ( clang_major_version < 3 || (clang_major_version == 3 && clang_minor_version < 8) ) )); then
			eerror "You need >=sys-devel/clang-3.8 to compile 64-bit wine"
			die "wine_build_environment_prechecks() failed"
		fi
		if (( using_gcc && (gcc_major_version == 5 && gcc_minor_version <= 3) )); then
			ewarn "=sys-devel/gcc-5.0.x ... =sys-devel/gcc-5.3.x - introduced compilation bugs"
			ewarn "and are no longer supported byGentoo's Toolchain Team."
			ewarn "If your ebuild fails the compiler checks in the src-configure phase then:"
			ewarn "update your compiler, switch to <sys-devel-gcc-5.0.x or >=sys-devel/gcc-5.4.x"
			ewarn "See https://bugs.gentoo.org/610752"
		fi
		if use abi_x86_32 && use opencl && [[ "$(eselect opencl show 2>/dev/null)" == "intel" ]]; then
			eerror "You cannot build wine with USE=+opencl because dev-util/intel-ocl-sdk is 64-bit only."
			eerror "See https://bugs.gentoo.org/487864"
			eerror
			return 1
		fi
	fi
}

wine_gcc_specific_pretests() {
	( [[ "${MERGE_TYPE}" = "binary" ]] || ! tc-is-gcc ) && return 0

	local using_abi_x86_64 gcc_major_version gcc_minor_version
	using_abi_x86_64=$(use abi_x86_64)
	gcc_major_version=$(gcc-major-version)
	gcc_minor_version=$(gcc-minor-version)

	#549768 sys-devel/gcc-5 miscompiles ms_abi functions (breaks app-emulation/wine)
	if (( using_abi_x86_64 && (gcc_major_version == 5 && gcc_minor_version <= 2) )); then
		ebegin "(subshell): checking for =sys-devel/gcc-5.1.x , =sys-devel/gcc-5.2.0 MS X86_64 ABI compiler bug ..."
		$(tc-getCC) -O2 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/pr66838.c" -o "${T}/pr66838" \
			|| die "cc compilation failed: pr66838 test"
		# Run in a subshell to prevent "Aborted" message
		( "${T}"/pr66838 || false ) >/dev/null 2>&1
		if ! eend $?; then
			eerror "(subshell): =sys-devel/gcc-5.1.x , =sys-devel/gcc-5.2.0 MS X86_64 ABI compiler bug detected."
			eerror "64-bit wine cannot be built with =sys-devel/gcc-5.1 or initial patchset of =sys-devel/gcc-5.2.0."
			eerror "Please re-emerge wine using an unaffected version of gcc or apply"
			eerror "Re-emerge the latest =sys-devel/gcc-5.2.0 ebuild,"
			eerror "or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/549768"
			eerror
			return 1
		fi
	fi

	#574044 sys-devel/gcc-5.3.0 miscompiles app-emulation/wine
	if (( using_abi_x86_64 && (gcc_major_version == 5) && (gcc_minor_version == 3) )); then
		ebegin "(subshell): checking for =sys-devel/gcc-5.3.0 X86_64 misaligned stack compiler bug ..."
		# Compile in a subshell to prevent "Aborted" message
		( $(tc-getCC) -O2 -mincoming-stack-boundary=3 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/pr69140.c" -o "${T}/pr69140" ) >/dev/null 2>&1
		if ! eend $?; then
			eerror "(subshell): =sys-devel/gcc-5.3.0 X86_64 misaligned stack compiler bug detected."
			eerror "Please re-emerge the latest =sys-devel/gcc-5.3.0 ebuild,"
			eerror "or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/574044"
			eerror
			return 1
		fi
	fi
}

wine_generic_compiler_pretests() {
	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	if use abi_x86_64; then
		ebegin "(subshell): checking compiler support for (64-bit) builtin_ms_va_list ..."
		# Compile in a subshell to prevent "Aborted" message
		( $(tc-getCC) -O2 "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/files/builtin_ms_va_list.c" -o "${T}/builtin_ms_va_list" >/dev/null 2>&1 )
		if ! eend $?; then
			eerror "(subshell): $(tc-getCC) does not support builtin_ms_va_list."
			eerror "Please re-emerge using a compiler (version) that supports building 64-bit Wine."
			eerror "Use >=sys-devel/gcc-4.4 or >=sys-devel/clang-3.8 to build ${CATEGORY}/${PN}."
			eerror
			return 1
		fi
	fi
}

pkg_pretend() {
	if use oss && ! use kernel_FreeBSD && ! has_version '>=media-sound/oss-4'; then
		eerror "You cannot build ${CATEGORY}/${PN} with USE=+oss without having support from a FreeBSD kernel"
		eerror "or >=media-sound/oss-4 (only available through an Overlay)."
		die "USE=+oss currently unsupported on this system."
	fi
}

pkg_setup() {
	wine_env_vcs_variable_prechecks || die "wine_env_vcs_variable_prechecks() failed"
	wine_build_environment_prechecks || die "wine_build_environment_prechecks() failed"

	WINE_VARIANT="${PN#wine}-${PV}"
	WINE_VARIANT="${WINE_VARIANT#-}"
	MY_PREFIX="${EPREFIX%/}/usr/lib/wine-${WINE_VARIANT}"
	MY_DATAROOTDIR="${EPREFIX%/}/usr/share/wine-${WINE_VARIANT}"
	MY_DATADIR="${MY_DATAROOTDIR}"
	MY_DOCDIR="${EPREFIX%/}/usr/share/doc/${PF}"
	MY_INCLUDEDIR="${EPREFIX%/}/usr/include/wine-${WINE_VARIANT}"
	MY_LIBEXECDIR="${EPREFIX%/}/usr/libexec/wine-${WINE_VARIANT}"
	MY_LOCALSTATEDIR="${EPREFIX%/}/var/wine-${WINE_VARIANT}"
	MY_MANDIR="${MY_DATADIR}/man"
}

src_unpack() {
	default
	if [[ "${MY_PV}" == "9999" ]]; then
		# Fully Mirror git tree, Wine, so we can access commits in all branches
		EGIT_MIN_CLONE_TYPE="mirror"
		EGIT_CHECKOUT_DIR="${S}"
		wine_git_unpack "${S}"
	fi

	l10n_find_plocales_changes "${S}/po" "" ".po"
}

src_prepare() {

	eapply_bin() {
		local patch
		# shellcheck disable=SC2068
		for patch in ${PATCHES_BIN[@]}; do
			patchbin --nogit < "${patch}" || die "patchbin failed"
		done
	}

	local md5hash
	md5hash="$(md5sum server/protocol.def)" || die "md5sum failed"
	[[ ! -z "${STABLE_PREFIX}" ]] && sed -i -e 's/[\-\.[:alnum:]]\+$/'"${MY_PV}"'/' "${S}/VERSION"
	local -a PATCHES PATCHES_BIN
	PATCHES+=(
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.8_winecfg_detailed_version.patch"
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.5.26-winegcc.patch" #260726
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.6-memset-O3.patch" #480508
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.9.13-gnutls-3.5-compat.patch" #587028
		"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.8-multislot-apploader.patch" #310611
	)
	if use truetype; then
		PATCHES+=(
			"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-segfault.patch"    #631676
			"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-drop-glyphs.patch" #631676
		)
		PATCHES_BIN+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.18-freetype-2.8.1-implement_minimum_em_size_required_by_opentype_1.8.2.patch" ) #631376
	fi
	use osmesa && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-2.7-osmesa-configure_support_recent_versions.patch" ) #429386

	# https://bugs.winehq.org/show_bug.cgi?id=40851
	use cups && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.9.14-cups-2.2-cupsgetppd-build-fix.patch" )

	# https://bugs.winehq.org/show_bug.cgi?id=31836
	use gstreamer && PATCHES+=( "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/patches/${MY_PN}-1.8-gstreamer-1.0_"{01,02,03,04,05,06,07,09,10,11}".patch" )

	[[ "${MY_PV}" == "9999" ]] && sieve_patchset_array_by_git_commit "${S}" "PATCHES" "PATCHES_BIN"

	#395615 - run bash/sed script, combining both versions of the multilib-portage.patch
	ebegin "(subshell) script: \"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh\" ..."
	(
		# shellcheck disable=SC1090
		source "${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh"
	)
	eend $? || die "(subshell) script: \"${WORKDIR}/${GENTOO_WINE_EBUILD_COMMON_P%/}/scripts/${MY_PN}-multilib-portage-sed.sh\"."

	disable_man_file() {
		(($# == 3))	|| die "invalid number of arguments: ${#} (3)"
		local makefile="${1}" man_file="${2}" locale
		[[ "${3}" = "en" ]] || locale="\.${3}\.UTF-8"

		sed -i -e "\|${man_file}${locale}\.man\.in|d" "${makefile}" || die "sed failed"
	}

	#617864 Generate wine64 man pages for 64-bit bit only installation
	if use abi_x86_64 && ! use abi_x86_32; then
		find "${S%/}/loader" -type f -name "wine.*man.in" -exec sh -c 'mv "${1}" "${1/\/wine./\/wine64.}"' sh "{}" \; \
			|| die "find (mv) failed"
		sed -i -e '\|wine\.[^[:blank:]]*man\.in|{s|wine\.|wine64\.|g}' "${S%/}/loader/Makefile.in" \
			|| die "sed failed"
	fi

	#469418 Respect LINGUAS/L10N when building man pages
	local makefile_in
	find "${S}" -type f -name "Makefile.in" -exec egrep -q "^MANPAGES" "{}" \; -printf '%p\0' 2>/dev/null \
		| while IFS= read -r -d '' makefile_in; do
			l10n_for_each_disabled_locale_do disable_man_file "${makefile_in}" ""
		done

	# Don't build winedump,winemaker if not using perl
	if ! use perl; then
		# winedump calls function_grep.pl, and winemaker is a perl script
		local tools
		for tool in "winedump" "winemaker"; do
			sed -i -e '\|WINE_CONFIG_TOOL(tools/'"${tool}"',[^[:blank:]]*)$|d' "${S%/}/configure.ac" \
				|| die "sed failed"
		done
	fi

	#551124 Only build wineconsole, if either of X or ncurses is installed
	if ! use X && ! use ncurses; then
		sed -i -e '\|WINE_CONFIG_PROGRAM(wineconsole,[^[:blank:]]*)$|d' "${S%/}/configure.ac" \
			|| die "sed failed"
	fi

	default

	eapply_bin
	eautoreconf

	# Modification of the server protocol requires regenerating the server requests
	if ! md5sum -c - <<<"${md5hash}" >/dev/null 2>&1; then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die "tools/make_requests failed" #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die "sed failed"
	if use run-exes; then
		sed -i '\:^Exec=:{s:wine :wine-'"${WINE_VARIANT}"' :}' "${S}/loader/wine.desktop" || die "sed failed"
	else
		sed -i '/^MimeType/d' "${S}/loader/wine.desktop" || die "sed failed" #117785
	fi

	#472990 use hi-res default icon, https://bugs.winehq.org/show_bug.cgi?id=24652
	cp "${EROOT%/}/usr/share/wine/icons/oic_winlogo.ico" dlls/user32/resources/ || die "cp failed"

	l10n_get_locales > "${S}/po/LINGUAS" || die "l10n_get_locales failed" # Make Wine respect LINGUAS
}

src_configure() {
	wine_gcc_specific_pretests || die "wine_gcc_specific_pretests() failed"
	wine_generic_compiler_pretests || die "wine_generic_compiler_pretests() failed"

	export LDCONFIG="/bin/true"
	use custom-cflags || strip-flags

	multilib-minimal_src_configure
}

multilib_src_configure() {
	local myconf=(
		"--prefix=${MY_PREFIX}"
		"--datarootdir=${MY_DATAROOTDIR}"
		"--datadir=${MY_DATADIR}"
		"--docdir=${MY_DOCDIR}"
		"--includedir=${MY_INCLUDEDIR}"
		"--libdir=${EPREFIX}/usr/$(get_libdir)/wine-${WINE_VARIANT}"
		"--libexecdir=${MY_LIBEXECDIR}"
		"--localstatedir=${MY_LOCALSTATEDIR}"
		"--mandir=${MY_MANDIR}"
		"--sysconfdir=/etc/wine"
		$(use_with alsa)
		$(use_with capi)
		$(use_with lcms cms)
		$(use_with cups)
		$(use_with ncurses curses)
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
		$(use_with udisks dbus)
		$(use_with v4l)
		$(use_with X x)
		$(use_with xcomposite)
		$(use_with xinerama)
		$(use_with xml)
		$(use_with xml xslt)
	)

	local PKG_CONFIG AR RANLIB
	#472038 Avoid crossdev's i686-pc-linux-gnu-pkg-config if building wine32 on amd64
	#483342 set AR and RANLIB to make QA scripts happy
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
	if [[ "${ABI}" == "x86" ]]; then
		if [[ "$(id -u)" == "0" ]]; then
			ewarn "Skipping tests since they cannot be run under the root user."
			ewarn "To run the test ${MY_PN} suite, add userpriv to FEATURES in make.conf"
			return
		fi
		WINEPREFIX="${T}/.wine-${ABI}" \
			Xemake test
	fi
}

multilib_src_install_all() {
	DOCS=( "ANNOUNCE" "AUTHORS" "README" )
	add_locale_docs() {
		local locale_doc="documentation/README.${1}"
		[[ ! -e "S{S}/${locale_doc}" ]] || DOCS+=( "${locale_doc}" )
	}
	l10n_for_each_locale_do add_locale_docs

	einstalldocs
	unset -v DOCS

	prune_libtool_files --all

	use abi_x86_32 && pax-mark psmr "${D%/}${MY_PREFIX}/bin/wine"{,-preloader}   #255055
	use abi_x86_64 && pax-mark psmr "${D%/}${MY_PREFIX}/bin/wine64"{,-preloader} #255055

	if use abi_x86_64 && ! use abi_x86_32; then
		#404331
		dosym "wine64" "${MY_PREFIX}/bin/wine"
		dosym "wine64-preloader" "${MY_PREFIX}/bin/wine-preloader"

		# Symlink wine manpage - for all active locales
		local manpage manpage_target="wine64.1"
		while IFS= read -r -d '' manpage; do
			dosym "${manpage_target}" "${manpage/%${manpage_target}/${manpage_target/64/}}"
		done < <(find "${MY_MANDIR}" -type f -name "${manpage_target}" -printf '%p\0' 2>/dev/null)
	fi

	# Make wrappers for binaries for handling multiple variants
	local binary_file
	while IFS= read -r -d '' binary_file; do
		make_wrapper "${binary_file}-${WINE_VARIANT}" "${MY_PREFIX}/bin/${binary_file}"
	done < <(find "${D%/}${MY_PREFIX}/bin" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -printf '%f\0' 2>/dev/null)
}

pkg_postinst() {
	local wine_git_commit wine_git_date

	if [[ "${MY_PV}" == "9999" ]]; then
		pushd "${S}" || die "pushd failed"
		wine_git_commit="$(git rev-parse HEAD)" || die "git rev-parse failed"
		wine_git_date="$(git show -s --format=%cd "${wine_git_commit}")" || die "git show failed"
		popd || die "popd failed"
	fi

	# shellcheck disable=SC2086,SC2090
	eselect wine register ${wine_git_commit:+--commit=}"${wine_git_commit}" ${wine_git_date:+--date=}"${wine_git_date}" \
			--verbose --wine --vanilla "${P}" \
		|| die "eselect wine register --wine --vanilla \"${P}\" failed"
	eselect wine set --force --verbose --wine --vanilla --if-unset "${P}" \
		|| die "eselect wine set --force --wine --vanilla --if-unset \"${P}\" failed"

	if ! use gecko; then
		ewarn "Without Wine Gecko, wine prefixes will not have a default"
		ewarn "implementation of iexplore.  Many older windows applications"
		ewarn "rely upon the existence of an iexplore implementation, so"
		ewarn "you will likely need to install an external one, using winetricks."
	fi
	if ! use mono; then
		ewarn "Without Wine Mono, wine prefixes will not have a default"
		ewarn "implementation of .NET.  Many windows applications rely upon"
		ewarn "the existence of a .NET implementation, so you will likely need"
		ewarn "to install an external one, using winetricks."
	fi
}

pkg_prerm() {
	eselect wine deregister --force --verbose --wine --vanilla "${P}" \
		|| die "eselect wine deregister --force --wine --vanilla \"${P}\" failed"
}

pkg_postrm() {
	xdg_mimeinfo_database_update
}
