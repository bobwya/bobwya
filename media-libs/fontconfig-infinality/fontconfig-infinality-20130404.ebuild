# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit readme.gentoo-r1

DESCRIPTION="freetype configuration for infinality subpixel hinting"
HOMEPAGE="https://web.archive.org/web/20160216114305/http://www.infinality.net/blog/"
SRC_URI="https://dev.gentoo.org/~jstein/dist/${P}.tar.xz
	nyx? ( https://dev.gentoo.org/~jstein/dist/fontconfig-nyx-2.tar.xz )"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 x86"
IUSE="+nyx"

DEPEND=""
RDEPEND="
	app-eselect/eselect-fontconfig
	app-eselect/eselect-infinality
	app-eselect/eselect-lcdfilter
"
PDEPEND="
	media-libs/freetype:2[infinality]
	>=x11-libs/libXft-2.3.0
	nyx? ( media-fonts/croscorefonts )
"

get_doc_contents() {
	printf "%s\\n%s\\n%s\\n%s\\n%s\\n" \
		"Use eselect fontconfig enable 52-infinality.conf to enable the" \
		"configuration. Then use eselect infinality to set your fontconfig style and" \
		"eselect lcdfilter to set freetype variables. If you run into trouble with" \
		"applications not being able to find Type-1 fonts, then comment out the" \
		"relevant lines in ${EPREFIX}/etc/fonts/infinality/infinality.conf"
}

src_configure() {
	:
}

src_compile() {
	:
}

src_install() {
	DOC_CONTENTS="$(get_doc_contents)"

	dodoc infinality/{CHANGELOG,CHANGELOG.pre_git,README}
	readme.gentoo_create_doc

	insinto "/etc/fonts/conf.avail"
	doins "conf.avail/52-infinality.conf"

	insinto "/etc/fonts/infinality"
	doins -r "infinality"/{conf.src,styles.conf.avail,infinality.conf}

	insinto "/etc/X11/"
	doins "${FILESDIR}/Xresources"

	if use nyx; then
		insinto "/etc/fonts/infinality/styles.conf.avail"
		doins -r "${WORKDIR}/nyx"
	fi
}
