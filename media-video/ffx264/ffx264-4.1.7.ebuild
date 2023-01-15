# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

DESCRIPTION="Script to encode video files to H.264/AVC video using the FFmpeg encoder"
HOMEPAGE="https://ffx264.teambelgium.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""

RDEPEND="
	media-video/ffmpeg[fdk,fontconfig,mp3,opus,vorbis,x264,zimg]
	media-video/gpac[static-libs]
	media-video/mplayer
	sys-devel/bc"
DEPEND=""

src_compile() {
	:
}

src_install() {
	emake PREFIX="${ED}/usr" install
}
