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
		MY_MINORV="${MY_MINORV/pre/m}"
		MY_P="${MY_P}${MY_MINORV}"
		SRC_URI="http://www.phoronix-test-suite.com/download.php?file=development/${MY_P} -> ${MY_P}.tar.gz"
	fi
	S="${WORKDIR}/${PN}"
fi

IUSE=""

DEPEND=""
RDEPEND="dev-lang/php[cli,curl,gd,json,posix,pcntl,truetype,zip]"

src_prepare() {
	sed -i -e 's:PTS_DIR=`pwd`:PTS_DIR="/usr/share/phoronix-test-suite":' \
			-e 's:"`pwd`":"$(pwd)":'				\
			-e 's:`dirname $0`:"$(dirname $0)":g'	\
			-e 's:\$PTS_DIR:"\${PTS_DIR}":g'		\
			"${S}/phoronix-test-suite"
	# Tidyup non-Gentoo install scripts
	rm -f "${S}/pts-core/external-test-dependencies/scripts"/install-{a,d,f,m,n,o,p,u,z}*-packages.sh
	if [[ $(get_version_component_range 1) -lt 6 ]] ; then
		[ -f "CHANGE-LOG" ] && mv "CHANGE-LOG" "ChangeLog"
		# Backport Upstream issue #79 with BASH completion helper
		sed -i -e 's:_phoronix-test-suite-show:_phoronix_test_suite_show:g' \
			"${S}/pts-core/static/bash_completion" \
			|| die "sed unable to correct PTS bash completion helper"
	fi
	# BASH completion helper function "have" test - is now depreciated - so remove
	sed -i -e '/^have phoronix-test-suite &&$/d' "${S}/pts-core/static/bash_completion" \
		|| die "sed unable to remove PTS bash completion have test"
}

src_install() {
	local PACKAGE_DATA_DIR="/usr/share/${PN}"
	dodir "${PACKAGE_DATA_DIR}"
	insinto "${PACKAGE_DATA_DIR}"

	doman documentation/man-pages/phoronix-test-suite.1
	dodoc AUTHORS ChangeLog
	dohtml -r documentation/
	doicon pts-core/static/images/phoronix-test-suite.png
	doicon pts-core/static/images/openbenchmarking.png
	domenu pts-core/static/phoronix-test-suite.desktop
	newbashcomp pts-core/static/bash_completion ${PN}
	rm -f "${S}/pts-core/static/bash_completion"

	doins -r pts-core
	exeinto /usr/bin
	doexe phoronix-test-suite
	find "${D}${PACKAGE_DATA_DIR}" -type f -name "*.sh" -printf "${PACKAGE_DATA_DIR}/%P\0" | xargs -0 fperms a+x

	# Fix the cli-php config for downloading to work.
	local PHP_SLOT
	for PHP_SLOT in $(eselect --brief php list cli); do
		local php_dir="etc/php/cli-${PHP_SLOT}"
		if [[ -f "${ROOT}${php_dir}/php.ini" ]] ; then
			dodir "${php_dir}"
			cp -f "${ROOT}${php_dir}/php.ini" "${D}${php_dir}/php.ini" \
				|| die "cp unable to copy php.ini file"
			sed -i -e 's|^allow_url_fopen .*|allow_url_fopen = On|g' "${D}${php_dir}/php.ini" \
				|| die "sed unable to modify php.ini file copy"
		elif [[ "x$(eselect php show cli)" == "x${PHP_SLOT}" ]] ; then
			ewarn
			ewarn "${PHP_SLOT} does not have a php.ini file."
			ewarn "${PN} needs the 'allow_url_fopen' option set to \"On\""
			ewarn "for downloading to work properly."
			ewarn
		else
			elog
			elog "${PHP_SLOT} does not have a php.ini file."
			elog "${PN} may need the 'allow_url_fopen' option set to \"On\""
			elog "for downloading to work properly if you switch to ${PHP_SLOT}"
			elog
		fi
	done
}
