# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

FIREFOX_PATCHSET="firefox-116-patches-01.tar.xz"
MOZ_KDE_PATCHSET="mozilla-kde-opensuse-patchset-${P}"

LLVM_MAX_SLOT=16

PYTHON_COMPAT=( python3_{9..11} )
PYTHON_REQ_USE="ncurses,sqlite,ssl"

WANT_AUTOCONF="2.1"

VIRTUALX_REQUIRED="manual"

MOZ_ESR=

MOZ_PV=${PV}
MOZ_PV_SUFFIX=

if [[ -n ${MOZ_ESR} ]]; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

MOZ_PN="${PN%-bin}"
MOZ_P="${MOZ_PN}-${MOZ_PV}"
MOZ_PV_DISTFILES="${MOZ_PV}${MOZ_PV_SUFFIX}"
MOZ_P_DISTFILES="${MOZ_PN}-${MOZ_PV_DISTFILES}"

inherit autotools check-reqs desktop flag-o-matic gnome2-utils linux-info llvm multiprocessing \
	optfeature pax-utils python-any-r1 toolchain-funcs virtualx xdg

MOZ_SRC_BASE_URI="https://archive.mozilla.org/pub/${MOZ_PN}/releases/${MOZ_PV}"
MOZ_KDE_OPENSUSE_BASE_URI="https://github.com/bobwya/mozilla-kde-opensuse-patchset"

PATCH_URIS=( "https://dev.gentoo.org/"~{polynomial-c,whissi}"/mozilla/patchsets/${FIREFOX_PATCHSET}" )
# shellcheck disable=SC2124
SRC_URI="${MOZ_SRC_BASE_URI}/source/${MOZ_P}.source.tar.xz
	${PATCH_URIS[@]}
	kde? ( ${MOZ_KDE_OPENSUSE_BASE_URI}/raw/main/${MOZ_KDE_PATCHSET}.tar.xz )"

DESCRIPTION="Firefox Web Browser, with SUSE patchset, to provide better KDE integration"
HOMEPAGE="https://www.mozilla.com/firefox
	https://www.rosenauer.org/hg/mozilla"

KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"

SLOT="rapid"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"

IUSE="+clang cpu_flags_arm_neon dbus debug eme-free hardened hwaccel kde"
IUSE+=" jack +jumbo-build libproxy lto +openh264 pgo pulseaudio sndio selinux"
IUSE+=" +system-av1 +system-harfbuzz +system-icu +system-jpeg +system-libevent +system-libvpx system-png system-python-libs +system-webp"
IUSE+=" +telemetry valgrind wayland wifi +X"

# Firefox-only IUSE
IUSE+=" geckodriver +gmp-autoupdate screencast"

REQUIRED_USE="|| ( X wayland )
	debug? ( !system-av1 )
	!jumbo-build? ( clang )
	pgo? ( lto )
	wifi? ( dbus )"

FF_ONLY_DEPEND="!www-client/firefox:0
	!www-client/firefox:esr
	screencast? ( media-video/pipewire:= )
	selinux? ( sec-policy/selinux-mozilla )"
BDEPEND="${PYTHON_DEPS}
	|| (
		(
			sys-devel/clang:16
			sys-devel/llvm:16
			clang? (
				|| (
					sys-devel/lld:16
					sys-devel/mold
				)
				virtual/rust:0/llvm-16
				pgo? ( =sys-libs/compiler-rt-sanitizers-16*[profile] )
			)
		)
		(
			sys-devel/clang:15
			sys-devel/llvm:15
			clang? (
				|| (
					sys-devel/lld:15
					sys-devel/mold
				)
				virtual/rust:0/llvm-15
				pgo? ( =sys-libs/compiler-rt-sanitizers-15*[profile] )
			)
		)
	)
	app-alternatives/awk
	app-arch/unzip
	app-arch/zip
	>=dev-util/cbindgen-0.24.3
	net-libs/nodejs
	virtual/pkgconfig
	!clang? ( >=virtual/rust-1.65 )
	amd64? ( >=dev-lang/nasm-2.14 )
	x86? ( >=dev-lang/nasm-2.14 )
	pgo? (
		X? (
			sys-devel/gettext
			x11-base/xorg-server[xvfb]
			x11-apps/xhost
		)
		wayland? (
			>=gui-libs/wlroots-0.15.1-r1[tinywl]
			x11-misc/xkeyboard-config
		)
	)"
COMMON_DEPEND="${FF_ONLY_DEPEND}
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/libffi:=
	>=dev-libs/nss-3.91
	>=dev-libs/nspr-4.35
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa
	media-video/ffmpeg
	sys-libs/zlib
	virtual/freedesktop-icon-theme
	x11-libs/cairo
	x11-libs/gdk-pixbuf
	x11-libs/pango
	x11-libs/pixman
	dbus? (
		dev-libs/dbus-glib
		sys-apps/dbus
	)
	jack? ( virtual/jack )
	pulseaudio? (
		|| (
			media-libs/libpulse
			>=media-sound/apulse-0.1.12-r4[sdk]
		)
	)
	libproxy? ( net-libs/libproxy )
	selinux? ( sec-policy/selinux-mozilla )
	sndio? ( >=media-sound/sndio-1.8.0-r1 )
	screencast? ( media-video/pipewire:= )
	system-av1? (
		>=media-libs/dav1d-1.0.0:=
		>=media-libs/libaom-1.0.0:=
	)
	system-harfbuzz? (
		>=media-gfx/graphite2-1.3.13
		>=media-libs/harfbuzz-2.8.1:0=
	)
	system-icu? ( >=dev-libs/icu-73.1:= )
	system-jpeg? ( >=media-libs/libjpeg-turbo-1.2.1 )
	system-libevent? ( >=dev-libs/libevent-2.1.12:0=[threads(+)] )
	system-libvpx? ( >=media-libs/libvpx-1.8.2:0=[postproc] )
	system-png? ( >=media-libs/libpng-1.6.35:0=[apng] )
	system-webp? ( >=media-libs/libwebp-1.1.0:0= )
	valgrind? ( dev-util/valgrind )
	wayland? (
		>=media-libs/libepoxy-1.5.10-r1
		x11-libs/gtk+:3[wayland]
		x11-libs/libxkbcommon[wayland]
	)
	wifi? (
		kernel_linux? (
			dev-libs/dbus-glib
			net-misc/networkmanager
			sys-apps/dbus
		)
	)
	X? (
		virtual/opengl
		x11-libs/cairo[X]
		x11-libs/gtk+:3[X]
		x11-libs/libX11
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libxkbcommon[X]
		x11-libs/libXrandr
		x11-libs/libXtst
		x11-libs/libxcb:=
	)"
RDEPEND="${COMMON_DEPEND}
	jack? ( virtual/jack )
	kde? ( kde-misc/kmozillahelper )
	openh264? ( media-libs/openh264:*[plugin] )"
DEPEND="${COMMON_DEPEND}
	X? (
		x11-base/xorg-proto
		x11-libs/libICE
		x11-libs/libSM
	)"

S="${WORKDIR}/${PN}-${PV%_*}"

# Allow MOZ_GMP_PLUGIN_LIST to be set in an eclass or
# overridden in the enviromnent (advanced hackers only)
if [[ -z "${MOZ_GMP_PLUGIN_LIST+set}" ]]; then
	MOZ_GMP_PLUGIN_LIST=( gmp-gmpopenh264 gmp-widevinecdm )
