# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
VIRTUALX_REQUIRED="pgo"
WANT_AUTOCONF="2.1"
MOZ_ESR=""

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
# Excluding cak, dsb, ff, gn, lij as they arent on the gentoo list
MOZ_LANGS=( ach af an ar as ast az be bg bn-BD bn-IN br bs ca cs cy da de
el en en-GB en-US en-ZA eo es-AR es-CL es-ES es-MX et eu fa fi fr fy-NL
ga-IE gd gl gu-IN he hi-IN hr hsb hu hy-AM id is it ja kk km kn ko lt
lv mai mk ml mr ms nb-NO nl nn-NO or pa-IN pl pt-BR pt-PT rm ro ru si sk sl
son sq sr sv-SE ta te th tr uk uz vi xh zh-CN zh-TW )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PN="firefox"
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PV="${MOZ_PV/_beta/b}" # Handle beta for SRC_URI
MOZ_PV="${MOZ_PV/_rc/rc}" # Handle rc for SRC_URI

if [[ ${MOZ_ESR} == 1 ]]; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

# Patch version
PATCH="${MOZ_PN}-48.0-patches-01"
MOZ_HTTP_URI="https://archive.mozilla.org/pub/${MOZ_PN}/releases"

# Mercurial repository for Mozilla Firefox patches to provide better KDE Integration (developed by Wolfgang Rosenauer for OpenSUSE)
EHG_REPO_URI="http://www.rosenauer.org/hg/mozilla"

#MOZCONFIG_OPTIONAL_QT5=1 -- fails to build so leave it off until the code can be patched
MOZCONFIG_OPTIONAL_GTK2ONLY=1
MOZCONFIG_OPTIONAL_WIFI=1
MOZCONFIG_OPTIONAL_JIT="enabled"

inherit check-reqs flag-o-matic toolchain-funcs eutils gnome2-utils mozconfig-kde-v6.48 pax-utils fdo-mime autotools virtualx mozlinguas-kde-v2 mercurial

DESCRIPTION="Firefox Web Browser, with SUSE patchset, to provide better KDE integration"
HOMEPAGE="http://www.mozilla.com/firefox
	${EHG_REPO_URI}"

KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist hardened +hwaccel kde pgo selinux +gmp-autoupdate test"
RESTRICT="!bindist? ( bindist )"

PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/${PATCH}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/firefox-${MOZ_PV}.source.tar.xz
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

RDEPEND="
	>=dev-libs/nss-3.24
	>=dev-libs/nspr-4.12
	selinux? ( sec-policy/selinux-mozilla )
	kde? ( kde-misc/kmozillahelper:*  )
	!!www-client/firefox"

DEPEND="${RDEPEND}
	pgo? ( >=sys-devel/gcc-4.5 )
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"

S="${WORKDIR}/firefox-${MOZ_PV}"

QA_PRESTRIPPED="usr/lib*/${MOZ_PN}/firefox"

BUILD_OBJ_DIR="${S}/ff"
MAX_OBJ_DIR_LEN="80"

pkg_setup() {
	moz_pkgsetup

	# Avoid PGO profiling problems due to enviroment leakage
	# These should *always* be cleaned up anyway
	unset DBUS_SESSION_BUS_ADDRESS \
		DISPLAY \
		ORBIT_SOCKETDIR \
		SESSION_MANAGER \
		XDG_SESSION_COOKIE \
		XAUTHORITY

	if ! use bindist; then
		einfo
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation"
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag"
	fi

	if use pgo; then
		einfo
		ewarn "You will do a double build for profile guided optimization."
		ewarn "This will result in your build taking at least twice as long as before."
	fi
}

