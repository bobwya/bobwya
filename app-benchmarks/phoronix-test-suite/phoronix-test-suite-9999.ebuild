# Copyright 1999-2015 Gentoo Foundation
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
else
	MY_MAJORV="$(get_version_component_range 1-3)"
 	MY_P="${PN}-${MY_MAJORV}"
	if [ -z "$(get_version_component_range 4)" ]; then
		KEYWORDS="~amd64 ~x86"
		SRC_URI="http://www.phoronix-test-suite.com/download.php?file=${MY_P} -> ${MY_P}.tar.gz"
	else	
        MY_MINORV="$(get_version_component_range 4)"
		MY_MINORV="${MY_MINORV/pre/m}"
		MY_P="${MY_P}${MY_MINORV}"
		SRC_URI="http://www.phoronix-test-suite.com/download.php?file=development/${MY_P} -> ${MY_P}.tar.gz"
	fi
	S="${WORKDIR}/${PN}"
fi
IUSE=""

DEPEND=""
# php 5.3 doesn't have pcre and reflection useflags anymore
RDEPEND="dev-lang/php[cli,curl,gd,json,posix,pcntl,truetype,zip]"

src_prepare() {
	sed -i -e 's:PTS_DIR=`pwd`:PTS_DIR="/usr/share/phoronix-test-suite":' \
			-e 's:"`pwd`":"$(pwd)":'				\
			-e 's:`dirname $0`:"$(dirname $0)":g'	\
			-e 's:\$PTS_DIR:"\${PTS_DIR}":g'		\
			phoronix-test-suite
	# Tidyup non-Gentoo install scripts
	rm -f pts-core/external-test-dependencies/scripts/install-{a,d,f,m,n,o,p,u,z}*-packages.sh
	if [[ ${PV} != "9999" ]] ; then
		[ -f "CHANGE-LOG" ] && mv "CHANGE-LOG" "ChangeLog"
		# Backport Upstream issue #79 with BASH completion helper
		sed -i -e 's:_phoronix-test-suite-show:_phoronix_test_suite_show:g' \
			pts-core/static/bash_completion
	fi
	# BASH completion helper function "have" test - is now depreciated - so remove
	sed -i -e '/^have phoronix-test-suite &&$/d' pts-core/static/bash_completion
}

src_install() {
	dodir /usr/share/${PN}
	insinto /usr/share/${PN}

	doman documentation/man-pages/phoronix-test-suite.1
	dodoc AUTHORS ChangeLog
	dohtml -r documentation/
	doicon pts-core/static/images/phoronix-test-suite.png
	doicon pts-core/static/images/openbenchmarking.png
	domenu pts-core/static/phoronix-test-suite.desktop
	newbashcomp pts-core/static/bash_completion ${PN}
	rm -f pts-core/static/phoronix-test-suite.desktop || die 'rm failed'
	rm -f pts-core/static/bash_completion || die 'rm failed'

	doins -r pts-core
	exeinto /usr/bin
	doexe phoronix-test-suite

	find /usr/share/${PN}/pts-core/ -type f -name "*.sh" -print0  | xargs -0 fperms a+x

	# Need to fix the cli-php config for downloading to work. Very naughty!
	local slots
	local slot
	if [[ "x${PHP_TARGETS}" == "x" ]] ; then
		ewarn
		ewarn "PHP_TARGETS seems empty, php.ini file can't be configure."
		ewarn "Make sure that PHP_TARGETS in /etc/make.conf is set."
		ewarn "phoronix-test-suite needs the 'allow_url_fopen' option set to \"On\""
		ewarn "for downloading to work properly."
		ewarn
	else
		for slot in ${PHP_TARGETS}; do
			slots+=" ${slot/-/.}"
		done
	fi

	for slot in ${slots}; do
		local PHP_INI_FILE="/etc/php/cli-${slot}/php.ini"
		if [[ -f ${PHP_INI_FILE} ]] ; then
			dodir $(dirname ${PHP_INI_FILE})
			cp ${PHP_INI_FILE} "${D}${PHP_INI_FILE}"
			sed -e 's|^allow_url_fopen .*|allow_url_fopen = On|g' -i "${D}${PHP_INI_FILE}"
		else
			if [[ "x$(eselect php show cli)" == "x${slot}" ]] ; then
				ewarn
				ewarn "${slot} hasn't a php.ini file."
				ewarn "phoronix-test-suite needs the 'allow_url_fopen' option set to \"On\""
				ewarn "for downloading to work properly."
				ewarn "Check that your PHP_INI_VERSION is set during ${slot} merge"
				ewarn
			else
				elog
				elog "${slot} hasn't a php.ini file."
				elog "phoronix-test-suite may need the 'allow_url_fopen' option set to \"On\""
				elog "for downloading to work properly if you switch to ${slot}"
				elog "Check that your PHP_INI_VERSION is set during ${slot} merge"
				elog
			fi
		fi
	done

	ewarn
	ewarn "If you upgrade from phoronix-test-suite-2*, you should reinstall all"
	ewarn "your tests because"
	ewarn "   \$HOME/.phoronix-test-suite/installed-tests/\$TEST_NAME/"
	ewarn "moves to"
	ewarn "   \$HOME/.phoronix-test-suite/installed-tests/pts/\$TEST_NAME-\$TEST_VERSION/"
	ewarn "in phoronix-test-suite-3* version. The \$TEST_VERSION can be find in"
	ewarn "pts-install.xml file."
	ewarn
}