fi

llvm_check_deps() {
	local -r llvm_message="Cannot use LLVM slot ${LLVM_SLOT} ..."
	if ! has_version -b "sys-devel/clang:${LLVM_SLOT}"; then
		einfo "sys-devel/clang:${LLVM_SLOT} is missing! ${llvm_message}" >&2
		return 1
	fi

	if use clang && ! tc-ld-is-mold; then
		if ! has_version -b "sys-devel/lld:${LLVM_SLOT}"; then
			einfo "sys-devel/lld:${LLVM_SLOT} is missing! ${llvm_message}" >&2
			return 1
		fi

		if ! has_version -b "virtual/rust:0/llvm-${LLVM_SLOT}"; then
			einfo "virtual/rust:0/llvm-${LLVM_SLOT} is missing! ${llvm_message}" >&2
			return 1
		fi

		if use pgo; then
			if ! has_version -b "=sys-libs/compiler-rt-sanitizers-${LLVM_SLOT}*[profile]"; then
				einfo "=sys-libs/compiler-rt-sanitizers-${LLVM_SLOT}*[profile] is missing! ${llvm_message}" >&2
				return 1
			fi
		fi
	fi

	einfo "Using LLVM slot ${LLVM_SLOT} to build" >&2
}

MOZ_LANGS=(
	af ar ast be bg br ca cak cs cy da de dsb
	el en-CA en-GB en-US es-AR es-ES et eu
	fi fr fy-NL ga-IE gd gl he hr hsb hu
	id is it ja ka kab kk ko lt lv ms nb-NO nl nn-NO
	pa-IN pl pt-BR pt-PT rm ro ru
	sk sl sq sr sv-SE th tr uk uz vi zh-CN zh-TW
)

# Firefox-only LANGS
MOZ_LANGS+=( ach )
MOZ_LANGS+=( an )
MOZ_LANGS+=( az )
MOZ_LANGS+=( bn )
MOZ_LANGS+=( bs )
MOZ_LANGS+=( ca-valencia )
MOZ_LANGS+=( eo )
MOZ_LANGS+=( es-CL )
MOZ_LANGS+=( es-MX )
MOZ_LANGS+=( fa )
MOZ_LANGS+=( ff )
MOZ_LANGS+=( fur )
MOZ_LANGS+=( gn )
MOZ_LANGS+=( gu-IN )
MOZ_LANGS+=( hi-IN )
MOZ_LANGS+=( hy-AM )
MOZ_LANGS+=( ia )
MOZ_LANGS+=( km )
MOZ_LANGS+=( kn )
MOZ_LANGS+=( lij )
MOZ_LANGS+=( mk )
MOZ_LANGS+=( mr )
MOZ_LANGS+=( my )
MOZ_LANGS+=( ne-NP )
MOZ_LANGS+=( oc )
MOZ_LANGS+=( sc )
MOZ_LANGS+=( sco )
MOZ_LANGS+=( si )
MOZ_LANGS+=( son )
MOZ_LANGS+=( szl )
MOZ_LANGS+=( ta )
MOZ_LANGS+=( te )
MOZ_LANGS+=( tl )
MOZ_LANGS+=( trs )
MOZ_LANGS+=( ur )
MOZ_LANGS+=( xh )

mozilla_set_globals() {
	# https://bugs.gentoo.org/587334
	local MOZ_TOO_REGIONALIZED_FOR_L10N
	MOZ_TOO_REGIONALIZED_FOR_L10N=(
		fy-NL ga-IE gu-IN hi-IN hy-AM nb-NO ne-NP nn-NO pa-IN sv-SE
	)

	local lang xflag
	# shellcheck disable=SC2068
	for lang in ${MOZ_LANGS[@]} ; do
		# en and en_US are handled internally
		if [[ "${lang}" == en ]] || [[ "${lang}" == en-US ]]; then
			continue
		fi

		# strip region subtag if $lang is in the list
		# shellcheck disable=SC2068
		if has "${lang}" "${MOZ_TOO_REGIONALIZED_FOR_L10N[@]}"; then
			xflag="${lang%%-*}"
		else
			xflag="${lang}"
		fi

		SRC_URI+=" l10n_${xflag/[_@]/-}? ("
		SRC_URI+=" ${MOZ_SRC_BASE_URI}/linux-x86_64/xpi/${lang}.xpi -> ${MOZ_P_DISTFILES}-${lang}.xpi"
		SRC_URI+=" )"
		IUSE+=" l10n_${xflag/[_@]/-}"
	done
}
mozilla_set_globals

moz_clear_vendor_checksums() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -ne 1 ]]; then
		die "${FUNCNAME[0]} requires exact one argument"
	fi

	einfo "Clearing cargo checksums for ${1} ..."

	# shellcheck disable=SC2154
	sed -i \
		-e 's/\("files":{\)[^}]*/\1/' \
		"${S}/third_party/rust/${1}/.cargo-checksum.json" \
		|| die "sed failed"
}

moz_install_xpi() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -lt 2 ]]; then
		die "${FUNCNAME[0]} requires at least two arguments"
	fi

	local DESTDIR
	DESTDIR="${1}"
	shift

	insinto "${DESTDIR}"

	local emid xpi_file xpi_tmp_dir
	# shellcheck disable=SC2068
	for xpi_file in ${@} ; do
		emid=
		xpi_tmp_dir="$(mktemp -d --tmpdir="${T}")"

		# Unpack XPI
		unzip -qq "${xpi_file}" -d "${xpi_tmp_dir}" || die

		# Determine extension ID
		if [[ -f "${xpi_tmp_dir}/install.rdf" ]]; then
			emid="$(
				sed -n \
					-e '/install-manifest/,$ { /em:id/!d; s/.*[\">]\([^\"<>]*\)[\"<].*/\1/; p; q }' \
					"${xpi_tmp_dir}/install.rdf" \
			)"
			[[ -z "${emid}" ]] && die "failed to determine extension id from install.rdf"
		elif [[ -f "${xpi_tmp_dir}/manifest.json" ]] ; then
			emid="$(sed -n -e 's/.*"id": "\([^"]*\)".*/\1/p' "${xpi_tmp_dir}/manifest.json")"
			[[ -z "${emid}" ]] && die "failed to determine extension id from manifest.json"
		else
			die "failed to determine extension id"
		fi

		einfo "Installing ${emid}.xpi into ${ED}${DESTDIR} ..."
		newins "${xpi_file}" "${emid}.xpi"
	done
}

mozconfig_add_options_ac() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -lt 2 ]]; then
		die "${FUNCNAME[0]} requires at least two arguments"
	fi

	local reason
	reason="${1}"
	shift

	local option
	# shellcheck disable=SC2068
	for option in ${@} ; do
		echo "ac_add_options ${option} # ${reason}" >>"${MOZCONFIG}"
	done
}

mozconfig_add_options_mk() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -lt 2 ]]; then
		die "${FUNCNAME[0]} requires at least two arguments"
	fi

	local reason
	reason="${1}"
	shift

	local option
	# shellcheck disable=SC2068
	for option in ${@} ; do
		echo "mk_add_options ${option} # ${reason}" >>"${MOZCONFIG}"
	done
}

mozconfig_use_enable() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -lt 1 ]]; then
		die "${FUNCNAME[0]} requires at least one arguments"
	fi

	local flag
	# shellcheck disable=SC2068
	flag="$(use_enable "${@}")"
	mozconfig_add_options_ac "$(use "${1}"&& echo +"${1}" || echo -"${1}")" "${flag}"
}

