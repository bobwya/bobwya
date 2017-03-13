# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE="xml"
MY_PN="Polkit-Explorer"

EGIT_REPO_URI="https://github.com/scarygliders/${MY_PN}.git"
EGIT3_STORE_DIR="${T}"
inherit git-r3 python-single-r1
SRC_URI=""

DESCRIPTION="Present PolicyKit information in a human-readable form"
HOMEPAGE="https://github.com/scarygliders/Polkit-Explorer"

LICENSE="ISC"
SLOT="0"
KEYWORDS=""
IUSE=""

DEPEND="${PYTHON_DEPS}"
RDEPEND="${DEPEND}
		 dev-python/PyQt4[X,${PYTHON_USEDEP}]"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_prepare() {
	python_export PYTHON_SITEDIR
	sed -i 's/python$/python2/' polkitex.py
	# Reduce all Qt UI font element pointsizes (by a specified amount)
	"${FILESDIR}/font_fix.sh" "${S}" -4
}

src_install() {
	local	PACKAGE_DIR="${PYTHON_SITEDIR}/${PN}"
	domenu	"${FILESDIR}/${PN}.desktop"
	dodir "${PACKAGE_DIR}"
	exeinto "${PACKAGE_DIR}"
	doexe   *.py
	insinto "${PACKAGE_DIR}"
	doins	*.ui
	newicon  "PKEIconV001.png" "polkitex.png"
	dosym   "${PACKAGE_DIR}/polkitex.py" "/usr/bin/polkitex"
	dodoc "README.md"
	unset PACKAGE_DIR
}
