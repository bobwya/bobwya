#!/bin/bash

tidyup_pts_source()
{
	local S="${1}"
	sed -i -e 's:PTS_DIR=`pwd`:PTS_DIR="/usr/share/phoronix-test-suite":' \
			-e 's:"`pwd`":"$(pwd)":' \
			-e 's:`dirname $0`:"$(dirname $0)":g' \
			-e 's:\$PTS_DIR:"\${PTS_DIR}":g' \
			"${S}/phoronix-test-suite" \
			|| die "sed: correcting main PTS file"
	find "${S}/pts-core/external-test-dependencies/xml/" -type f ! -name "gentoo-packages.xml" -print0 | xargs -0 rm -f \
			|| die "xargs-rm: non-Gentoo xml package files"
	find "${S}/pts-core/external-test-dependencies/scripts/" -type f ! -name "install-gentoo-packages.sh" -print0 | xargs -0 rm -f \
			|| die "xargs-rm: non-Gentoo package script files"
	# BASH completion helper function "have" test - is now depreciated - so remove
	sed -i -e '/^have phoronix-test-suite &&$/d' "${S}/pts-core/static/bash_completion" \
			|| die "sed: unable to remove PTS bash completion have test"
}

tidyup_pts_source_pre_6.0.0()
{
	local S="${1}"
	[ -f "${S}/CHANGE-LOG" ] && { mv "${S}/CHANGE-LOG" "${S}/ChangeLog" || die "mv: ChangeLog"; }
	# Backport Upstream issue #79 with BASH completion helper
	sed -i -e 's:_phoronix-test-suite-show:_phoronix_test_suite_show:g' "${S}/pts-core/static/bash_completion" \
		|| die "sed unable to correct PTS bash completion helper"
}