mozconfig_use_with() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	if [[ "${#}" -lt 1 ]]; then
		die "${FUNCNAME[0]} requires at least one arguments"
	fi

	local flag
	# shellcheck disable=SC2068
	flag="$(use_with "${@}")"
	mozconfig_add_options_ac "$(use "${1}"&& echo +"${1}" || echo -"${1}")" "${flag}"
}

# This is a straight copypaste from toolchain-funcs.eclass's 'tc-ld-is-lld', and is temporarily
# placed here until toolchain-funcs.eclass gets an official support for mold linker.
# Please see:
# https://github.com/gentoo/gentoo/pull/28366 ||
# https://github.com/gentoo/gentoo/pull/28355
# shellcheck disable=SC2120
tc-ld-is-mold() {
	local out

	# Ensure ld output is in English.
	local -x LC_ALL
	LC_ALL=C

	# First check the linker directly.
	out="$("$(tc-getLD "$@")" --version 2>&1)"
	if [[ "${out}" == *"mold"* ]]; then
		return 0
	fi

	# Then see if they're selecting mold via compiler flags.
	# Note: We're assuming they're using LDFLAGS to hold the
	# options and not CFLAGS/CXXFLAGS.
	local base
	base="${T}/test-tc-linker"
	cat <<-EOF > "${base}.c"
	int main() { return 0; }
	EOF
	out="$("$(tc-getCC "$@")" "${CFLAGS}" "${CPPFLAGS}" "${LDFLAGS}" -Wl,--version "${base}.c" -o "${base}" 2>&1)"
	rm -f "${base}"*
	if [[ "${out}" == *"mold"* ]]; then
		return 0
	fi

	# No mold here!
	return 1
}

virtwl() {
	debug-print-function "${FUNCNAME[0]}" "$@"

	[[ $# -lt 1 ]] && die "${FUNCNAME[0]} needs at least one argument"
	[[ -n $XDG_RUNTIME_DIR ]] || die "${FUNCNAME[0]} needs XDG_RUNTIME_DIR to be set; try xdg_environment_reset"
	tinywl -h >/dev/null || die 'tinywl -h failed'

	# TODO: don't run addpredict in utility function. WLR_RENDERER=pixman doesn't work
	addpredict /dev/dri
	local VIRTWL VIRTWL_PID
	# shellcheck disable=SC2016
	coproc VIRTWL { WLR_BACKENDS=headless exec tinywl -s 'echo $WAYLAND_DISPLAY; read  -r _; kill $PPID'; }
	local -x WAYLAND_DISPLAY
	read  -r WAYLAND_DISPLAY <&"${VIRTWL[0]}"

	# shellcheck disable=SC2145
	debug-print "${FUNCNAME[0]}: $@"
	"$@"
	local r
	r=$?

	[[ -n $VIRTWL_PID ]] || die "tinywl exited unexpectedly"
	# shellcheck disable=SC1083
	exec {VIRTWL[0]}<&- {VIRTWL[1]}>&-
	return $r
}

pkg_pretend() {
	if [[ "${MERGE_TYPE}" != binary ]]; then
		if use pgo; then
			# shellcheck disable=SC2086
			if ! has usersandbox $FEATURES; then
				die "You must enable usersandbox as X server can not run as root!"
			fi
		fi

		# Ensure we have enough disk space to compile
		if use pgo || use lto || use debug; then
			CHECKREQS_DISK_BUILD="13500M"
		else
			CHECKREQS_DISK_BUILD="6600M"
		fi

		check-reqs_pkg_pretend
	fi
}

pkg_setup() {
	if [[ "${MERGE_TYPE}" != binary ]]; then
		if use pgo; then
			# shellcheck disable=SC2086
			if ! has userpriv "${FEATURES}"; then
				eerror "Building ${PN} with USE=pgo and FEATURES=-userpriv is not supported!"
			fi
		fi

		# Ensure we have enough disk space to compile
		if use pgo || use lto || use debug; then
			CHECKREQS_DISK_BUILD="13500M"
		else
			CHECKREQS_DISK_BUILD="6400M"
		fi

		check-reqs_pkg_setup

		llvm_pkg_setup

		if use clang && use lto && tc-ld-is-lld; then
			local version_lld version_llvm_rust
			version_lld="$(ld.lld --version 2>/dev/null | awk '{ print $2 }')"
			[[ -n "${version_lld}" ]] && version_lld="$(ver_cut 1 "${version_lld}")"
			[[ -z "${version_lld}" ]] && die "Failed to read ld.lld version!"

		version_llvm_rust="$( rustc -vV 2>/dev/null \
				| awk '{
					if ($1 != "LLVM") next
					match($3, "^[[:digit:]]+")
					if (RSTART) {
						printf("%s\n", substr($3,RSTART,RLENGTH))
						exit
					}
				}'
			)"
		[[ -z "${version_llvm_rust}" ]] && die "Failed to read used LLVM version from rustc!"

			if ver_test "${version_lld}" -ne "${version_llvm_rust}"; then
				eerror "Rust is using LLVM version ${version_llvm_rust} but ld.lld version belongs to LLVM version ${version_lld}."
				eerror "You will be unable to link ${CATEGORY}/${PN}. To proceed you have the following options:"
				eerror " - Manually switch rust version using 'eselect rust' to match used LLVM version"
				eerror " - Switch to dev-lang/rust[system-llvm] which will guarantee matching version"
				eerror " - Build ${CATEGORY}/${PN} without USE=lto"
				eerror " - Rebuild lld with llvm that was used to build rust (may need to rebuild the whole "
				eerror " llvm/clang/lld/rust chain depending on your @world updates)"
				die "LLVM version used by Rust (${version_llvm_rust}) does not match with ld.lld version (${version_lld})!"
			fi
		fi

		python-any-r1_pkg_setup

		# Avoid PGO profiling problems due to enviroment leakage
		# These should *always* be cleaned up anyway
		unset \
			DBUS_SESSION_BUS_ADDRESS \
			DISPLAY \
			ORBIT_SOCKETDIR \
			SESSION_MANAGER \
			XAUTHORITY \
			XDG_CACHE_HOME \
			XDG_SESSION_COOKIE

		# Build system is using /proc/self/oom_score_adj, bug #604394
		addpredict /proc/self/oom_score_adj

		if use pgo; then
			# Update 105.0: "/proc/self/oom_score_adj" isn't enough anymore with pgo, but not sure
			# whether that's due to better OOM handling by Firefox (bmo#1771712), or portage
			# (PORTAGE_SCHEDULING_POLICY) update...
			addpredict /proc

			# May need a wider addpredict when using wayland+pgo.
			addpredict /dev/dri

			# Allow access to GPU during PGO run
			local ati_cards mesa_cards nvidia_cards render_cards
			shopt -s nullglob

			ati_cards="$(echo -n /dev/ati/card* | sed 's/ /:/g')"
			if [[ -n "${ati_cards}" ]]; then
				addpredict "${ati_cards}"
			fi

			mesa_cards="$(echo -n /dev/dri/card* | sed 's/ /:/g')"
			if [[ -n "${mesa_cards}" ]]; then
				addpredict "${mesa_cards}"
			fi

			nvidia_cards="$(echo -n /dev/nvidia* | sed 's/ /:/g')"
			if [[ -n "${nvidia_cards}" ]]; then
				addpredict "${nvidia_cards}"
			fi

			render_cards="$(echo -n /dev/dri/renderD128* | sed 's/ /:/g')"
			if [[ -n "${render_cards}" ]]; then
				addpredict "${render_cards}"
			fi

			shopt -u nullglob
		fi

		if ! mountpoint -q /dev/shm; then
			# If /dev/shm is not available, configure is known to fail with
			# a traceback report referencing /usr/lib/pythonN.N/multiprocessing/synchronize.py
			ewarn "/dev/shm is not mounted -- expect build failures!"
		fi

		# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
		# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
		# get your own set of keys.
		if [[ -z "${MOZ_API_KEY_GOOGLE+set}" ]]; then
			MOZ_API_KEY_GOOGLE="AIzaSyDEAOvatFogGaPi0eTgsV_ZlEzx0ObmepsMzfAc"
		fi

		if [[ -z "${MOZ_API_KEY_LOCATION+set}" ]]; then
			MOZ_API_KEY_LOCATION="AIzaSyB2h2OuRgGaPicUgy5N-5hsZqiPW6sH3n_rptiQ"
		fi

		# Mozilla API keys (see https://location.services.mozilla.com/api)
		# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
		# get your own set of keys.
		if [[ -z "${MOZ_API_KEY_MOZILLA+set}" ]]; then
			MOZ_API_KEY_MOZILLA="edb3d487-3a84-46m0ap1e3-9dfd-92b5efaaa005"
		fi

		# Ensure we use C locale when building, bug #746215
		export LC_ALL
		LC_ALL=C
	fi

	CONFIG_CHECK="~SECCOMP"
	WARNING_SECCOMP="CONFIG_SECCOMP not set! This system will be unable to play DRM-protected content."
	linux-info_pkg_setup
}

