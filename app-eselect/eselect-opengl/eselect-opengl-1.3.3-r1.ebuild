# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

inherit multilib

DESCRIPTION="Utility to change the OpenGL interface being used"
HOMEPAGE="https://www.gentoo.org/"

# Source:
# http://www.opengl.org/registry/api/glext.h
# http://www.opengl.org/registry/api/glxext.h
GLEXT="85"
GLXEXT="34"

SRC_URI="https://github.com/bobwya/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND=">=app-admin/eselect-1.2.4
		 >=media-libs/mesa-11.0.6-r1
		 >=x11-base/xorg-server-1.16.4-r6
		 !<x11-proto/glproto-1.4.17-r1
		 !<x11-drivers/ati-drivers-14.9-r2
		 !=x11-drivers/ati-drivers-14.12
		 !<=app-emulation/emul-linux-x86-opengl-20180508"

pkg_preinst() {
	# we may be moving the config file, so get it early
	old_gl_implementation=$(eselect opengl show)
}

pkg_postinst() {
	delete_opengl_symlinks() {
		path_exists "${EROOT}/usr/$(get_libdir)/opengl/" || return

		# delete broken symlinks
		find "${EROOT}/usr/$(get_libdir)/opengl/" -xtype l -delete
		# delete empty leftover directories (they confuse eselect)
		find "${EROOT}/usr/$(get_libdir)/opengl/" -depth -type d -empty -exec rmdir -v {} +
	}

	multilib_foreach_abi delete_opengl_symlinks

	if [[ -n "${old_gl_implementation}" && "${old_gl_implementation}" != '(none)' ]]; then
		eselect opengl set "${old_gl_implementation}"
	fi
	for conf_file in "etc/env.d/000opengl" "etc/X11/xorg.conf.d/20opengl.conf"; do
		[[ -f "${EROOT}/${conf_file}" ]] || continue

		rm -vf "${EROOT}/${conf_file}" || die "rm failed"
	done
	unset -v conf_file old_gl_implementation
}

src_prepare() {
	# don't die on Darwin users
	if [[ ${CHOST} == *-darwin* ]] ; then
		sed -i -e 's/libGL\.so/libGL.dylib/' opengl.eselect || die "sed failed"
	fi
	eapply_user
}

src_install() {
	insinto "/usr/share/eselect/modules"
	doins "opengl.eselect"
	doman "opengl.eselect.5"
}

pkg_postinst() {
	ewarn "This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues"
	ewarn "when switching GL providers."
	ewarn "This package can only be used in conjuction with patched versions of:"
	ewarn " * media-libs/mesa"
	ewarn " * x11-base/xorg-server"
	ewarn " * x11-drivers/nvidia-drivers"
	ewarn "from the bobwya overlay."
	einfo "Please refer to the manual page before first use:"
	einfo "  man opengl.eselect"
}
