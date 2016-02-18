# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils multilib

DESCRIPTION="Utility to change the OpenGL interface being used"
HOMEPAGE="https://www.gentoo.org/"

# Source:
# http://www.opengl.org/registry/api/glext.h
# http://www.opengl.org/registry/api/glxext.h
GLEXT="85"
GLXEXT="34"

SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND=">=app-admin/eselect-1.2.4
		 >=media-libs/mesa-11.0.6-r1
		 >=x11-base/xorg-server-1.16.4-r6
		 !<x11-proto/glproto-1.4.17-r1
		 !<x11-drivers/ati-drivers-14.9-r2
		 !=x11-drivers/ati-drivers-14.12
		 !<=app-emulation/emul-linux-x86-opengl-20140508"

S="${WORKDIR}"

pkg_preinst() {
	# we may be moving the config file, so get it early
	OLD_IMPLEMENTATION=$(eselect opengl show)
}

pkg_postinst() {
	if path_exists "${EROOT}"/usr/lib*/opengl; then
		# delete broken symlinks
		find "${EROOT}"/usr/lib*/opengl -xtype l -delete
		# delete empty leftover directories (they confuse eselect)
		find "${EROOT}"/usr/lib*/opengl -depth -type d -empty -exec rmdir -v {} +
	fi

	if [[ -n "${OLD_IMPLEMENTATION}" && "${OLD_IMPLEMENTATION}" != '(none)' ]] ; then
		eselect opengl set "${OLD_IMPLEMENTATION}"
	fi
	[[ -f "${EROOT}"/etc/env.d/03opengl ]] && rm -vf "${EROOT}"/etc/env.d/03opengl
	[[ -f "${EROOT}"/etc/X11/xorg.conf.d/20opengl.conf ]] && rm -vf "${EROOT}"/etc/X11/xorg.conf.d/20opengl.conf
}

src_prepare() {
	# don't die on Darwin users
	if [[ ${CHOST} == *-darwin* ]] ; then
		sed -i -e 's/libGL\.so/libGL.dylib/' opengl.eselect || die
	fi
}

src_install() {
	insinto "/usr/share/eselect/modules"
	newins "${FILESDIR}/opengl.eselect-${PV}" opengl.eselect
}

pkg_postinst() {
	ewarn "This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues"
	ewarn "when switching GL providers."
	ewarn "This package can only be used in conjuction with patched versions of:"
	ewarn " * media-libs/mesa"
	ewarn " * app-select/eselect-opengl"
	ewarn " * x11-base/xorg-server"
	ewarn "from the bobwya overlay."
	ewarn ""
	ewarn "Please ensure you cleanup the /usr/lib{32,64}/ lib*GL* symlinks, using:"
	ewarn "  eselect opengl cleanup"
	ewarn "... before reverting back to the mainline Gentoo implementation of this package"
}
