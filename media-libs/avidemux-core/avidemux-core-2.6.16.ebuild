# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit cmake-utils flag-o-matic

SLOT="2.6"

DESCRIPTION="Avidemux is a simple cross-platform video editor (core libraries component)"
HOMEPAGE="http://fixounet.free.fr/avidemux"

MY_PN="${PN%-core}"
if [[ ${PV} == *9999* ]] ; then
	MY_P="${P}"
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/mean00/${MY_PN}2.git git://github.com/mean00/${MY_PN}2.git"
	inherit git-r3
else
	MY_P="${MY_PN}_${PV}"
	KEYWORDS="~amd64"
	SRC_URI="mirror://sourceforge/${MY_PN}/${MY_PN}/${PV}/${MY_P}.tar.gz"
fi

# Multiple licenses because of all the bundled stuff.
LICENSE="GPL-1 GPL-2 MIT PSF-2 public-domain"
IUSE="debug nls sdl system-ffmpeg vaapi vdpau video_cards_fglrx xv"

# Trying to use virtual; ffmpeg misses aac,cpudetection USE flags now though, are they needed?
DEPEND="
	!<media-video/avidemux-${PV}:${SLOT}
	dev-db/sqlite:3
	sdl? (
		|| ( media-libs/libsdl:0
			 media-libs/libsdl2:0 )
		)
	system-ffmpeg? ( >=virtual/ffmpeg-9:0[mp3,theora] )
	vaapi? ( x11-libs/libva:0 )
	vdpau? ( x11-libs/libvdpau:0 )
	video_cards_fglrx? (
		|| ( >=x11-drivers/ati-drivers-14.12-r3
			x11-libs/xvba-video:0 )
		)
	xv? ( x11-libs/libXv:0 )
"
RDEPEND="
	$DEPEND
	nls? ( virtual/libintl:0 )
"
DEPEND="
	$DEPEND
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	!system-ffmpeg? ( dev-lang/yasm[nls=] )
"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	export build_directory="buildCore" cmake_directory="avidemux_core"
	mkdir "${S}/${build_directory}" || die "mkdir failed"

	default

	if use system-ffmpeg ; then
		# Preparations to support the system ffmpeg. Currently fails because it depends on files the system ffmpeg doesn't install.
		rm -rf "${S}/cmake"/{admFFmpeg,ffmpeg}* "${S}/${cmake_directory}/ffmpeg_package" "${S}/${build_directory}/ffmpeg" \
			|| die "rm failed"
		sed -i -e 's/include(admFFmpegUtil)//g' -e '/registerFFmpeg/d' "${S}/avidemux/commonCmakeApplication.cmake" \
			|| die "sed failed"
		sed -i -e 's/include(admFFmpegBuild)//g' "{S}/${cmake_directory}/CMakeLists.txt" \
			|| die "sed failed"
	else
		eapply --binary "${FILESDIR}/${PN}-2.6.16-ffmpeg-parallel-build-use-processorcount.patch"
		# Avoid existing avidemux installations from making the build process fail, bug #461496.
		sed -i -e "s:getFfmpegLibNames(\"\${sourceDir}\"):getFfmpegLibNames(\"${S}/${build_directory}/ffmpeg/source/\"):g" \
					"${S}/cmake/admFFmpegUtil.cmake" \
			|| die "sed failed"
	fi

	# Add lax vector typing for PowerPC.
	if use ppc || use ppc64 ; then
		append-cflags -flax-vector-conversions
	fi

	# See bug 432322.
	use x86 && replace-flags -O0 -O1
}

src_configure() {
	local -a mycmakeargs=(
		-DAVIDEMUX_SOURCE_DIR='${S}'
		-DGETTEXT="$(usex nls)"
		-DSDL="$(usex sdl)"
		-DLIBVA="$(usex vaapi)"
		-DVDPAU="$(usex vdpau)"
		-DXVBA="$(usex video_cards_fglrx)"
		-DXVIDEO="$(usex xv)"
	)

	if use debug ; then
		mycmakeargs+=( -DVERBOSE=1 -DCMAKE_BUILD_TYPE=Debug -DADM_DEBUG=1 )
	fi
	CMAKE_USE_DIR="${S}/${cmake_directory}" BUILD_DIR="${S}/${build_directory}" cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile -j1
}

src_install() {
	local DOCS=( AUTHORS README )
	# revert edit from src_prepare prior to installing, bug #549818
	sed -i -e "s:getFfmpegLibNames(\"${S}/${build_directory}/ffmpeg/source/\"):getFfmpegLibNames(\"\${sourceDir}\"):g" \
				"${S}/cmake/admFFmpegUtil.cmake" \
		|| die "sed failed"
	cmake-utils_src_install -j1
	unset -v build_directory cmake_directory
}
