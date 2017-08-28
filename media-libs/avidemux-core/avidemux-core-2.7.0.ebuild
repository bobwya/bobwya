# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

PLOCALES="ca cs da de el en es eu fr hu it ja pl pt_BR ru sr sr@latin tr zh_TW"

inherit cmake-utils flag-o-matic

SLOT="0"

DESCRIPTION="Avidemux is a simple cross-platform video editor (core libraries component)"
HOMEPAGE="http://fixounet.free.fr/${PN}"

MY_PN="${PN%-core}"
if [[ "${PV}" == *9999* ]]; then
	inherit git-r3
	MY_P="${P}"
	EGIT_REPO_URI="https://github.com/mean00/${MY_PN}2.git"
	SRC_URI=""
	KEYWORDS=""
else
	MY_P="${MY_PN}_${PV}"
	SRC_URI="mirror://sourceforge/${MY_PN}/${MY_PN}/${PV}/${MY_P}.tar.gz"
	KEYWORDS="~amd64"
fi

# Multiple licenses because of all the bundled stuff.
LICENSE="GPL-1 GPL-2 MIT PSF-2 public-domain"

IUSE="debug nls sdl system-ffmpeg vaapi vdpau xv"

COMMON_DEPEND="
	!media-libs/avidemux-core:2.6
	!<media-video/avidemux-${PV}:0
	dev-db/sqlite:3
	sdl? (
		|| ( media-libs/libsdl:0
			media-libs/libsdl2:0 )
	)
	system-ffmpeg? ( >=virtual/ffmpeg-9-r2:0[mp3,theora] )
	vaapi? ( x11-libs/libva:0 )
	vdpau? ( x11-libs/libvdpau:0 )
	xv? ( x11-libs/libXv:0 )
"
RDEPEND="
	${COMMON_DEPEND}
	nls? ( virtual/libintl:0 )
"
DEPEND="
	${COMMON_DEPEND}
	virtual/pkgconfig
	nls? ( sys-devel/gettext )
	!system-ffmpeg? ( dev-lang/yasm[nls=] )
"
S="${WORKDIR}/${MY_P}"

pkg_pretend() {
	if has_version '>=dev-util/cmake-3.9.0'; then
		ewarn "If you are upgrading from a previous revision of this package"
		ewarn "please unmerge the previously installed version first:"
		ewarn "  emerge --unmerge ${CATEGORY}/${PN}"
		ewarn ""
	fi
}

src_prepare() {
	export build_directory="buildCore" cmake_directory="avidemux_core"
	mkdir "${S%/}/${build_directory}" || die "mkdir failed"
	if use system-ffmpeg; then
		# Prepare to support system ffmpeg. Currently this fails because avidemux depends on files the system ffmpeg doesn't install.
		rm -rf "${S%/}/cmake"/{admFFmpeg,ffmpeg}* "${S%/}/${cmake_directory}/ffmpeg_package" "${S%/}/${build_directory}/ffmpeg" \
			|| die "rm failed"
		sed -i -e 's/include(admFFmpegUtil)//g' -e '/registerFFmpeg/d' "${S%/}/avidemux/commonCmakeApplication.cmake" \
			|| die "sed failed"
		sed -i -e 's/include(admFFmpegBuild)//g' "${S%/}/${cmake_directory}/CMakeLists.txt" \
			|| die "sed failed"
	else
		eapply --binary "${FILESDIR}/${PN}-2.6.16-ffmpeg-parallel-build-use-processorcount.patch"
		# Avoid existing avidemux installations from making the build process fail, bug #461496.
		# shellcheck disable=SC2016
		sed -i -e 's|getFfmpegLibNames("${sourceDir}")|getFfmpegLibNames("'"${S%/}/${build_directory}/ffmpeg/source/"'")|g' \
				"${S%/}/cmake/admFFmpegUtil.cmake" \
			|| die "sed failed"
	fi

	# Add lax vector typing for PowerPC.
	if use ppc || use ppc64; then
		append-cflags -flax-vector-conversions
	fi

	# See bug 432322.
	use x86 && replace-flags -O0 -O1

	# Needed for sys-devel/gcc:6.*
	append-cxxflags "$(test-flags-CXX -std=gnu++98)"

	# Filter problematic compiler flags.
	filter-flags -fwhole-program -flto

	default
}

src_configure() {
	local -a mycmakeargs=(
		"-DAVIDEMUX_SOURCE_DIR='${S%/}'"
		"-DGETTEXT=$(usex nls)"
		"-DSDL=$(usex sdl)"
		"-DLIBVA=$(usex vaapi)"
		"-DVDPAU=$(usex vdpau)"
		"-DXVBA=NO"
		"-DXVIDEO=$(usex xv)"
	)

	if use debug; then
		mycmakeargs+=( "-DVERBOSE=1" "-DCMAKE_BUILD_TYPE=Debug" "-DADM_DEBUG=1" )
	fi
	CMAKE_USE_DIR="${S%/}/${cmake_directory}" BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile -j1
}
src_install() {
	# revert edit from src_prepare prior to installing, bug #549818
	# shellcheck disable=SC2016
	sed -i -e 's|getFfmpegLibNames("'"${S%/}/${build_directory}/ffmpeg/source/"'")|getFfmpegLibNames("${sourceDir}")|g' \
			"${S%/}/cmake/admFFmpegUtil.cmake" \
		|| die "sed failed"
	cmake-utils_src_install -j1

	unset -v build_directory cmake_directory

}
