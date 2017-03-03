# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PLOCALES="ar bg ca cs da de el en en_US eo es fa fi fr he hi hr hu it ja ko lt ml nb_NO nl or pa pl pt_BR pt_PT rm ro ru sk sl sr_RS@cyrillic sr_RS@latin sv te th tr uk wa zh_CN zh_TW"
PLOCALE_BACKUP="en"

inherit autotools fdo-mime flag-o-matic gnome2-utils l10n multilib multilib-minimal pax-utils toolchain-funcs virtualx versionator

MY_PV="${PV}"
MY_P="${P}"
STAGING_SUFFIX=""
if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="git://source.winehq.org/git/wine.git http://source.winehq.org/git/wine.git"
	inherit git-r3
	SRC_URI=""
	#KEYWORDS=""
else
	rc_version=0
	[[ "$(get_version_component_range $(get_version_component_count))" =~ ^rc ]] && rc_version=1
	if (( rc_version )); then
		MY_PV=$(replace_version_separator $(get_last_version_component_index) '''-''')
		#KEYWORDS=""
	else
		KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
	fi
	MY_P="${PN}-${MY_PV}"
	major_version=$(get_major_version)
	minor_version=$(get_version_component_range 2)
	stable_version=$(( (major_version == 1 && (minor_version % 2 == 0)) || (major_version >= 2 && minor_version == 0) ))
	if (( stable_version && rc_version )); then
		# Pull Wine RC stable versions from alternate Github repostiory...
		STABLE_PREFIX="wine-stable"
		MY_P="${STABLE_PREFIX}-${MY_P}"
		SRC_URI="https://github.com/mstefani/wine-stable/archive/${PN}-${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	elif (( stable_version || (major_version < 2) )); then
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.${minor_version}/${MY_P}.tar.bz2 -> ${P}.tar.bz2"
	else
		SRC_URI="https://dl.winehq.org/wine/source/${major_version}.x/${MY_P}.tar.xz -> ${P}.tar.xz"
	fi
	((major_version == 1 && minor_version == 8)) && STAGING_SUFFIX="-unofficial"
	unset -v minor_version major_version rc_version stable_version
fi