pkg_pretend() {
	if [[ ${#BUILD_OBJ_DIR} -gt ${MAX_OBJ_DIR_LEN} ]]; then
		ewarn "Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:"
		ewarn " ... \"${BUILD_OBJ_DIR}\""
	fi
	# Ensure we have enough disk space to compile
	if use pgo || use debug || use test; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi
	check-reqs_pkg_setup
}

src_unpack() {
	default

	# Unpack language packs
	mozlinguas_kde_src_unpack
	if use kde; then
		if [[ ${MOZ_PV} =~ ^\(10|17|24\)\..*esr$ ]]; then
			EHG_REVISION="esr${MOZ_PV%%.*}"
		else
			EHG_REVISION="firefox${MOZ_PV%%.*}"
		fi
		KDE_PATCHSET="firefox-kde-patchset"
		EHG_CHECKOUT_DIR="${WORKDIR}/${KDE_PATCHSET}"
		mercurial_fetch "${EHG_REPO_URI}" "${KDE_PATCHSET}"
	fi
}

src_prepare() {
	# Default to our patchset
	local PATCHES=( "${WORKDIR}/firefox" )
	if use kde; then
		# Gecko/toolkit OpenSUSE KDE integration patchset
		if [[ $(get_major_version) -lt 42 ]]; then
			PATCHES+=( "${EHG_CHECKOUT_DIR}/toolkit-download-folder.patch" )
		fi
		PATCHES+=( "${EHG_CHECKOUT_DIR}/mozilla-kde.patch" )
		PATCHES+=( "${EHG_CHECKOUT_DIR}/mozilla-language.patch" )
		PATCHES+=( "${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch" )
		if [[ $(get_major_version) -lt 39 ]]; then
			PATCHES+=( "${EHG_CHECKOUT_DIR}/mozilla-prefer_plugin_pref.patch" )
		fi
		# Firefox OpenSUSE KDE integration patchset
		PATCHES+=( "${EHG_CHECKOUT_DIR}/firefox-branded-icons.patch" )
		PATCHES+=( "${EHG_CHECKOUT_DIR}/firefox-kde.patch" )
		PATCHES+=( "${EHG_CHECKOUT_DIR}/firefox-no-default-ualocale.patch" )
		# Uncomment the next line to enable KDE support debugging (additional console output)...
		#PATCHES+=( "${FILESDIR}/firefox-kde-opensuse-kde-debug.patch" )
		# Uncomment the following patch line to force Plasma/Qt file dialog for Firefox...
		#PATCHES+=( "${FILESDIR}/firefox-kde-opensuse-force-qt-dialog.patch" )
		# ... _OR_ install the patch file as a User patch (/etc/portage/patches/www-client/firefox-kde-opensuse/)
		# ... _OR_ add to your user .xinitrc: "xprop -root -f KDE_FULL_SESSION 8s -set KDE_FULL_SESSION true"
	fi
	PATCHES+=( "${FILESDIR}/${PN}-48.0-pgo.patch" )

	if ! tc-ld-is-gold && has_version ">=sys-devel/binutils-2.26"; then
		PATCHES+=( "${FILESDIR}/xpcom-components-binutils-26.patch" )
	fi

	# Enable gnomebreakpad
	if use debug; then
		sed -i -e "s:GNOME_DISABLE_CRASH_DIALOG=1:GNOME_DISABLE_CRASH_DIALOG=0:g" \
			"${S}"/build/unix/run-mozilla.sh || die "sed failed!"
	fi

	# Ensure that our plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 64bit!"

	# Fix sandbox violations during make clean, bug 372817
	sed -e "s:\(/no-such-file\):${T}\1:g" \
		-i "${S}"/config/rules.mk \
		-i "${S}"/nsprpub/configure{.in,} \
		|| die "sed failed"

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/browser/installer/Makefile.in || die "sed failed"

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die "sed failed"

	# Keep codebase the same even if not using official branding
	sed '/^MOZ_DEV_EDITION=1/d' \
		-i "${S}"/browser/branding/aurora/configure.sh || die "sed failed"

	default

	# Autotools configure is now called old-configure.in
	# This works because there is still a configure.in that happens to be for the
	# shell wrapper configure script
	eautoreconf old-configure.in

	# Must run autoconf in js/src
	cd "${S}"/js/src || die "cd failed"
	eautoconf old-configure.in

	# Need to update jemalloc's configure
	cd "${S}"/memory/jemalloc/src || die "cd failed"
	WANT_AUTOCONF= eautoconf
}

src_configure() {
	MEXTENSIONS="default"
	# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
	# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
	# get your own set of keys.
	_google_api_key=AIzaSyDEAOvatFo0eTgsV_ZlEzx0ObmepsMzfAc

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	mozconfig_config

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,relro,-z,now"

	# Only available on mozilla-overlay for experimentation -- Removed in Gentoo repo per bug 571180
	#use egl && mozconfig_annotate 'Enable EGL as GL provider' --with-gl-provider=EGL

	# Setup api key for location services
	echo -n "${_google_api_key}" > "${S}"/google-api-key
	mozconfig_annotate '' --with-google-api-keyfile="${S}/google-api-key"

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"

	# Allow for a proper pgo build
	if use pgo; then
		echo "mk_add_options PROFILE_GEN_SCRIPT='EXTRA_TEST_ARGS=10 \$(MAKE) -C \$(MOZ_OBJDIR) pgo-profile-run'" >> "${S}"/.mozconfig
	fi

	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}"/.mozconfig

	# Finalize and report settings
	mozconfig_final

	if [[ $(gcc-major-version) -lt 4 ]]; then
		append-cxxflags -fno-stack-protector
	fi

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
	emake -f client.mk configure
}

src_compile() {
	if use pgo; then
		addpredict /root
		addpredict /etc/gconf
		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		# Firefox tries to use dri stuff when it's run, see bug 380283
		shopt -s nullglob
		cards=$(echo -n /dev/dri/card* | sed 's/ /:/g')
		if test -z "${cards}"; then
			cards=$(echo -n /dev/ati/card* /dev/nvidiactl* | sed 's/ /:/g')
			if test -n "${cards}"; then
				# Binary drivers seem to cause access violations anyway, so
				# let's use indirect rendering so that the device files aren't
				# touched at all. See bug 394715.
				export LIBGL_ALWAYS_INDIRECT=1
			fi
		fi
		shopt -u nullglob
		addpredict "${cards}"

		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		virtx emake -f client.mk profiledbuild || die "virtx emake failed"
	else
		MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX%/}/bin/bash}" \
		emake -f client.mk realbuild
	fi

}

