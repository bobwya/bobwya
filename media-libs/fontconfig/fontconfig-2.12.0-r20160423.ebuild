# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools eutils multilib-minimal readme.gentoo-r1 versionator

DESCRIPTION="A library for configuring and customizing font access"
HOMEPAGE="http://fontconfig.org/"

SRC_URI="http://fontconfig.org/release/${P}.tar.bz2"
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

LICENSE="MIT"
SLOT="1.0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="doc infinality static-libs"

# Purposefully dropped the xml USE flag and libxml2 support.  Expat is the
# default and used by every distro.  See bug #283191.
RDEPEND="
	>=dev-libs/expat-2.1.0-r3[${MULTILIB_USEDEP}]
	=media-libs/freetype-2.6.3-${PR}[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( =app-text/docbook-sgml-dtd-3.1*
	app-text/docbook-sgml-utils[jadetex] )"
PDEPEND="
	!x86-winnt? ( app-eselect/eselect-fontconfig )
	virtual/ttf-fonts"

MULTILIB_CHOST_TOOLS=( /usr/bin/fc-cache )

pkg_setup() {
	DOC_CONTENTS=$(sed -e 's:${EROOT}:'"${EROOT}"':' "${FILESDIR}"/doc.txt)
}

src_prepare() {
	PATCHES=(
		"${FILESDIR}"/${PN}-2.10.2-docbook.patch # 310157
		"${FILESDIR}"/${PN}-2.11.93-latin-update.patch # 130466 + make liberation default
	)
	if use infinality; then
		PATCHES+=( "${WORKDIR}/${FCU_P}"/fontconfig_patches/{01,02,03,04,05}*.patch )
		cp -r "${WORKDIR}/${FCU_P}"/conf.d.infinality "${S}"/ || die "cp"
	fi
	default
	eautoreconf
}

multilib_src_configure() {
	local addfonts
	# harvest some font locations, such that users can benefit from the
	# host OS's installed fonts
	case ${CHOST} in
		*-darwin*)
			addfonts=",/Library/Fonts,/System/Library/Fonts"
		;;
		*-solaris*)
			[[ -d /usr/X/lib/X11/fonts/TrueType ]] && \
				addfonts=",/usr/X/lib/X11/fonts/TrueType"
			[[ -d /usr/X/lib/X11/fonts/Type1 ]] && \
				addfonts="${addfonts},/usr/X/lib/X11/fonts/Type1"
		;;
		*-linux-gnu)
			use prefix && [[ -d /usr/share/fonts ]] && \
				addfonts=",/usr/share/fonts"
		;;
	esac

	local myeconfargs=(
		$(use_enable doc docbook)
		--disable-docs
		--localstatedir="${EPREFIX}"/var
		--with-default-fonts="${EPREFIX}"/usr/share/fonts
		--with-add-fonts="${EPREFIX}/usr/local/share/fonts${addfonts}" \
		--with-templatedir="${EPREFIX}"/etc/fonts/conf.avail \
		$(usex infinality '--with-templateinfdir=/etc/fonts/conf.avail.infinality' '')
	)

	ECONF_SOURCE="${S}" \
	econf "${myeconfargs[@]}"
}

multilib_src_install() {
	default

	# avoid calling this multiple times, bug #459210
	if multilib_is_native_abi; then
		# stuff installed from build-dir
		emake -C doc DESTDIR="${D}" install-man

		insinto /etc/fonts
		doins fonts.conf
	fi
}

multilib_src_install_all() {
	einstalldocs
	prune_libtool_files --all

	# fc-lang directory contains language coverage datafiles
	# which are needed to test the coverage of fonts.
	insinto /usr/share/fc-lang
	doins fc-lang/*.orth

	dodoc doc/fontconfig-user.{txt,pdf}

	if [[ -e "${ED}"usr/share/doc/fontconfig/ ]];  then
		mv "${ED}"usr/share/doc/fontconfig/* "${ED}"/usr/share/doc/${P} || die "mv"
		rm -rf "${ED}"usr/share/doc/fontconfig || die "rm"
	fi

	# Changes should be made to /etc/fonts/local.conf, and as we had
	# too much problems with broken fonts.conf we force update it ...
	echo 'CONFIG_PROTECT_MASK="/etc/fonts/fonts.conf"' > "${T}"/37fontconfig || die "echo"
	doenvd "${T}"/37fontconfig

	# As of fontconfig 2.7, everything sticks their noses in here.
	dodir /etc/sandbox.d
	echo 'SANDBOX_PREDICT="/var/cache/fontconfig"' > "${ED}"/etc/sandbox.d/37fontconfig || die "echo"

	readme.gentoo_create_doc
}

pkg_preinst() {
	[[ ! -e "${EROOT}"/etc/fonts/conf.d ]] && return 0

	# Bug #193476
	# /etc/fonts/conf.d/ contains symlinks to ../conf.avail/ to include various
	# config files.  If we install as-is, we'll blow away user settings.
	ebegin "Syncing fontconfig configuration to system"
		for file in $(find "${EROOT}"/etc/fonts/conf.avail/ ! -type d -name "*.conf" -printf "%f "); do
			if [[ -L "${EROOT}"/etc/fonts/conf.d/"${file}" && -f "${ED}"etc/fonts/conf.avail/"${file}" ]]; then
				ln -sf ../conf.avail/"${file}" "${ED}"etc/fonts/conf.d/ &>/dev/null \
					|| die "ln ../conf.avail/${file} ${ED}etc/fonts/conf.d/"
			elif [[ -f ${ED}etc/fonts/conf.avail/"${file}" ]]; then
				rm -f "${ED}"etc/fonts/conf.d/"${file}" &>/dev/null \
					|| die "rm -f ${ED}etc/fonts/conf.d/${file}"
			fi
		done
	eend $? || die "Syncing fontconfig configuration: subshell failed"
}

pkg_postinst() {
	einfo "Cleaning broken symlinks in ${EROOT}etc/fonts/conf.d/"
	find -L "${EROOT}"etc/fonts/conf.d/ -type l -delete

	readme.gentoo_print_elog

	if [[ ${ROOT} = / ]]; then
		multilib_pkg_postinst() {
			ebegin "Creating global font cache for ${ABI}"
			"${EPREFIX}"/usr/bin/${CHOST}-fc-cache -srf || die "${CHOST}-fc-cache"
			eend $? || die "Creating global font cache for ${ABI}: subshell failed"
		}

		multilib_parallel_foreach_abi multilib_pkg_postinst
	fi
}
