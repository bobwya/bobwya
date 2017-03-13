# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit flag-o-matic multilib multilib-build multilib-minimal toolchain-funcs

DESCRIPTION="A high-quality and portable font engine"
HOMEPAGE="http://www.freetype.org/"
SRC_URI="mirror://sourceforge/freetype/${P/_/}.tar.bz2
	mirror://nongnu/freetype/${P/_/}.tar.bz2
	utils?	( mirror://sourceforge/freetype/ft2demos-${PV}.tar.bz2
		mirror://nongnu/freetype/ft2demos-${PV}.tar.bz2 )
	doc?	( mirror://sourceforge/freetype/${PN}-doc-${PV}.tar.bz2
		mirror://nongnu/freetype/${PN}-doc-${PV}.tar.bz2 )"
FCU_PN="fontconfig-ultimate"
FCU_P="${FCU_PN}"
if [[ "${PR}" == "99999999" ]]; then
	EGIT_REPO_URI="https://github.com/bohoomil/${PN}.git"
	EGIT3_STORE_DIR="${WORKDIR}/${FCU_PN}"
	inherit git-r3
else
	FCU_PV="${PR:1:4}-${PR:5:2}-${PR:7:2}"
	FCU_P="${FCU_PN}-${FCU_PV}"
	SRC_URI="${SRC_URI}
		https://github.com/bohoomil/${FCU_PN}/archive/${FCU_PV}.tar.gz -> ${FCU_P}.tar.gz"
fi

LICENSE="|| ( FTL GPL-2+ )"
SLOT="2"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="X +adobe-cff bindist bzip2 debug doc fontforge harfbuzz infinality png static-libs utils"
RESTRICT="!bindist? ( bindist )" # bug 541408

CDEPEND="
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[${MULTILIB_USEDEP}] )
	harfbuzz? ( >=media-libs/harfbuzz-0.9.19[truetype,${MULTILIB_USEDEP}] )
	png? ( >=media-libs/libpng-1.2.51:=[${MULTILIB_USEDEP}] )
	utils? (
		X? (
			>=x11-libs/libX11-1.6.2[${MULTILIB_USEDEP}]
			>=x11-libs/libXau-1.0.7-r1[${MULTILIB_USEDEP}]
			>=x11-libs/libXdmcp-1.1.1-r1[${MULTILIB_USEDEP}]
		)
	)"
DEPEND="${CDEPEND}
	virtual/pkgconfig"
RDEPEND="${CDEPEND}"
PDEPEND="infinality? ( media-libs/fontconfig-infinality )"

src_prepare() {
	enable_option() {
		sed -i -e 's:^.*\(#define[ ^I]*'"${1}"'\).*$:\1:' \
			"${S}/include/${PN}"/config/ftoption.h \
			|| die "sed: unable to enable option ${1}"
	}

	disable_option() {
		sed -i -e 's:^.*\(#define[ ^I]*'"${1}"'\).*$:/* \1 */:' \
			"${S}/include/${PN}"/config/ftoption.h \
			|| die "sed: unable to disable option ${1}"
	}

	PATCHES=(
		"${FILESDIR}"/${PN}-2.4.11-sizeof-types.patch # 459966
		"${WORKDIR}/${FCU_P}/${PN}"/01-*.patch
	)
	default

	if use infinality; then
		eapply "${WORKDIR}/${FCU_P}/${PN}"/{02,03}-*.patch
		# FT_CONFIG_OPTION_SUBPIXEL_RENDERING is already enabled in freetype-2.4.11
		enable_option TT_CONFIG_OPTION_SUBPIXEL_HINTING
	fi

	if ! use bindist; then
		# See http://freetype.org/patents.html
		# ClearType is covered by several Microsoft patents in the US
		enable_option FT_CONFIG_OPTION_SUBPIXEL_RENDERING
	fi

	if ! use adobe-cff; then
		enable_option CFF_CONFIG_OPTION_OLD_ENGINE
	fi

	if use debug; then
		enable_option FT_DEBUG_LEVEL_TRACE
		enable_option FT_DEBUG_MEMORY
	fi

	if use utils; then
		pushd "${WORKDIR}/ft2demos-${PV}" || die "pushd"
		# Disable tests needing X11 when USE="-X". (bug #177597)
		if ! use X; then
			sed -i -e "/EXES\ +=\ ftdiff/ s:^:#:" Makefile || die "sed"
		fi
		popd || die "popd"
	fi

	if [[ -n "${CONFIG_SHELL}" ]] ; then
		sed -i -e '1s:^#![[:space:]]*/bin/sh:#!'"${CONFIG_SHELL}"':' \
			"${S}"/builds/unix/configure || die "sed"
	fi

	elibtoolize --patch-only
}

multilib_src_configure() {
	append-flags -fno-strict-aliasing
	type -P gmake &> /dev/null && export GNUMAKE=gmake

	local myeconfargs=(
		--enable-biarch-config
		--enable-shared
		$(use_with bzip2)
		$(use_with harfbuzz)
		$(use_with png)
		$(use_enable static-libs static)

		# avoid using libpng-config
		LIBPNG_CFLAGS="$($(tc-getPKG_CONFIG) --cflags libpng)"
		LIBPNG_LDFLAGS="$($(tc-getPKG_CONFIG) --libs libpng)"
	)

	ECONF_SOURCE="${S}" \
		econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	default

	if multilib_is_native_abi && use utils; then
		einfo "Building utils"
		# fix for Prefix, bug #339334
		emake \
			X11_PATH="${EPREFIX}/usr/$(get_libdir)" \
			FT2DEMOS=1 TOP_DIR_2="${WORKDIR}/ft2demos-${PV}"
	fi
}

multilib_src_install() {
	default

	if multilib_is_native_abi && use utils; then
		einfo "Installing utils"
		rm "${WORKDIR}"/ft2demos-${PV}/bin/README || die "rm"
		local ft2demo
		for ft2demo in ../ft2demos-${PV}/bin/*; do
			./libtool --mode=install $(type -P install) -m 755 "$ft2demo" \
				"${ED}"/usr/bin || die "ftdemo failed to install: ${ftdemo}"
		done
	fi
}

multilib_src_install_all() {
	if use fontforge; then
		# Probably fontforge needs less but this way makes things simplier...
		einfo "Installing internal headers required for fontforge"
		local header
		while read header; do
			mkdir -p "${ED}/usr/include/freetype2/internal4fontforge/$(dirname ${header})" || die "mkdir"
			cp ${header} "${ED}/usr/include/freetype2/internal4fontforge/$(dirname ${header})" || die "cp"
		done < <(find "${S}"/src/truetype "${S}"/include/freetype/internal -type f -name '*.h' || die "find")
	fi

	if use infinality; then
		exeinto /etc/X11/xinit/xinitrc.d/
		doexe "${WORKDIR}/${FCU_P}/${PN}"/{infinality-settings.sh,xft-settings.sh}
	fi

	dodoc docs/{CHANGES,CUSTOMIZE,DEBUG,INSTALL.UNIX,*.txt,PROBLEMS,TODO}
	if use doc ; then
		docinto html
		dodoc -r docs/*
	fi

	prune_libtool_files --all
}
