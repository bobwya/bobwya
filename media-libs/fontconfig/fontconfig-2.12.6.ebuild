# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit flag-o-matic libtool multilib multilib-build multilib-minimal toolchain-funcs

FONTCONFIG_ULTIMATE_BASE="fontconfig-ultimate-git"
FONTCONFIG_ULTIMATE_COMMIT="820e74be8345a0da2cdcff0a05bf5fa10fd85740"
DESCRIPTION="A library for configuring and customizing font access"
HOMEPAGE="https://www.fontconfig.org/"
SRC_URI="
	http://fontconfig.org/release/${P}.tar.bz2
	infinality? ( https://raw.githubusercontent.com/archfan/infinality_bundle/${FONTCONFIG_ULTIMATE_COMMIT}/02_fontconfig-iu/${FONTCONFIG_ULTIMATE_BASE}.tar.bz2 )
"
LICENSE="|| ( FTL GPL-2+ )"
SLOT="1.0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~m68k ~mips ppc ppc64 s390 ~sh sparc x86 ~amd64-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~x86-winnt"
IUSE="doc +infinality static-libs"

# 283191
RDEPEND="
	>=dev-libs/expat-2.1.0-r3[${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.7.1[infinality?,${MULTILIB_USEDEP}]
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? (
		=app-text/docbook-sgml-dtd-3.1*
		app-text/docbook-sgml-utils[jadetex]
	)
"
PDEPEND="
	!x86-winnt? ( app-eselect/eselect-fontconfig )
	virtual/ttf-fonts
"

PATCHES=(
	"${FILESDIR}/${PN}-2.10.2-docbook.patch"      # 310157
	"${FILESDIR}/${PN}-2.12.3-latin-update.patch" # 130466 + make liberation default
)

MULTILIB_CHOST_TOOLS=( "/usr/bin/fc-cache$(get_exeext)" )

pkg_setup() {
	DOC_CONTENTS="Please make fontconfig configuration changes using
	\`eselect fontconfig\`. Any changes made to \"/etc/fonts/fonts.conf\" will be
	overwritten. If you need to reset your configuration to upstream defaults,
	delete the directory \"${EROOT}etc/fonts/conf.d/\" and re-emerge fontconfig."
}

src_prepare() {
	if use infinality; then
		PATCHES+=(
			"${FILESDIR}/${PN}-2.12.6-infinality_ultimate.patch"
		)
		rsync -ach --safe-links "${WORKDIR}/${FONTCONFIG_ULTIMATE_BASE}/conf.d.infinality" .
	fi
	default
	export GPERF
	GPERF="$(type -P true)"  # 631980 : avoid dependency on gperf
	sed -i -e 's/FC_GPERF_SIZE_T="unsigned int"/FC_GPERF_SIZE_T=size_t/' \
		"${S}/configure.ac" \
		|| die "sed failed" # 631920 : secondary gperf dependency fix
	eautoreconf
}

multilib_src_configure() {
	local addfonts fontdir
	case "${CHOST}" in
		*-darwin*)
			addfonts=",/Library/Fonts,/System/Library/Fonts"
		;;
		*-solaris*)
			for fontdir in "TrueType" "Type1"; do
				[[ -d "/usr/X/lib/X11/fonts/${fontdir}" ]] || continue

				addfonts="${addfonts},/usr/X/lib/X11/fonts/${fontdir}"
			done
		;;
		*-linux-gnu)
			if use prefix && [[ -d "/usr/share/fonts" ]]; then
				addfonts=",/usr/share/fonts"
			fi
		;;
	esac

	local -a myeconfargs=(
		"$(use_enable doc docbook)"
		"$(use_enable static-libs static)"
		"--enable-docs"
		"--localstatedir=${EPREFIX}/var"
		"--with-default-fonts=${EPREFIX}/usr/share/fonts"
		"--with-add-fonts=${EPREFIX}/usr/local/share/fonts${addfonts}"
		"--with-templatedir=${EPREFIX}/etc/fonts/conf.avail"
		"$(usex infinality '--with-templateinfdir=/etc/fonts/conf.avail.infinality' '')"
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install() {
	default

	# 459210
	if multilib_is_native_abi; then
		emake -C doc DESTDIR="${D}" install-man
		insinto "/etc/fonts"
		doins "fonts.conf"
	fi
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -name "*.la" -delete || die "find failed"

	insinto "/usr/share/fc-lang"
	doins "fc-lang"/*.orth

	local doc_dir="usr/share/doc/fontconfig"
	if [[ -e "${ED%/}/${doc_dir}" ]];  then
		mv "${ED%/}/${doc_dir}"/* "${ED%/}/${doc_dir}-${PV}" || die "mv failed"
		rm -rf "${ED%/}/${doc_dir:?}"
	fi

	# End-users should only alter / update: "/etc/fonts/local.conf"
	echo 'CONFIG_PROTECT_MASK="/etc/fonts/fonts.conf"' > "${T}/37fontconfig"
	doenvd "${T}/37fontconfig"

	# fix for >=media-libs/fontconfig-2.7
	dodir "/etc/sandbox.d"
	echo 'SANDBOX_PREDICT="/var/cache/fontconfig"' > "${ED%/}/etc/sandbox.d/37fontconfig"

	if use infinality; then
		insinto "/etc/fonts/conf.avail.infinality/"
		doins "${WORKDIR}/${FONTCONFIG_ULTIMATE_BASE}/conf.d.infinality"/*.conf
		doins "${WORKDIR}/${FONTCONFIG_ULTIMATE_BASE}/fontconfig_patches"/{ms,free,combi}/*.conf
	fi

	readme.gentoo_create_doc

	if [[ "${PV}" != 9999 ]] && use doc; then
		use infinality && dodoc -r "${WORKDIR}/${FONTCONFIG_ULTIMATE_BASE}/doc/"
		docinto html
		dodoc -r docs/*
	fi

	find "${ED}" -name '*.la' -delete || die "find failed"
	if ! use static-libs; then
		find "${ED}" -name '*.a' -delete || die "find failed"
	fi
}

pkg_preinst() {
	if [[ ! -e "${EROOT%/}/etc/fonts/conf.d" ]]; then
		return
	fi

	# 193476
	ebegin "Syncing fontconfig configuration to system"
		while IFS= read -r -d '' conf_file; do
			[[ -f "${ED%/}/etc/fonts/conf.avail/${conf_file}" ]] || continue

			if [[ -L "${EROOT%/}/etc/fonts/conf.d/${conf_file}" ]]; then
				ln -sf ../"conf.avail/${conf_file}" "${ED%/}/etc/fonts/conf.d/" &>/dev/null
			else
				rm "${ED%/}/etc/fonts/conf.d/${conf_file}" &>/dev/null
			fi
		done < <(find "${EROOT%/}/etc/fonts/conf.avail" -mindepth 1 -type f -name "*.conf" -printf '%f\0' 2>/dev/null)
	eend $?
}

pkg_postinst() {
	einfo "Cleaning broken symlinks in \"${EROOT%/}/etc/fonts/conf.d/\""
	find -L "${EROOT%/}/etc/fonts/conf.d/" -type l -delete

	readme.gentoo_print_elog

	if [[ "${ROOT}" != "/" ]]; then
		return 0
	fi

	multilib_pkg_postinst() {
		ebegin "Creating global font cache for ${ABI}"
			"${EPREFIX}/usr/bin/${CHOST}-fc-cache" -srf
		eend $?
	}

	multilib_parallel_foreach_abi multilib_pkg_postinst
}
