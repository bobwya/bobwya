# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop meson xdg-utils

DESCRIPTION="Hardware controlling and monitoring program."
HOMEPAGE="https://github.com/Lurkki14/tuxclocker"

if [[ "${PV}" == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/Lurkki14/${PN}.git"
	inherit git-r3
else
	# External Dobiasd/FunctionalPlus C++ library dependency
	FPLUS_PN="FunctionalPlus"
	FPLUS_COMMIT="62658c228f1b4081ebdc75395b8061fa6d8d4e28"
	FPLUS_P="${FPLUS_PN}-${FPLUS_COMMIT}"

	# External mpark/patterns C++ library dependency
	PATTERNS_PN="patterns"
	PATTERNS_COMMIT="b3270e0dd7b6312f7a4fe8647e2333dbb86e355e"
	PATTERNS_P="${PATTERNS_PN}-${PATTERNS_COMMIT}"

	SRC_URI="https://github.com/Lurkki14/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz
		https://github.com/Dobiasd/${FPLUS_PN}/archive/${FPLUS_COMMIT}.tar.gz -> ${FPLUS_P}.gh.tar.gz
		https://github.com/mpark/${PATTERNS_PN}/archive/${PATTERNS_COMMIT}.tar.gz -> ${PATTERNS_P}.gh.tar.gz
		https://github.com/Dobiasd/FunctionalPlus/commits/master"
	KEYWORDS="-* ~amd64"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE="+daemon +gui +plugins hwdata video_cards_amdgpu video_cards_nvidia"

DEPEND="
	dev-libs/boost:=
	gui? (
		dev-qt/qtcore:5
		dev-qt/qtcharts:5
		dev-qt/qtdbus:5
		dev-qt/qtgui:5
		dev-qt/qtwidgets:5
	)
"
RDEPEND="
	${DEPEND}
	video_cards_amdgpu? (
		hwdata? ( dev-python/python-hwdata )
		x11-libs/libdrm[video_cards_amdgpu]
	)
	video_cards_nvidia? (
		x11-drivers/nvidia-drivers:*[static-libs,tools]
	)
"

src_unpack() {
	if [[ "${PV}" == "9999" ]]; then
		git-r3_src_unpack
	else
		local dependency
		default
		for dependency in "${FPLUS_P}" "${PATTERNS_P}"; do
			mv "${WORKDIR}/${dependency}/include" "${S}/src/include/deps/${dependency%-*}/" \
				|| die "mv failed"
		done
	fi
}

src_configure() {
	local emesonargs=(
		-Dlibrary=true
		$(meson_use gui)
		$(meson_use plugins)
		$(meson_use daemon)
		$(meson_use video_cards_nvidia require-nvidia)
		$(meson_use video_cards_amdgpu require-amd)
		$(meson_use hwdata require-python-hwdata)
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	if use gui; then
		newicon -s scalable "${S}/src/tuxclocker-qt/resources/${PN}-logo.svg" "${PN}.svg"
		make_desktop_entry "${PN}" "${PN}" "${PN}"
	fi
	dodoc -r "doc" "README.md"
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
