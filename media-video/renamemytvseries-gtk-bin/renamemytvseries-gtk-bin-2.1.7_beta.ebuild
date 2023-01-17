# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Rename your TV-Series using TheTVDB (GTK version)"
HOMEPAGE="https://www.tweaking4all.com/home-theatre/rename-my-tv-series-v2"

PN_PRE="${PN%-bin}"
PN_POST="${PN_PRE#*-}"
PN_PRE="${PN_PRE%-*}"

MY_PN="RenameMyTVSeries"
MY_PN_POST="${PN_POST^^}"

if [[ "${PV}" =~ beta ]]; then
	SRC_URI="https://www.tweaking4all.com/downloads/betas/${MY_PN}-$(ver_cut 1-3)-${MY_PN_POST}-beta-Linux-64bit-shared-ffmpeg.tar.gz -> ${P}.tar.gz"
else
	SRC_URI="https://www.tweaking4all.com/downloads/${MY_PN}-${PV}-${MY_PN_POST}-Linux-64bit-shared-ffmpeg.tar.gz -> ${P}.tar.gz"
fi

LICENSE="RenameMyTVSeries"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE=""

DEPEND=""
RDEPEND="
	!media-video/renamemytvseries-qt5-bin
	dev-db/sqlite:3
	>=app-accessibility/at-spi2-core-2.46.0:2[X,introspection]
	dev-libs/glib:2
	media-video/ffmpeg
	x11-libs/cairo[X,glib]
	x11-libs/gtk+:2[introspection]
	x11-libs/libX11
	x11-libs/libnotify[introspection]
	x11-libs/pango[X,introspection]"

QA_PREBUILT="opt/${PN_PRE}/${PN_PRE}"

S="${WORKDIR}"

src_prepare() {
	local exe_path

	eapply_user

	exe_path="${S}/${MY_PN}"
	patchelf --set-rpath "./:" "${exe_path}" \
		|| die "patchelf failed"
}

src_install() {
	local sizes="16 32 64 128 256 512"

	exeopts -m755
	exeinto "/opt/${PN_PRE}"
	newexe "${MY_PN}" "${PN_PRE}"
	dosym ../../"opt/${PN_PRE}/${PN_PRE}" "/usr/bin/${PN_PRE}"

	for size in ${sizes}; do
		newicon -s "${size}" "icons/${size}x${size}.png" "${PN_PRE}.png"
	done
	domenu "${FILESDIR}/${MY_PN}.desktop"

	dostrip -x ${QA_PREBUILT}
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