VANILLA_GV="2.40"
VANILLA_MV="4.5.6"
STAGING_P="wine-staging-${MY_PV}"
STAGING_DIR="${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}"
STAGING_HELPER="wine-staging-git-helper-0.1.3"
WINE_GENTOO="wine-gentoo-2015.03.07"
GST_P="wine-1.8-gstreamer-1.0"
DESCRIPTION="Free implementation of Windows(tm) on Unix"
HOMEPAGE="http://www.winehq.org/"
SRC_URI="${SRC_URI}
	!staging? (
		gecko? (
			abi_x86_32? ( https://dl.winehq.org/wine/wine-gecko/${VANILLA_GV}/wine_gecko-${VANILLA_GV}-x86.msi )
			abi_x86_64? ( https://dl.winehq.org/wine/wine-gecko/${VANILLA_GV}/wine_gecko-${VANILLA_GV}-x86_64.msi )
		)
		mono? ( https://dl.winehq.org/wine/wine-mono/${VANILLA_MV}/wine-mono-${VANILLA_MV}.msi )
	)
	staging? (
		gecko? (
			abi_x86_32? ( https://dl.winehq.org/wine/wine-gecko/${STAGING_GV:-${VANILLA_GV}}/wine_gecko-${STAGING_GV:-${VANILLA_GV}}-x86.msi )
			abi_x86_64? ( https://dl.winehq.org/wine/wine-gecko/${STAGING_GV:-${VANILLA_GV}}/wine_gecko-${STAGING_GV:-${VANILLA_GV}}-x86_64.msi )
		)
		mono? ( https://dl.winehq.org/wine/wine-mono/${STAGING_MV:-${VANILLA_MV}}/wine-mono-${STAGING_MV:-${VANILLA_MV}}.msi )
	)
	gstreamer? ( https://dev.gentoo.org/~np-hardass/distfiles/${PN}/${GST_P}.patch.bz2 )
	https://dev.gentoo.org/~tetromino/distfiles/${PN}/${WINE_GENTOO}.tar.bz2"

if [[ ${PV} == "9999" ]]; then
	STAGING_EGIT_REPO_URI="git://github.com/wine-compholio/wine-staging.git"
	SRC_URI="${SRC_URI}
	staging? ( https://github.com/bobwya/${STAGING_HELPER%-*}/archive/${STAGING_HELPER##*-}.tar.gz -> ${STAGING_HELPER}.tar.gz )"
else
	SRC_URI="${SRC_URI}
	staging? ( https://github.com/wine-compholio/wine-staging/archive/v${MY_PV}${STAGING_SUFFIX}.tar.gz -> ${STAGING_P}.tar.gz )"
fi

LICENSE="LGPL-2.1"
SLOT="0"
IUSE="+abi_x86_32 +abi_x86_64 +alsa capi cups custom-cflags dos elibc_glibc +fontconfig +gecko gphoto2 gsm gstreamer +jpeg kernel_FreeBSD +lcms ldap +mono mp3 ncurses netapi nls odbc openal opencl +opengl osmesa oss +perl pcap pipelight +png prelink pulseaudio +realtime +run-exes s3tc samba scanner selinux +ssl staging test themes +threads +truetype +udisks v4l vaapi +X +xcomposite xinerama +xml"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )
	X? ( truetype )
	elibc_glibc? ( threads )
	mono? ( abi_x86_32 )
	osmesa? ( opengl )
	pipelight? ( staging )
	s3tc? ( staging )
	test? ( abi_x86_32 )
	themes? ( staging )
	vaapi? ( staging )" # osmesa-opengl #286560 # X-truetype #551124

# FIXME: the test suite is unsuitable for us; many tests require net access
# or fail due to Xvfb's opengl limitations.
RESTRICT="test"

COMMON_DEPEND="
	X? (
		x11-libs/libXcursor[${MULTILIB_USEDEP}]
		x11-libs/libXext[${MULTILIB_USEDEP}]
		x11-libs/libXrandr[${MULTILIB_USEDEP}]
		x11-libs/libXi[${MULTILIB_USEDEP}]
		x11-libs/libXxf86vm[${MULTILIB_USEDEP}]
	)
	alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	capi? ( net-libs/libcapi[${MULTILIB_USEDEP}] )
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
	netapi? ( net-fs/samba[netapi(+),${MULTILIB_USEDEP}] )
	nls? ( sys-devel/gettext[${MULTILIB_USEDEP}] )
	odbc? ( dev-db/unixODBC:=[${MULTILIB_USEDEP}] )
	openal? ( media-libs/openal:=[${MULTILIB_USEDEP}] )
	opencl? ( virtual/opencl[${MULTILIB_USEDEP}] )
	opengl? (
		virtual/glu[${MULTILIB_USEDEP}]
		virtual/opengl[${MULTILIB_USEDEP}]
	)
	osmesa? ( media-libs/mesa[osmesa,${MULTILIB_USEDEP}] )
	pcap? ( net-libs/libpcap[${MULTILIB_USEDEP}] )
	png? ( media-libs/libpng:0=[${MULTILIB_USEDEP}] )
	pulseaudio? ( media-sound/pulseaudio[${MULTILIB_USEDEP}] )
	scanner? ( media-gfx/sane-backends:=[${MULTILIB_USEDEP}] )
	ssl? ( net-libs/gnutls:=[${MULTILIB_USEDEP}] )
	staging? ( sys-apps/attr[${MULTILIB_USEDEP}] )
	themes? ( x11-libs/gtk+:3[X?,${MULTILIB_USEDEP}] )
	truetype? ( >=media-libs/freetype-2.0.5[${MULTILIB_USEDEP}] )
	udisks? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	v4l? ( media-libs/libv4l[${MULTILIB_USEDEP}] )
	vaapi? ( x11-libs/libva[X,${MULTILIB_USEDEP}] )
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
	dos? ( >=games-emulation/dosbox-0.74_p20160629 )
	perl? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	pulseaudio? (
		realtime? ( sys-auth/rtkit )
	)
	s3tc? ( >=media-libs/libtxc_dxtn-1.0.1-r1[${MULTILIB_USEDEP}] )
	samba? ( >=net-fs/samba-3.0.25[winbind] )
	selinux? ( sec-policy/selinux-wine )
	udisks? ( sys-fs/udisks:2 )"

# tools/make_requests requires perl
DEPEND="${COMMON_DEPEND}
	>=sys-devel/flex-2.5.33
	>=sys-kernel/linux-headers-2.6
	virtual/pkgconfig
	virtual/yacc
	X? (
		x11-proto/inputproto
		x11-proto/xextproto
		x11-proto/xf86vidmodeproto
	)
	prelink? ( sys-devel/prelink )
	staging? (
		dev-lang/perl
		dev-perl/XML-Simple
	)
	xinerama? ( x11-proto/xineramaproto )"

# These use a non-standard "Wine" category, which is provided by
# /etc/xdg/applications-merged/wine.menu
QA_DESKTOP_FILE="usr/share/applications/wine-browsedrive.desktop
usr/share/applications/wine-notepad.desktop
usr/share/applications/wine-uninstaller.desktop
usr/share/applications/wine-winecfg.desktop"

S="${WORKDIR}/${MY_P}"

wine_gcc_specific_pretests() {
	( [[ "${MERGE_TYPE}" = "binary" ]] || ! tc-is-gcc ) && return 0

	# bug #549768
	if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -le 2 ]]; then
		ebegin "(subshell): checking for gcc-5.1/gcc-5.2 MS X86_64 ABI compiler bug ..."
		( # Run in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 "${FILESDIR}/pr66838.c" -o "${T}/pr66838" || die "cc compilation failed: pr66838 test"
			"${T}"/pr66838 &>/dev/null || die "pr66838 test failed"
		)
		if ! eend $?; then
			eerror "(subshell): gcc-5.1/5.2 MS X86_64 ABI compiler bug detected."
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
		ebegin "(subshell): checking for gcc-5.3.0 X86_64 misaligned stack compiler bug ..."
		( # Compile in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 -mincoming-stack-boundary=3 "${FILESDIR}"/pr69140.c -o "${T}"/pr69140 &>/dev/null || die "pr69140 test failed"
		)
		if ! eend $?; then
			eerror "(subshell): gcc-5.3.0 X86_64 misaligned stack compiler bug detected."
			eerror "Please re-emerge the latest gcc-5.3.0 ebuild, or use gcc-config to select a different compiler version."
			eerror "See https://bugs.gentoo.org/574044"
			eerror
			return 1
		fi
	fi
}

wine_generic_compiler_pretests() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	if use abi_x86_64; then
		ebegin "(subshell): checking compiler support for (64-bit) builtin_ms_va_list ..."
		( # Compile in a subshell to prevent "Aborted" message
			$(tc-getCC) -O2 "${FILESDIR}"/builtin_ms_va_list.c -o "${T}"/builtin_ms_va_list &>/dev/null || die "test for builtin_ms_va_list support failed"
		)
		if ! eend $?; then
			eerror "(subshell): $(tc-getCC) does not support builtin_ms_va_list."
			eerror "Please re-emerge using a compiler (version) that supports building 64-bit Wine."
			eerror "Use >=sys-devel/gcc-4.4 or >=sys-devel/clang-3.8 to build ${CATEGORY}/${PN}."
			eerror
			return 1
		fi
	fi
}

wine_build_environment_prechecks() {
	[[ ${MERGE_TYPE} = "binary" ]] && return 0

	if use abi_x86_32 && use opencl && [[ "$(eselect opencl show 2>/dev/null)" == "intel" ]]; then
		eerror "You cannot build wine with USE=+opencl because intel-ocl-sdk is 64-bit only."
		eerror "See https://bugs.gentoo.org/487864"
		eerror
		return 1
	fi
}

wine_env_vcs_variable_prechecks() {
	local pn_live_variable="${PN//[-+]/_}_LIVE_COMMIT"
	local pn_live_value="${!pn_live_variable}"
	local env_error=false

	if [[ ! -z "${pn_live_value}" ]] && use staging; then
		eerror "Because ${PN} is multi-repository based, ${pn_live_variable}"
		eerror "cannot be used to set the commit."
		env_error=true
	fi
	[[ ! -z ${EGIT_COMMIT} || ! -z ${EGIT_BRANCH} ]] && \
		env_error=true
	if [[ ${env_error} == true ]]; then
		eerror "Git commit (and branch) overrides must now be specified"
		eerror "using ONE of following the environmental variables:"
		eerror "  EGIT_WINE_COMMIT or EGIT_WINE_BRANCH (Wine)"
		eerror "  EGIT_STAGING_COMMIT or EGIT_STAGING_BRANCH (Wine-Staging)."
		eerror
		return 1
	fi
}

wine_git_unpack() {
	if [[ ! -z "${EGIT_WINE_COMMIT}" ]]; then
		ewarn "Building Wine against Wine git commit EGIT_WINE_COMMIT=\"${EGIT_WINE_COMMIT}\" ."
		EGIT_COMMIT="${EGIT_WINE_COMMIT}" git-r3_src_unpack
	elif [[ ! -z "${EGIT_WINE_BRANCH}" ]]; then
		ewarn "Building Wine against Wine git branch EGIT_WINE_BRANCH=\"${EGIT_WINE_BRANCH}\" ."
		EGIT_BRANCH="${EGIT_WINE_BRANCH}" git-r3_src_unpack
	else
		EGIT_BRANCH="master" git-r3_src_unpack
	fi
}

pkg_pretend() {
	wine_gcc_specific_pretests || die
	wine_generic_compiler_pretests || die
	wine_build_environment_prechecks || die

	# Verify OSS support
	if use oss && ! use kernel_FreeBSD && ! has_version '>=media-sound/oss-4'; then
		eerror "You cannot build wine with USE=+oss without having support from a FreeBSD kernel"
		eerror "or >=media-sound/oss-4 (only available through an Overlay)."
		die "USE=+oss currently unsupported on this system."
	fi
}

pkg_setup() {
	wine_build_environment_prechecks || die
	wine_env_vcs_variable_prechecks || die

	if ! use staging; then
		GV="${VANILLA_GV}"
		MV="${VANILLA_MV}"
	else
		GV="${STAGING_GV:-${VANILLA_GV}}"
		MV="${STAGING_MV:-${VANILLA_MV}}"
	fi
}

src_unpack() {
	default
	if [[ ${PV} == "9999" ]]; then
		# Fully Mirror git tree, Wine, so we can access commits in all branches
		EGIT_MIN_CLONE_TYPE="mirror"
		EGIT_CHECKOUT_DIR="${S}"
		if ! use staging; then
			wine_git_unpack
		elif [[ ! -z "${EGIT_STAGING_COMMIT:-${EGIT_STAGING_BRANCH}}" ]]; then
			# References are relative to Wine-Staging git tree (checkout Wine-Staging git tree first)
			# Use env variables "EGIT_STAGING_COMMIT" or "EGIT_STAGING_BRANCH" to reference Wine-Staging git tree
			# Use git-r3 internal functions for secondary Wine-Staging repository. See #588604
			ebegin "(subshell): you have specified a Wine-Staging git reference (building Wine git with USE +staging) ..."
			(
				source "${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh" || die
				if [[ ! -z "${EGIT_STAGING_COMMIT}" ]]; then
					ewarn "Building Wine against Wine-Staging git commit EGIT_STAGING_COMMIT=\"${EGIT_STAGING_COMMIT}\" ."
					git-r3_fetch "${STAGING_EGIT_REPO_URI}" "${EGIT_STAGING_COMMIT}"
				else
					ewarn "Building Wine against Wine-Staging git branch EGIT_STAGING_BRANCH=\"${EGIT_STAGING_BRANCH}\" ."
					git-r3_fetch "${STAGING_EGIT_REPO_URI}" "refs/heads/${EGIT_STAGING_BRANCH}"
				fi
				git-r3_checkout "${STAGING_EGIT_REPO_URI}" "${STAGING_DIR}"
				wine_staging_commit="${EGIT_VERSION}"
				get_upstream_wine_commit  "${STAGING_DIR}" "${wine_staging_commit}" "wine_commit"
				EGIT_COMMIT="${wine_commit}" git-r3_src_unpack
				einfo "Building Wine commit \"${wine_commit}\" referenced by Wine-Staging commit \"${wine_staging_commit}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine commit."
		else
			# References are relative to Wine git tree (post-checkout Wine-Staging git tree)
			# Use env variables "EGIT_WINE_COMMIT" or "EGIT_WINE_BRANCH" to reference Wine git tree
			# Use git-r3 internal functions for secondary Wine-Staging repository. See #588604
			ebegin "(subshell): You are using a Wine git reference (building Wine git with USE +staging) ..."
			(
				source "${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh" || die
				wine_git_unpack
				wine_commit="${EGIT_VERSION}"
				git-r3_fetch "${STAGING_EGIT_REPO_URI}" "HEAD"
				git-r3_checkout "${STAGING_EGIT_REPO_URI}" "${STAGING_DIR}"
				if ! walk_wine_staging_git_tree "${STAGING_DIR}" "${S}" "${wine_commit}" "wine_staging_commit" ; then
					find_closest_wine_commit "${STAGING_DIR}" "${S}" "wine_commit" "wine_staging_commit" "wine_commit_offset"
					(($? == 0)) && display_closest_wine_commit_message "${wine_commit}" "${wine_staging_commit}" "${wine_commit_offset}"
					die "Failed to find Wine-Staging git commit corresponding to supplied Wine git commit \"${wine_commit}\" ."
				fi
				einfo "Building Wine-Staging commit \"${wine_staging_commit}\" corresponding to Wine commit \"${wine_commit}\" ..."
			)
			eend $? || die "(subshell): ... failed to determine target Wine-Staging commit."
		fi
	fi

	l10n_find_plocales_changes "${S}/po" "" ".po"
}

src_prepare() {
	local md5hash="$(md5sum server/protocol.def || die "md5sum")"
	[[ ! -z "${STABLE_PREFIX}" ]] && sed -i -e 's/[\-\.[:alnum:]]\+$/'"${MY_PV}"'/' "${S}/VERSION"
	local PATCHES=(
		"${FILESDIR}/${PN}-1.8_winecfg_detailed_version.patch"
		"${FILESDIR}/${PN}-1.5.26-winegcc.patch" #260726
		"${FILESDIR}/${PN}-1.7.12-osmesa-check.patch" #429386
		"${FILESDIR}/${PN}-1.6-memset-O3.patch" #480508
		"${FILESDIR}/${PN}-winhlp32-macro-flex-2.6.3-flex.patch" # https://bugs.winehq.org/show_bug.cgi?id=42132
	)
	if [[ ${PV} != "9999" ]]; then
		use gstreamer && PATCHES+=( "${WORKDIR}/${GST_P}.patch" )
	else
		# only apply gstreamer:1.0 patch to older versions of wine, using gstreamer:0.1 API/ABI
		grep -q "gstreamer-0.10" "${S}/configure" &>/dev/null || unset GST_P
		[[ ! -z "${GST_P}" ]] && use gstreamer && PATCHES+=( "${WORKDIR}/${GST_P}.patch" )
	fi
	#395615 - run bash/sed script, combining both versions of the multilib-portage.patch
	ebegin "(subshell) script: \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" ..."
	(
		source "${FILESDIR}/${PN}-9999-multilib-portage-sed.sh" || die
	)
	eend $? || die "(subshell) script: \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\"."
	if use staging; then
		ewarn "Applying the Wine-Staging patchset. Any bug reports to the"
		ewarn "Wine bugzilla should explicitly state that staging was used."

		# Declare Wine-Staging excluded patchsets
		local -a STAGING_EXCLUDE_PATCHSETS=( "winhlp32-Flex_Workaround" )
		use pipelight || STAGING_EXCLUDE_PATCHSETS+=( "Pipelight" )

		# Process Wine-Staging exluded patchsets
		local array_indices=( ${!STAGING_EXCLUDE_PATCHSETS[*]} )
		for ((i=0; i<${#array_indices[*]}; i++)); do
			local patchset="${STAGING_EXCLUDE_PATCHSETS[array_indices[i]]}"
			if grep -q "${patchset})" "${STAGING_DIR}/patches/patchinstall.sh"; then
				STAGING_EXCLUDE_PATCHSETS[${array_indices[i]}]="-W ${patchset}"
				einfo "Excluding Wine-Staging patchset: \"${patchset}\""
			else
				unset -v STAGING_EXCLUDE_PATCHSETS[${array_indices[i]}]
			fi
		done

		# Launch wine-staging patcher in a subshell, using eapply as a backend, and gitapply.sh as a backend for binary patches
		ebegin "Running Wine-Staging patch installer"
		(
			set -- DESTDIR="${S}" --backend=eapply --no-autoconf --all ${STAGING_EXCLUDE_PATCHSETS[@]}
			cd "${STAGING_DIR}/patches"
			source "${STAGING_DIR}/patches/patchinstall.sh"
		)
		eend $? || die "(subshell) script: failed to apply Wine-Staging patches (excluding: ${STAGING_EXCLUDE_PATCHSETS[@]})."
		sed -r -i -e '/^AC_INIT\(.*\)$/{s/\[Wine\]/\[Wine \(Staging\)\]/}' "${S}/configure.ac" || die "sed failed"
		sed -r -i -e 's/Wine (\(Staging\) |)/Wine \(Staging\) /' "${S}/VERSION" || die "sed failed"

		if [[ ! -z "${STAGING_SUFFIX}" ]]; then
			sed -i -e 's/(Staging)/(Staging'"${STAGING_SUFFIX}"')/' libs/wine/Makefile.in || die "sed failed"
		fi
	fi

	default
	eautoreconf

	# Modification of the server protocol requires regenerating the server requests
	if ! $(md5sum -c - <<<"${md5hash}" &>/dev/null); then
		einfo "server/protocol.def was patched; running tools/make_requests"
		tools/make_requests || die "tools/make_requests failed" #432348
	fi
	sed -i '/^UPDATE_DESKTOP_DATABASE/s:=.*:=true:' tools/Makefile.in || die "sed failed"
	if ! use run-exes; then
		sed -i '/^MimeType/d' loader/wine.desktop || die "sed failed" #117785
	fi

	# hi-res default icon, #472990, http://bugs.winehq.org/show_bug.cgi?id=24652
	cp "${WORKDIR}"/${WINE_GENTOO}/icons/oic_winlogo.ico dlls/user32/resources/ || die "cp failed"

	l10n_get_locales > po/LINGUAS || die "l10n_get_locales failed" # otherwise wine doesn't respect LINGUAS
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
		$(use_with themes gtk3)
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
	DOCS=( "ANNOUNCE" "AUTHORS" "README" )
	add_locale_docs() {
		local locale_doc="documentation/README.${1}"
		[[ ! -e "S{S}/${locale_doc}" ]] || DOCS+=( "${locale_doc}" )
	}
	l10n_for_each_locale_do add_locale_docs

	einstalldocs
	unset -v DOCS

	prune_libtool_files --all

	emake -C "../${WINE_GENTOO}" install DESTDIR="${D}" EPREFIX="${EPREFIX}"
	if use gecko; then
		insinto /usr/share/wine/gecko
		use abi_x86_32 && doins "${DISTDIR}/wine_gecko-${GV}-x86.msi"
		use abi_x86_64 && doins "${DISTDIR}/wine_gecko-${GV}-x86_64.msi"
	fi
	if use mono; then
		insinto /usr/share/wine/mono
		doins "${DISTDIR}/wine-mono-${MV}.msi"
	fi
	if ! use perl; then  # winedump calls function_grep.pl, and winemaker is a perl script
		rm "${D}usr/bin"/{wine{dump,maker},function_grep.pl} || die "rm failed"
		rm "${D}usr/share/man/man1"/wine{dump,maker}.1 || die "rm failed"
	fi

	# Remove wineconsole if neither backend is installed #551124
	if ! use X && ! use ncurses; then
		rm "${D}"/usr/bin/wineconsole* || die "rm failed"
		rm "${D}"/usr/share/man/man1/wineconsole* || die "rm failed"
		rm_wineconsole() {
			rm "${D}usr/$(get_libdir)"/wine/{,fakedlls/}wineconsole.exe* || die "rm failed"
		}
		multilib_foreach_abi rm_wineconsole
	fi

	use abi_x86_32 && pax-mark psmr "${D}"usr/bin/wine{,-preloader} #255055
	use abi_x86_64 && pax-mark psmr "${D}"usr/bin/wine64{,-preloader}

	if use abi_x86_64 && ! use abi_x86_32; then
		dosym /usr/bin/wine{64,} # 404331
		dosym /usr/bin/wine{64,}-preloader
	fi

	# respect LINGUAS when installing man pages, #469418
	local locale_man
	for locale_man in "de" "fr" "pl"; do
		use linguas_${locale_man} || rm -r "${D}/usr/share/man/${locale_man}"*
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
	if [[ ! -z "${GST_P}" ]] && use gstreamer; then
		ewarn "This package uses a Gentoo specific patchset to provide "
		ewarn "gstreamer:1.0 API / ABI support.  Any bugs related to GStreamer"
		ewarn "should be filed at Gentoo's bugzilla, not upstream's."
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update
}