src_unpack() {
	local _lp_dir
	_lp_dir="${WORKDIR}/language_packs"
	local _src_file

	if [[ ! -d "${_lp_dir}" ]]; then
		mkdir "${_lp_dir}" || die
	fi

	for _src_file in ${A} ; do
		if [[ "${_src_file}" == *.xpi ]]; then
			# shellcheck disable=SC2153
			cp "${DISTDIR}/${_src_file}" "${_lp_dir}" || die "Failed to copy '${_src_file}' to '${_lp_dir}'!"
		else
			unpack "${_src_file}"
		fi
	done
}

src_prepare() {
	if use lto; then
		rm -v "${WORKDIR}/firefox-patches/"*-LTO-Only-enable-LTO-*.patch || die "rm failed"
	fi
	if use kde; then
		# OpenSUSE KDE integration patchset
		eapply "${WORKDIR}/${MOZ_KDE_PATCHSET}"
		# Uncomment the next line to enable KDE support debugging (additional console output)...
		#eapply "${FILESDIR}/${PN}-kde-debug.patch"
		# Uncomment the following patch line to force Plasma/Qt file dialog for Firefox...
		#eapply "${FILESDIR}/${PN}-force-qt-dialog.patch"
		# ... _OR_ install the patch file as a User patch (/etc/portage/patches/www-client/firefox/)
		# ... _OR_ add to your user .xinitrc: "xprop -root -f KDE_FULL_SESSION 8s -set KDE_FULL_SESSION true"
	fi

	if ! use ppc64; then
		rm -v "${WORKDIR}/firefox-patches/"*ppc64*.patch || die "rm failed"
	fi

	eapply "${WORKDIR}/firefox-patches"

	# Allow user to apply any additional patches without modifying ebuild
	eapply_user

	# Make cargo respect MAKEOPTS
	export CARGO_BUILD_JOBS
	CARGO_BUILD_JOBS="$(makeopts_jobs)"

	# Make LTO respect MAKEOPTS
	# shellcheck disable=SC2154
	sed -i \
		-e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}/build/moz.configure/lto-pgo.configure" \
		|| die "sed failed to set num_cores"

	# Make ICU respect MAKEOPTS
	# shellcheck disable=SC2154
	sed -i \
		-e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}/intl/icu_sources_data.py" \
		|| die "sed failed to set num_cores"

	# sed-in toolchain prefix
	# shellcheck disable=SC2154
	sed -i \
		-e "s/objdump/${CHOST}-objdump/" \
		"${S}/python/mozbuild/mozbuild/configure/check_debug_ranges.py" \
		|| die "sed failed to set toolchain prefix"

	# shellcheck disable=SC2154
	sed -i \
		-e 's/ccache_stats = None/return None/' \
		"${S}/python/mozbuild/mozbuild/controller/building.py" \
		|| die "sed failed to disable ccache stats call"

	einfo "Removing pre-built binaries ..."

	find "${S}/third_party" -type f \( -name '*.so' -o -name '*.o' \) -print -delete || die

	# Respect choice for "jumbo-build"
	# Changing the value for FILES_PER_UNIFIED_FILE may not work, see #905431
	if [[ -n "${FILES_PER_UNIFIED_FILE}" ]] && use jumbo-build; then
		local my_files_per_unified_file
		my_files_per_unified_file="${FILES_PER_UNIFIED_FILE:=16}"
		elog ""
		elog "jumbo-build defaults modified to ${my_files_per_unified_file}."
		elog "if you get a build failure, try undefining FILES_PER_UNIFIED_FILE,"
		elog "if that fails try -jumbo-build before opening a bug report."
		elog ""

		sed -i -e "s/\"FILES_PER_UNIFIED_FILE\", 16/\"FILES_PER_UNIFIED_FILE\", "${my_files_per_unified_file}/"" python/mozbuild/mozbuild/frontend/data.py ||
			die "Failed to adjust FILES_PER_UNIFIED_FILE in python/mozbuild/mozbuild/frontend/data.py"
		sed -i -e "s/FILES_PER_UNIFIED_FILE = 6/FILES_PER_UNIFIED_FILE = "${my_files_per_unified_file}/"" js/src/moz.build ||
			die "Failed to adjust FILES_PER_UNIFIED_FILE in js/src/moz.build"
	fi

	# Create build dir
	BUILD_DIR="${WORKDIR}/${PN}_build"
	mkdir -p "${BUILD_DIR}" || die

	# Write API keys to disk
	echo -n "${MOZ_API_KEY_GOOGLE//gGaPi/}" > "${S}/api-google.key" || die "echo failed"
	echo -n "${MOZ_API_KEY_LOCATION//gGaPi/}" > "${S}/api-location.key" || die "echo failed"
	echo -n "${MOZ_API_KEY_MOZILLA//m0ap1/}" > "${S}/api-mozilla.key" || die "echo failed"

	xdg_environment_reset
}

