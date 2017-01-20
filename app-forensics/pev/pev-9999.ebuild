# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/merces/${PN}.git
		   git://github.com/merces/${PN}.git"
	inherit git-r3
else
	case "${PV}" in
		0.80)	PE_GIT_COMMIT="71880441da80bbf38d3b0987e97dafe3e1258725";;
		*) 		die "Unsupported package version ($PV)";;
	esac
	SRC_URI="https://github.com/merces/${PN}/archive/v${PV}.tar.gz
			https://github.com/merces/libpe/archive/${PE_GIT_COMMIT}.zip -> libpe-${PE_GIT_COMMIT}.zip"
	KEYWORDS="~x86 ~amd64"
fi

DESCRIPTION="The PE file analysis toolkit"
HOMEPAGE="http://pev.sourceforge.net/"
LICENSE="GPL-2+"
SLOT="0"

DEPEND="dev-libs/openssl:0"
RDEPEND="${DEPEND}"

src_prepare() {
	if [[ ! -z "${PE_GIT_COMMIT}" ]]; then
		rsync -achu "${WORKDIR}/libpe-${PE_GIT_COMMIT}/" "${S}/lib/libpe/" \
			|| die "rsync failed"
	fi
	eapply_user
}