src_install() {
	cd "${BUILD_OBJ_DIR}" || die "cd failed"

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Add our default prefs for firefox
	cp "${FILESDIR}"/gentoo-default-prefs.js-1 \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die "cp failed"

	mozconfig_install_prefs \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js"

	# Augment this with hwaccel prefs
	if use hwaccel; then
		cat "${FILESDIR}"/gentoo-hwaccel-prefs.js-1 >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die "cat failed"
	fi

	echo "pref(\"extensions.autoDisableScopes\", 3);" >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die "echo failed"

	local plugin
	use gmp-autoupdate || for plugin in \
	gmp-gmpopenh264 ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die "echo failed"
	done

	MOZ_MAKE_FLAGS="${MAKEOPTS}" \
	emake DESTDIR="${D}" install

	# Install language packs
	mozlinguas_kde_src_install

	local size sizes icon_path icon name
	if use bindist; then
		sizes="16 32 48"
		icon_path="${S}/browser/branding/aurora"
		# Firefox's new rapid release cycle means no more codenames
		# Let's just stick with this one...
		icon="aurora"
		name="Aurora"

		# Override preferences to set the MOZ_DEV_EDITION defaults, since we
		# don't define MOZ_DEV_EDITION to avoid profile debaucles.
		# (source: browser/app/profile/firefox.js)
		cat >>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" <<PROFILE_EOF
pref("app.feedback.baseURL", "https://input.mozilla.org/%LOCALE%/feedback/firefoxdev/%VERSION%/");
sticky_pref("lightweightThemes.selectedThemeID", "firefox-devedition@mozilla.org");
sticky_pref("browser.devedition.theme.enabled", true);
sticky_pref("devtools.theme", "dark");
PROFILE_EOF

	else
		sizes="16 22 24 32 256"
		icon_path="${S}/browser/branding/official"
		icon="${MOZ_PN}"
		name="Mozilla Firefox"
	fi

	# Install icons and .desktop for menu entry
	for size in ${sizes}; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# The 128x128 icon has a different name
	insinto "/usr/share/icons/hicolor/128x128/apps"
	newins "${icon_path}/mozicon128.png" "${icon}.png"
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/content/icon48.png" "${icon}.png"
	newmenu "${FILESDIR}/icon/${MOZ_PN}.desktop" "${MOZ_PN}.desktop"
	sed -i -e "s:@NAME@:${name}:" -e "s:@ICON@:${icon}:" \
		"${ED}/usr/share/applications/${MOZ_PN}.desktop" || die "sed failed"

	# Add StartupNotify=true bug 237317
	if use startup-notification; then
		echo "StartupNotify=true"\
			 >> "${ED}/usr/share/applications/${MOZ_PN}.desktop" \
			|| die "echo failed"
	fi

	# Required in order to use plugins and even run firefox on hardened, with jit useflag.
	if use jit; then
		pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/{firefox,firefox-bin,plugin-container}
	else
		pax-mark m "${ED}"${MOZILLA_FIVE_HOME}/plugin-container
	fi

	# very ugly hack to make firefox not sigbus on sparc
	# FIXME: is this still needed??
	use sparc && { sed -e 's/Firefox/FirefoxGentoo/g' \
					 -i "${ED}/${MOZILLA_FIVE_HOME}/application.ini" \
					|| die "sparc sed failed"; }
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	# Update mimedb for the new .desktop file
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
	if [[ $(get_major_version) -ge 40 ]]; then
		# See https://forums.gentoo.org/viewtopic-t-1028874.html
		ewarn "If you experience problems with your cursor theme - only when mousing over ${PN}."
		ewarn "See:"
		ewarn "  https://forums.gentoo.org/viewtopic-t-1028874.html"
		ewarn "  https://wiki.gentoo.org/wiki/Cursor_themes"
		ewarn "  https://wiki.archlinux.org/index.php/Cursor_themes"
		ewarn
	fi
	if [[ $(get_major_version) -ge 47 ]]; then
		einfo "To enable experimental Electrolysis (e10s) support for ${PN}..."
		einfo "  browse to: \"about:config\" page"
		einfo "  add entry: \"browser.tabs.remote.force-enable = true\""
		einfo
	fi
}

pkg_postrm() {
	gnome2_icon_cache_update
}
