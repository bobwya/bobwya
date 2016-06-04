# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils bash-completion-r1 versionator

DESCRIPTION="Phoronix's comprehensive, cross-platform testing and benchmark suite"
HOMEPAGE="http://www.phoronix-test-suite.com"
SRC_URI=""

LICENSE="GPL-3"
SLOT="0"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	EGIT3_STORE_DIR="${T}"
	inherit git-r3
	SRC_URI=""
	KEYWORDS=""
else
	MY_MAJORV="$(get_version_component_range 1-3)"
	MY_P="${PN}-${MY_MAJORV}"
	if [ -z "$(get_version_component_range 4)" ]; then
		KEYWORDS="~amd64 ~x86"
		SRC_URI="http://www.phoronix-test-suite.com/download.php?file=${MY_P} -> ${MY_P}.tar.gz"
	else
		KEYWORDS=""
		MY_MINORV="$(get_version_component_range 4)"
		MY_P="${MY_P}${MY_MINORV/pre/m}"
		SRC_URI="http://www.phoronix-test-suite.com/download.php?file=development/${MY_P} -> ${MY_P}.tar.gz"
	fi
	S="${WORKDIR}/${PN}"
fi

IUSE=""

DEPEND=""
RDEPEND="${DEPEND}
		dev-lang/php[cli,curl,gd,json,posix,pcntl,sockets,truetype,zip]"

src_prepare() {
	source "${FILESDIR}/tidyup_pts_source_helper.sh"
	tidyup_pts_source "${S}" || die
	[[ $(get_major_version) -lt 6 ]] && { tidyup_pts_source_pre_6.0.0 "${S}" || die; }
}

src_install() {
	local package_data_dir="/usr/share/${PN}"
	dodir "${package_data_dir}"
	insinto "${package_data_dir}"

	doman documentation/man-pages/phoronix-test-suite.1
	dodoc AUTHORS ChangeLog
	dohtml -r documentation/
	doicon pts-core/static/images/phoronix-test-suite.png
	doicon pts-core/static/images/openbenchmarking.png
	domenu pts-core/static/phoronix-test-suite.desktop
	newbashcomp pts-core/static/bash_completion ${PN}
	rm -f "${S}/pts-core/static/bash_completion" || die "rm: PTS bash_completion"

	doins -r pts-core
	exeinto /usr/bin
	doexe phoronix-test-suite
	find "${D}${package_data_dir}" -type f -name "*.sh" -printf "${package_data_dir}/%P\0" | xargs -0 fperms a+x

	# Fix the cli-php config for downloading to work.
	source "${FILESDIR}/check_php_config_helper.sh"
	check_php_config
}