src_configure() {
	# Show flags set at the beginning
	einfo "Current BINDGEN_CFLAGS:\t${BINDGEN_CFLAGS:-no value set}"
	einfo "Current CFLAGS:\t\t${CFLAGS:-no value set}"
	einfo "Current CXXFLAGS:\t\t${CXXFLAGS:-no value set}"
	einfo "Current LDFLAGS:\t\t${LDFLAGS:-no value set}"
	einfo "Current RUSTFLAGS:\t\t${RUSTFLAGS:-no value set}"

	local have_switched_compiler
	have_switched_compiler=
	if use clang; then
		# Force clang
		einfo "Enforcing the use of clang due to USE=clang ..."

		local version_clang
		version_clang="$(clang --version 2>/dev/null | grep -F -- 'clang version' | awk '{ print $3 }')"
		[[ -n "${version_clang}" ]] && version_clang="$(ver_cut 1 "${version_clang}")"
		[[ -z "${version_clang}" ]] && die "Failed to read clang version!"

		if tc-is-gcc; then
			have_switched_compiler=yes
		fi

		AR=llvm-ar
		CC="${CHOST}-clang-${version_clang}"
		CXX="${CHOST}-clang++-${version_clang}"
		NM=llvm-nm
		RANLIB=llvm-ranlib
	elif ! use clang && ! tc-is-gcc ; then
		# Force gcc
		have_switched_compiler=yes
		einfo "Enforcing the use of gcc due to USE=-clang ..."
		AR=gcc-ar
		CC="${CHOST}-gcc"
		CXX="${CHOST}-g++"
		NM=gcc-nm
		RANLIB=gcc-ranlib
	fi

	if [[ -n "${have_switched_compiler}" ]]; then
		# Because we switched active compiler we have to ensure
		# that no unsupported flags are set
		strip-unsupported-flags
	fi

	# Ensure we use correct toolchain,
	# AS is used in a non-standard way by upstream, #bmo1654031
	HOST_CC="$(tc-getBUILD_CC)"
	export HOST_CC
	HOST_CXX="$(tc-getBUILD_CXX)"
	export HOST_CXX
	AS="$(tc-getCC) -c"
	export AS
	tc-export CC CXX LD AR AS NM OBJDUMP RANLIB PKG_CONFIG

	# Pass the correct toolchain paths through cbindgen
	if tc-is-cross-compiler; then
		BINDGEN_CFLAGS="${SYSROOT:+--sysroot=${ESYSROOT}} --target=${CHOST} ${BINDGEN_CFLAGS-}"
		export BINDGEN_CFLAGS
	fi

	# Set MOZILLA_FIVE_HOME
	MOZILLA_FIVE_HOME="/usr/$(get_libdir)/${PN}"
	export MOZILLA_FIVE_HOME

	# python/mach/mach/mixin/process.py fails to detect SHELL
	SHELL="${EPREFIX}/bin/bash"
	export SHELL

	# Set state path
	MOZBUILD_STATE_PATH="${BUILD_DIR}"
	export MOZBUILD_STATE_PATH

	# Set MOZCONFIG
	MOZCONFIG="${S}/.mozconfig"
	export MOZCONFIG

	# Initialize MOZCONFIG
	mozconfig_add_options_ac '' --enable-application=browser
	mozconfig_add_options_ac '' --enable-project=browser

	# Set Gentoo defaults
	if use telemetry; then
		MOZILLA_OFFICIAL=1
		export MOZILLA_OFFICIAL
	fi

	mozconfig_add_options_ac 'Gentoo default' \
		--allow-addon-sideload \
		--disable-cargo-incremental \
		--disable-crashreporter \
		--disable-gpsd \
		--disable-install-strip \
		--disable-legacy-profile-creation \
		--disable-parental-controls \
		--disable-strip \
		--disable-tests \
		--disable-updater \
		--disable-wmf \
		--enable-negotiateauth \
		--enable-new-pass-manager \
		--enable-official-branding \
		--enable-release \
		--enable-system-ffi \
		--enable-system-pixman \
		--enable-system-policies \
		--host="${CBUILD:-${CHOST}}" \
		--libdir="${EPREFIX}/usr/$(get_libdir)" \
		--prefix="${EPREFIX}/usr" \
		--target="${CHOST}" \
		--without-ccache \
		--without-wasm-sandboxed-libraries \
		--with-intl-api \
		--with-libclang-path="$(llvm-config --libdir)" \
		--with-system-nspr \
		--with-system-nss \
		--with-system-zlib \
		--with-toolchain-prefix="${CHOST}-" \
		--with-unsigned-addon-scopes=app,system \
		--x-includes="${ESYSROOT}/usr/include" \
		--x-libraries="${ESYSROOT}/usr/$(get_libdir)"

	# Set update channel
	local update_channel
	update_channel=release
	[[ -n "${MOZ_ESR}" ]] && update_channel=esr
	mozconfig_add_options_ac '' --update-channel="${update_channel}"

	local is_arch_simd_arch=1 is_rust_simd_supported=1
	use x86 || [[ "${CHOST}" == armv*h* ]] && is_arch_simd_arch=0
	has_version ">=virtual/rust-1.33.0"    && is_rust_simd_supported=0

	if (( is_arch_simd_arch && is_rust_simd_supported )); then
		mozconfig_add_options_ac '' --enable-rust-simd
	fi

	# For future keywording: This is currently (97.0) only supported on:
	# amd64, arm, arm64 & x86.
	# Might want to flip the logic around if Firefox is to support more arches.
	# bug 833001, bug 903411#c8
	if use ppc64 || use riscv; then
		mozconfig_add_options_ac '' --disable-sandbox
	elif use valgrind; then
		mozconfig_add_options_ac 'valgrind requirement' --disable-sandbox
	else
		mozconfig_add_options_ac '' --enable-sandbox
	fi

	# Enable JIT on riscv64 explicitly
	# Can be removed once upstream enable it by default in the future.
	use riscv && mozconfig_add_options_ac 'Enable JIT for RISC-V 64' --enable-jit

	if [[ -s "${S}/api-google.key" ]]; then
		local key_origin
		key_origin="Gentoo default"
		if [[ "$(md5sum <"${S}/api-google.key" | awk '{ print $1 }')" != 709560c02f94b41f9ad2c49207be6c54 ]]; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-google-safebrowsing-api-keyfile="${S}/api-google.key"
	else
		einfo "Building without Google API key ..."
	fi

	if [[ -s "${S}/api-location.key" ]]; then
		local key_origin
		key_origin="Gentoo default"
		if [[ "$(md5sum <"${S}/api-location.key" | awk '{ print $1 }')" != ffb7895e35dedf832eb1c5d420ac7420 ]]; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-google-location-service-api-keyfile="${S}/api-location.key"
	else
		einfo "Building without Location API key ..."
	fi

	if [[ -s "${S}/api-mozilla.key" ]]; then
		local key_origin
		key_origin="Gentoo default"
		if [[ "$(md5sum <"${S}/api-mozilla.key" | awk '{ print $1 }')" != 3927726e9442a8e8fa0e46ccc39caa27 ]]; then
			key_origin="User value"
		fi

		mozconfig_add_options_ac "${key_origin}" \
			--with-mozilla-api-keyfile="${S}/api-mozilla.key"
	else
		einfo "Building without Mozilla API key ..."
	fi

	mozconfig_use_with system-av1
	mozconfig_use_with system-harfbuzz
	mozconfig_use_with system-harfbuzz system-graphite2
	mozconfig_use_with system-icu
	mozconfig_use_with system-jpeg
	mozconfig_use_with system-libevent
	mozconfig_use_with system-libvpx
	mozconfig_use_with system-png
	mozconfig_use_with system-webp

	mozconfig_use_enable dbus
	mozconfig_use_enable libproxy
	mozconfig_use_enable valgrind

	use eme-free && mozconfig_add_options_ac '+eme-free' --disable-eme

	mozconfig_use_enable geckodriver

	if use hardened; then
		mozconfig_add_options_ac "+hardened" --enable-hardening
		append-ldflags "-Wl,-z,relro -Wl,-z,now"
	fi

	local myaudiobackends
	myaudiobackends=""
	use jack && myaudiobackends+="jack,"
	use sndio && myaudiobackends+="sndio,"
	use pulseaudio && myaudiobackends+="pulseaudio,"
	! use pulseaudio && myaudiobackends+="alsa,"

	mozconfig_add_options_ac '--enable-audio-backends' --enable-audio-backends="${myaudiobackends::-1}"

	mozconfig_use_enable wifi necko-wifi

	! use jumbo-build && mozconfig_add_options_ac '--disable-unified-build' --disable-unified-build

	if use X && use wayland; then
		mozconfig_add_options_ac '+x11+wayland' --enable-default-toolkit=cairo-gtk3-x11-wayland
	elif ! use X && use wayland ; then
		mozconfig_add_options_ac '+wayland' --enable-default-toolkit=cairo-gtk3-wayland-only
	else
		mozconfig_add_options_ac '+x11' --enable-default-toolkit=cairo-gtk3-x11-only
	fi

	if use lto; then
		if use clang; then
			# Upstream only supports lld or mold when using clang.
			# shellcheck disable=SC2119
			if tc-ld-is-mold; then
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "forcing ld=lld due to USE=clang and USE=lto" --enable-linker=lld
			fi

			mozconfig_add_options_ac '+lto' --enable-lto=cross

		else
			# ThinLTO is currently broken, see bmo#1644409.
			# mold does not support gcc+lto combination.
			mozconfig_add_options_ac '+lto' --enable-lto=full
			mozconfig_add_options_ac "linker is set to bfd" --enable-linker=bfd
		fi

		if use pgo; then
			mozconfig_add_options_ac '+pgo' MOZ_PGO=1

			if use clang; then
				# Used in build/pgo/profileserver.py
				LLVM_PROFDATA="llvm-profdata"
				export LLVM_PROFDATA
			fi
		fi
	else
		# Avoid auto-magic on linker
		if use clang; then
			# lld is upstream's default
			# shellcheck disable=SC2119
			if tc-ld-is-mold; then
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "forcing ld=lld due to USE=clang" --enable-linker=lld
			fi

		else
			# shellcheck disable=SC2119
			if tc-ld-is-mold; then
				mozconfig_add_options_ac "using ld=mold due to system selection" --enable-linker=mold
			else
				mozconfig_add_options_ac "linker is set to bfd due to USE=-clang" --enable-linker=bfd
			fi
		fi
	fi

	# LTO flag was handled via configure
	filter-lto

	mozconfig_use_enable debug
	if use debug; then
		mozconfig_add_options_ac '+debug' --disable-optimize
		mozconfig_add_options_ac '+debug' --enable-real-time-tracing
	else
		mozconfig_add_options_ac 'Gentoo defaults' --disable-real-time-tracing

		if is-flag '-g*'; then
			if use clang; then
				mozconfig_add_options_ac 'from CFLAGS' --enable-debug-symbols="$(get-flag '-g*')"
			else
				mozconfig_add_options_ac 'from CFLAGS' --enable-debug-symbols
			fi
		else
			mozconfig_add_options_ac 'Gentoo default' --disable-debug-symbols
		fi

		if is-flag '-O0'; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O0
		elif is-flag '-O4' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O4
		elif is-flag '-O3' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O3
		elif is-flag '-O1' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-O1
		elif is-flag '-Os' ; then
			mozconfig_add_options_ac "from CFLAGS" --enable-optimize=-Os
		else
			mozconfig_add_options_ac "Gentoo default" --enable-optimize=-O2
		fi
	fi

	# Debug flag was handled via configure
	filter-flags '-g*'

	# Optimization flag was handled via configure
	filter-flags '-O*'

	# Modifications to better support ARM, bug #553364
	if use cpu_flags_arm_neon; then
		mozconfig_add_options_ac '+cpu_flags_arm_neon' --with-fpu=neon

		if ! tc-is-clang; then
			# thumb options aren't supported when using clang, bug 666966
			mozconfig_add_options_ac '+cpu_flags_arm_neon' \
				--with-thumb=yes \
				--with-thumb-interwork=no
		fi
	fi

	if [[ "${CHOST}" == armv*h* ]]; then
		mozconfig_add_options_ac 'CHOST=armv*h*' --with-float-abi=hard

		if ! use system-libvpx; then
			# shellcheck disable=SC2154
			sed -i \
				-e "s|softfp|hard|" \
				"${S}/media/libvpx/moz.build" \
				|| die "sed failed"
		fi
	fi

	if use clang; then
		# https://bugzilla.mozilla.org/show_bug.cgi?id=1482204
		# https://bugzilla.mozilla.org/show_bug.cgi?id=1483822
		# toolkit/moz.configure Elfhack section: target.cpu in ('arm', 'x86', 'x86_64')
		local disable_elf_hack
		disable_elf_hack=
		if use amd64; then
			disable_elf_hack=yes
		elif use x86 ; then
			disable_elf_hack=yes
		elif use arm ; then
			disable_elf_hack=yes
		fi

		if [[ -n "${disable_elf_hack}" ]]; then
			mozconfig_add_options_ac 'elf-hack is broken when using Clang' --disable-elf-hack
		fi
	elif tc-is-gcc ; then
		if ver_test "$(gcc-fullversion)" -ge 10; then
			einfo "Forcing -fno-tree-loop-vectorize to workaround GCC bug, see bug 758446 ..."
			append-cxxflags -fno-tree-loop-vectorize
		fi
	fi

	if use elibc_musl && use arm64; then
		mozconfig_add_options_ac 'elf-hack is broken when using musl/arm64' --disable-elf-hack
	fi

	# Additional ARCH support
	case "${ARCH}" in
		arm)
			# Reduce the memory requirements for linking
			if use clang; then
				# Nothing to do
				:;
			elif use lto ; then
				append-ldflags -Wl,--no-keep-memory
			else
				append-ldflags -Wl,--no-keep-memory -Wl,--reduce-memory-overheads
			fi
			;;
	esac

	if ! use elibc_glibc; then
		mozconfig_add_options_ac '!elibc_glibc' --disable-jemalloc
	fi

	if use valgrind; then
		mozconfig_add_options_ac 'valgrind requirement' --disable-jemalloc
	fi

	# Allow elfhack to work in combination with unstripped binaries
	# when they would normally be larger than 2GiB.
	append-ldflags "-Wl,--compress-debug-sections=zlib"

	# Make revdep-rebuild.sh happy; Also required for musl
	append-ldflags -Wl,-rpath="${MOZILLA_FIVE_HOME}",--enable-new-dtags

	# Pass $MAKEOPTS to build system
	MOZ_MAKE_FLAGS="${MAKEOPTS}"
	export MOZ_MAKE_FLAGS

	# Use system's Python environment
	PIP_NETWORK_INSTALL_RESTRICTED_VIRTUALENVS=mach
	export PIP_NETWORK_INSTALL_RESTRICTED_VIRTUALENVS

	if use system-python-libs; then
		MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE="system"
		export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE
	else
		MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE="none"
		export MACH_BUILD_PYTHON_NATIVE_PACKAGE_SOURCE
	fi

	if ! use telemetry; then
		mozconfig_add_options_mk '-telemetry setting' "MOZ_CRASHREPORTER=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_DATA_REPORTING=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_SERVICES_HEALTHREPORT=0"
		mozconfig_add_options_mk '-telemetry setting' "MOZ_TELEMETRY_REPORTING=0"
	fi

	# Disable notification when build system has finished
	MOZ_NOSPAM=1
	export MOZ_NOSPAM

	# Portage sets XARGS environment variable to "xargs -r" by default which
	# breaks build system's check_prog() function which doesn't support arguments
	mozconfig_add_options_ac 'Gentoo default' "XARGS=${EPREFIX}/usr/bin/xargs"

	# Set build dir
	mozconfig_add_options_mk 'Gentoo default' "MOZ_OBJDIR=${BUILD_DIR}"

	# Show flags we will use
	einfo "Build BINDGEN_CFLAGS:\t${BINDGEN_CFLAGS:-no value set}"
	einfo "Build CFLAGS:\t\t${CFLAGS:-no value set}"
	einfo "Build CXXFLAGS:\t\t${CXXFLAGS:-no value set}"
	einfo "Build LDFLAGS:\t\t${LDFLAGS:-no value set}"
	einfo "Build RUSTFLAGS:\t\t${RUSTFLAGS:-no value set}"

	# Handle EXTRA_CONF and show summary
	local ac opt hash reason

	# Apply EXTRA_ECONF entries to $MOZCONFIG
	if [[ -n "${EXTRA_ECONF}" ]]; then
		# shellcheck disable=SC2086
		IFS=\! read  -r -a ac <<<"${EXTRA_ECONF// --/\!}"
		# shellcheck disable=SC2068
		for opt in "${ac[@]}"; do
			mozconfig_add_options_ac "EXTRA_ECONF" --"${opt#--}"
		done
	fi

	echo
	echo "=========================================================="
	echo "Building ${PF} with the following configuration"
	grep ^ac_add_options "${MOZCONFIG}" | while read  -r ac opt hash reason; do
		[[ -z "${hash}" || "${hash}" == \# ]] \
			|| die "error reading mozconfig: ${ac} ${opt} ${hash} ${reason}"
		printf " %-30s %s\n" "${opt}" "${reason:-mozilla.org default}"
	done
	echo "=========================================================="
	echo

	if use valgrind; then
		sed -i -e 's/--enable-optimize=-O[0-9s]/--enable-optimize="-g -O2"/' .mozconfig || die "sed failed"
	fi

	./mach configure || die "./mach failed"
}

src_compile() {
	local virtx_cmd
	virtx_cmd=

	if tc-ld-is-mold && use lto; then
		# increase ulimit with mold+lto, bugs #892641, #907485
		if ! ulimit -n 16384 1>/dev/null 2>&1; then
			ewarn "Unable to modify ulimits - building with mold+lto might fail due to low ulimit -n resources."
			ewarn "Please see bugs #892641 & #907485."
		else
			ulimit -n 16384
		fi
	fi

	if use pgo; then
		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		addpredict /root

		if ! use X; then
			virtx_cmd=virtwl
		else
			virtx_cmd=virtx
		fi
	fi

	if ! use X; then
		local -x GDK_BACKEND
		GDK_BACKEND=wayland
	else
		local -x GDK_BACKEND
		GDK_BACKEND=x11
	fi

	${virtx_cmd} ./mach build --verbose || die "./mach failed"
}

src_install() {
	# xpcshell is getting called during install
	pax-mark m \
		"${BUILD_DIR}/dist/bin/xpcshell" \
		"${BUILD_DIR}/dist/bin/${PN}" \
		"${BUILD_DIR}/dist/bin/plugin-container"

	DESTDIR="${D}" ./mach install || die "./mach failed"

	# Upstream cannot ship symlink but we can (bmo#658850)
	rm "${ED}${MOZILLA_FIVE_HOME}/${PN}-bin" || die "rm failed"
	dosym "${PN}" "${MOZILLA_FIVE_HOME}/${PN}-bin"

	# Don't install llvm-symbolizer from sys-devel/llvm package
	if [[ -f "${ED}${MOZILLA_FIVE_HOME}/llvm-symbolizer" ]]; then
		rm -v "${ED}${MOZILLA_FIVE_HOME}/llvm-symbolizer" || die "rm failed"
	fi

	# Install policy (currently only used to disable application updates)
	insinto "${MOZILLA_FIVE_HOME}/distribution"
	newins "${FILESDIR}/distribution.ini" distribution.ini
	newins "${FILESDIR}/disable-auto-update.policy.json" policies.json

	# Install system-wide preferences
	local PREFS_DIR
	PREFS_DIR="${MOZILLA_FIVE_HOME}/browser/defaults/preferences"
	insinto "${PREFS_DIR}"
	newins "${FILESDIR}/gentoo-default-prefs.js" gentoo-prefs.js

	local GENTOO_PREFS
	GENTOO_PREFS="${ED}${PREFS_DIR}/gentoo-prefs.js"

	# Set dictionary path to use system hunspell
	cat >>"${GENTOO_PREFS}" <<-EOF || die "failed to set spellchecker.dictionary_path pref"
	pref("spellchecker.dictionary_path", "${EPREFIX}/usr/share/myspell");
	EOF

	# Force hwaccel prefs if USE=hwaccel is enabled
	if use hwaccel; then
		cat "${FILESDIR}/gentoo-hwaccel-prefs.js-r2" \
		>>"${GENTOO_PREFS}" \
		|| die "failed to add prefs to force hardware-accelerated rendering to all-gentoo.js"

		if use wayland; then
			cat >>"${GENTOO_PREFS}" <<-EOF || die "failed to set hwaccel wayland prefs"
			pref("gfx.x11-egl.force-enabled", false);
			EOF
		else
			cat >>"${GENTOO_PREFS}" <<-EOF || die "failed to set hwaccel x11 prefs"
			pref("gfx.x11-egl.force-enabled", true);
			EOF
		fi
	fi

	if ! use gmp-autoupdate; then
		# shellcheck disable=SC2068
		for plugin in ${MOZ_GMP_PLUGIN_LIST[@]} ; do
			einfo "Disabling auto-update for ${plugin} plugin ..."
			cat >>"${GENTOO_PREFS}" <<-EOF || die "failed to disable autoupdate for ${plugin} media plugin"
			pref("media.${plugin}.autoupdate", false);
			EOF
		done
	fi

	# Force the graphite pref if USE=system-harfbuzz is enabled, since the pref cannot disable it
	if use system-harfbuzz; then
		cat >>"${GENTOO_PREFS}" <<-EOF || die "failed to set gfx.font_rendering.graphite.enabled pref"
		sticky_pref("gfx.font_rendering.graphite.enabled", true);
		EOF
	fi

	# Install language packs
	local langpacks
	langpacks=( "$(find "${WORKDIR}/language_packs" -type f -name '*.xpi')" )
	# shellcheck disable=SC2128
	if [[ -n "${langpacks}" ]]; then
		# shellcheck disable=SC2068
		moz_install_xpi "${MOZILLA_FIVE_HOME}/distribution/extensions" "${langpacks[@]}"
	fi

	# Install geckodriver
	if use geckodriver; then
		einfo "Installing geckodriver into ${ED}${MOZILLA_FIVE_HOME} ..."
		pax-mark m "${BUILD_DIR}/dist/bin/geckodriver"
		exeinto "${MOZILLA_FIVE_HOME}"
		doexe "${BUILD_DIR}/dist/bin/geckodriver"

		dosym "${MOZILLA_FIVE_HOME}/geckodriver" /usr/bin/geckodriver
	fi

	# Install icons
	local icon_srcdir
	icon_srcdir="${S}/browser/branding/official"
	local icon_symbolic_file
	icon_symbolic_file="${FILESDIR}/icon/firefox-symbolic.svg"

	insinto /usr/share/icons/hicolor/symbolic/apps
	newins "${icon_symbolic_file}" "${PN}-symbolic.svg"

	local icon size
	for icon in "${icon_srcdir}/default"*.png ; do
		size="${icon%.png}"
		size="${size##*/default}"

		if [[ "${size}" -eq 48 ]]; then
			newicon "${icon}" "${PN}.png"
		fi

		newicon -s "${size}" "${icon}" "${PN}.png"
	done

	# Install menu
	local app_name
	app_name="Mozilla ${MOZ_PN^}"
	local desktop_file
	desktop_file="${FILESDIR}/icon/${PN}-r3.desktop"
	local desktop_filename
	desktop_filename="${PN}.desktop"
	local exec_command
	exec_command="${PN}"
	local icon
	icon="${PN}"
	local use_wayland
	use_wayland="false"

	if use wayland; then
		use_wayland="true"
	fi

	cp "${desktop_file}" "${WORKDIR}/${PN}.desktop-template" || die "cp failed"

	# shellcheck disable=SC2154
	sed -i \
		-e "s:@NAME@:${app_name}:" \
		-e "s:@EXEC@:${exec_command}:" \
		-e "s:@ICON@:${icon}:" \
		"${WORKDIR}/${PN}.desktop-template" \
		|| die "sed failed"

	newmenu "${WORKDIR}/${PN}.desktop-template" "${desktop_filename}"

	rm "${WORKDIR}/${PN}.desktop-template" || die "rm failed"

	# Install wrapper script
	[[ -f "${ED}/usr/bin/${PN}" ]] && rm "${ED}/usr/bin/${PN}"
	newbin "${FILESDIR}/${PN}-r1.sh" "${PN}"

	# Update wrapper
	# shellcheck disable=SC2154
	sed -i \
		-e "s:@PREFIX@:${EPREFIX}/usr:" \
		-e "s:@MOZ_FIVE_HOME@:${MOZILLA_FIVE_HOME}:" \
		-e "s:@APULSELIB_DIR@:${apulselib}:" \
		-e "s:@DEFAULT_WAYLAND@:${use_wayland}:" \
		"${ED}/usr/bin/${PN}" \
		|| die "sed failed"
}

pkg_preinst() {
	xdg_pkg_preinst

	# If the apulse libs are available in MOZILLA_FIVE_HOME then apulse
	# does not need to be forced into the LD_LIBRARY_PATH
	if use pulseaudio && has_version ">=media-sound/apulse-0.1.12-r4"; then
		einfo "APULSE found; Generating library symlinks for sound support ..."
		local lib
		pushd "${ED}${MOZILLA_FIVE_HOME}" &>/dev/null || die "pushd failed"
		for lib in ../apulse/libpulse{.so{,.0},-simple.so{,.0}} ; do
			# A quickpkg rolled by hand will grab symlinks as part of the package,
			# so we need to avoid creating them if they already exist.
			if [[ ! -L "${lib##*/}" ]]; then
				ln -s "${lib}" "${lib##*/}" || die "ln failed"
			fi
		done
		popd &>/dev/null || die "popd failed"
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if ! use gmp-autoupdate; then
		elog "USE='-gmp-autoupdate' has disabled the following plugins from updating or"
		elog "installing into new profiles:"
		local plugin
		# shellcheck disable=SC2068
		for plugin in ${MOZ_GMP_PLUGIN_LIST[@]} ; do
			elog "\t ${plugin}"
		done
		elog
	fi

	if use pulseaudio && has_version ">=media-sound/apulse-0.1.12-r4"; then
		elog "Apulse was detected at merge time on this system and so it will always be"
		elog "used for sound. If you wish to use pulseaudio instead please unmerge"
		elog "media-sound/apulse."
		elog
	fi

	local show_doh_information
	local show_normandy_information
	local show_shortcut_information

	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		# New install; Tell user that DoH is disabled by default
		show_doh_information=yes
		show_normandy_information=yes
		show_shortcut_information=no
	else
		local replacing_version
		for replacing_version in ${REPLACING_VERSIONS} ; do
			if ver_test "${replacing_version}" -lt 91.0; then
				# Tell user that we no longer install a shortcut
				# per supported display protocol
				show_shortcut_information=yes
			fi
		done
	fi

	if [[ -n "${show_doh_information}" ]]; then
		elog
		elog "Note regarding Trusted Recursive Resolver aka DNS-over-HTTPS (DoH):"
		elog "Due to privacy concerns (encrypting DNS might be a good thing, sending all"
		elog "DNS traffic to Cloudflare by default is not a good idea and applications"
		elog "should respect OS configured settings), \"network.trr.mode\" was set to 5"
		elog "(\"Off by choice\") by default."
		elog "You can enable DNS-over-HTTPS in ${PN^}'s preferences."
	fi

	# bug 713782
	if [[ -n "${show_normandy_information}" ]]; then
		elog
		elog "Upstream operates a service named Normandy which allows Mozilla to"
		elog "push changes for default settings or even install new add-ons remotely."
		elog "While this can be useful to address problems like 'Armagadd-on 2.0' or"
		elog "revert previous decisions to disable TLS 1.0/1.1, privacy and security"
		elog "concerns prevail, which is why we have switched off the use of this"
		elog "service by default."
		elog
		elog "To re-enable this service set"
		elog
		elog " app.normandy.enabled=true"
		elog
		elog "in about:config."
	fi

	if [[ -n "${show_shortcut_information}" ]]; then
		elog
		elog "Since ${PN}-91.0 we no longer install multiple shortcuts for"
		elog "each supported display protocol. Instead we will only install"
		elog "one generic Mozilla ${PN^} shortcut."
		elog "If you still want to be able to select between running Mozilla ${PN^}"
		elog "on X11 or Wayland, you have to re-create these shortcuts on your own."
	fi

	# bug 835078
	if use hwaccel && has_version "x11-drivers/xf86-video-nouveau"; then
		ewarn "You have nouveau drivers installed in your system and 'hwaccel' "
		ewarn "enabled for Firefox. Nouveau / your GPU might not support the "
		ewarn "required EGL, so either disable 'hwaccel' or try the workaround "
		ewarn "explained in https://bugs.gentoo.org/835078#c5 if Firefox crashes."
	fi

	elog
	elog "Unfortunately Firefox-100.0 breaks compatibility with some sites using "
	elog "useragent checks. To temporarily fix this, enter about:config and modify "
	elog "network.http.useragent.forceVersion preference to \"99\"."
	elog "Or install an addon to change your useragent."
	elog "See: https://support.mozilla.org/en-US/kb/difficulties-opening-or-using-website-firefox-100"
	elog

	optfeature_header "Optional programs for extra features:"
	optfeature "desktop notifications" x11-libs/libnotify
	optfeature "fallback mouse cursor theme e.g. on WMs" gnome-base/gsettings-desktop-schemas

	if ! has_version "sys-libs/glibc"; then
		elog
		elog "glibc not found! You won't be able to play DRM content."
		elog "See Gentoo bug #910309 or upstream bug #1843683."
		elog
	fi
}
