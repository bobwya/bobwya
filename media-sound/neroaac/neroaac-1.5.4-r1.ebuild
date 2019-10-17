# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_PN="NeroAACCodec"
MP_P="${MY_PN}-${PV}"
DESCRIPTION="Nero AAC reference quality MPEG-4 and 3GPP audio codec"
HOMEPAGE="https://www.videohelp.com/software/Nero-AAC-Codec"
SRC_URI="${MP_P}.zip"

LICENSE="Nero-AAC-EULA"
SLOT="0"
KEYWORDS="amd64 ~ppc x86"
IUSE="doc"

RDEPEND=""
DEPEND="app-arch/unzip"

RESTRICT="fetch strip mirror test"
QA_PRESTRIPPED="opt/${PN}/${PV}/neroAac\(Dec\|Enc\|Tag\)"
QA_EXECSTACK="opt/${PN}/${PV}/neroAacDec opt/${PN}/${PV}/neroAacEnc"
QA_FLAGS_IGNORED="${QA_PRESTRIPPED}"

S="${WORKDIR}"

pkg_nofetch() {
	einfo "Please visit: ${HOMEPAGE} amd download: \"${MP_P}.zip\""
	einfo "Then move this zip file to your Portage distfiles directory."
	einfo
}

src_prepare() {
	edos2unix *.txt
	eapply_user
}

src_install() {
	exeinto "/opt/${PN}/${PV}"
	doexe "linux"/*
	dodir "/opt/bin"
	dosym ../"${PN}/${PV}/neroAacDec" "/opt/bin/neroAacDec"
	dosym ../"${PN}/${PV}/neroAacEnc" "/opt/bin/neroAacEnc"
	dosym ../"${PN}/${PV}/neroAacTag" "/opt/bin/neroAacTag"
	newdoc "readme.txt" "README"
	newdoc "license.txt" "LICENSE"
	newdoc "changelog.txt" "ChangeLog"
	if use doc; then
		insinto "/usr/share/doc/${PF}"
		doins "NeroAAC_tut.pdf"
	fi
}
