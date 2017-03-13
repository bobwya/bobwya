# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

MY_PN="kwallet-pam"

inherit cmake-utils git-r3

DESCRIPTION="PAM integration to automatically unlock kwallet when logged into KDE4 Session"
HOMEPAGE="https://projects.kde.org/projects/kde/workspace/kwallet-pam"

EGIT_REPO_URI="git://anongit.kde.org/${MY_PN}"
EGIT3_STORE_DIR="${T}"
SRC_URI=""

LICENSE="GPL-2"
SLOT="4"
KEYWORDS=""
IUSE="debug"

RDEPEND=">=dev-libs/libgcrypt-1.5.0:*
		net-misc/socat
		sys-libs/pam"
DEPEND="${RDEPEND}"

src_configure() {
	if use debug ; then
		export CMAKE_BUILD_TYPE=Debug
	else
		export CMAKE_BUILD_TYPE=Release
	fi
	local mycmakeargs=( "-DKWALLET4=1"
						"-DCMAKE_INSTALL_LIBDIR=$(get_libdir)"
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	elog "${P} requires a initialised KDE4 kwallet, for you primary user, with the same password as your kdm login."
	elog ""
	elog "You will need need following additional pam options (for a stock KDE4 configuration)..."
	elog "  /etc/pam.d/passwd:"
	elog "-auth     optional  pam_kwallet.so kdehome=.kde4 # for ~/.kde4 user directory"
	elog "  /etc/pam.d/login:"
	elog "-session  optional  pam_kwallet.so auto_start"
	elog "  /etc/pam.d/kde:"
	elog "-auth     optional  pam_kwallet.so kdehome=.kde4 # for ~/.kde4 user directory"
	elog "-session  optional  pam_kwallet.so"
}
