# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

PYTHON_COMPAT=( python{2_7,3_{4,5,6}} )

inherit cmake-utils flag-o-matic python-any-r1

SLOT="0"

DESCRIPTION="Avidemux is a simple cross-platform video editor (plugins component)"
HOMEPAGE="http://fixounet.free.fr/${PN}"

MY_PN="${PN%-plugins}"
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

IUSE="aac aften alsa amr a52 cli cpu_flags_x86_mmx debug dts fontconfig fribidi gtk jack lame libsamplerate nvenc opengl opus oss pulseaudio qt4 qt5 +system-a52dec +system-libass +system-libmad +system-libmp4v2 truetype twolame vapoursynth vdpau vorbis vpx xv xvid x264 x265"

REQUIRED_USE="|| ( cli gtk qt4 qt5 )
			!amd64? ( !nvenc )"
RDEPEND="
	!media-libs/avidemux-plugins:2.6
	~media-libs/avidemux-core-${PV}:0[vdpau?]
	~media-video/avidemux-${PV}:0[cli?,gtk?,opengl?,qt4?,qt5?]
	>=dev-lang/spidermonkey-1.5-r2:0=
	dev-libs/libxml2:2
	media-libs/libpng:0=
	virtual/libiconv:0
	aac? (
		media-libs/faac:0
		media-libs/faad2:0
	)
	aften? ( media-libs/aften:0 )
	alsa? ( >=media-libs/alsa-lib-1.0.3b-r2:0 )
	amr? ( media-libs/opencore-amr:0 )
	dts? ( media-libs/libdca:0 )
	fontconfig? ( media-libs/fontconfig:1.0 )
	fribidi? ( dev-libs/fribidi:0 )
	jack? (
		virtual/jack
		libsamplerate? ( media-libs/libsamplerate:0 )
	)
	lame? ( media-sound/lame:0 )
	nvenc? ( media-video/nvidia_video_sdk:0 )
	opus? ( media-libs/opus:0 )
	oss? ( virtual/os-headers:0 )
	pulseaudio? ( media-sound/pulseaudio:0 )
	system-a52dec? ( media-libs/a52dec:0 )
	system-libass? ( media-libs/libass:0= )
	system-libmad? ( media-libs/libmad:0 )
	system-libmp4v2? ( media-libs/libmp4v2:0 )
	truetype? ( media-libs/freetype:2 )
	twolame? ( media-sound/twolame:0 )
	vapoursynth? ( media-libs/vapoursynth:0 )
	vorbis? ( media-libs/libvorbis:0 )
	vpx? ( media-libs/libvpx:0 )
	x264? ( media-libs/x264:0= )
	x265? ( >=media-libs/x265-1.9 )
	xv? (
		x11-libs/libX11:0
		x11-libs/libXext:0
		x11-libs/libXv:0
	)
	xvid? ( media-libs/xvid:0 )
"
DEPEND="${DEPEND}"
S="${WORKDIR}/${MY_P}"

pkg_pretend() {
	if use gtk; then
		ewarn "The Gtk frontend, for ${CATEGORY}/${PN}, is considered obsolete by Upstream"
		ewarn "and currently does not build successfully."
	fi
}

src_prepare() {
	local PATCHES
	use pulseaudio	&& PATCHES+=( "${FILESDIR}/${PN}-2.6.14-optional-pulse.patch" )
	use opus		&& PATCHES+=( "${FILESDIR}/${PN}-2.6.14-opus_check.patch" )
	use nvenc		&& PATCHES+=( "${FILESDIR}/${PN}-2.6.14-fix_nvenc_check.patch" )
	default
}

src_configure() {
	export array_processes=( "buildPluginsCommon" "avidemux_plugins" )
	use cli && array_processes+=( "buildPluginsCli" "avidemux_plugins" )
	use gtk && array_processes+=( "buildPluginsGtk" "avidemux_plugins" )
	use qt4 && array_processes+=( "buildPluginsQt4" "avidemux_plugins" )
	use qt5 && array_processes+=( "buildPluginsQt5" "avidemux_plugins" )

	# Add lax vector typing for PowerPC.
	if use ppc || use ppc64; then
		append-cflags -flax-vector-conversions
	fi

	# See bug 432322.
	use x86 && replace-flags -O0 -O1

	# Filter problematic compiler flags.
	filter-flags -fwhole-program -flto

	local build_flag
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		build_flag=$(echo "${build_directory}" | sed '{s/^buildPlugins//;s/./\U&/g}')

		local -a mycmakeargs=(
			"-DAVIDEMUX_SOURCE_DIR='${S%/}'"
			"-DPLUGIN_UI=${build_flag/#QT*/QT4}"
			"-DENABLE_${build_flag}=YES"
			"-DOPENGL=OFF"
			"-DVAPOURSYNTH=OFF"
			"-DFAAC=$(usex aac)"
			"-DFAAD=$(usex aac)"
			"-DALSA=$(usex alsa)"
			"-DAFTEN=$(usex aften)"
			"-DOPENCORE_AMRWB=$(usex amr)"
			"-DOPENCORE_AMRNB=$(usex amr)"
			"-DLIBDCA=$(usex dts)"
			"-DFONTCONFIG=$(usex fontconfig)"
			"-DJACK=$(usex jack)"
			"-DLAME=$(usex lame)"
			"-DNVENC=$(usex nvenc)"
			"-DOPUS=$(usex opus)"
			"-DOSS=$(usex oss)"
			"-DPULSEAUDIOSIMPLE=$(usex pulseaudio)"
			"-DFREETYPE2=$(usex truetype)"
			"-DTWOLAME=$(usex twolame)"
			"-DX264=$(usex x264)"
			"-DX265=$(usex x265)"
			"-DXVIDEO=$(usex xv)"
			"-DXVID=$(usex xvid)"
			"-DVDPAU=$(usex vdpau)"
			"-DVORBIS=$(usex vorbis)"
			"-DLIBVORBIS=$(usex vorbis)"
			"-DVPX=$(usex vpx)"
			"-DUSE_EXTERNAL_LIBA52=$(usex system-a52dec)"
			"-DUSE_EXTERNAL_LIBASS=$(usex system-libass)"
			"-DUSE_EXTERNAL_LIBMAD=$(usex system-libmad)"
			"-DUSE_EXTERNAL_LIBMP4V2=$(usex system-libmp4v2)"
		)
		if [[ "${build_flag}" == "QT5" ]]; then
			export QT_SELECT=5
			append-cxxflags "$(test-flags-CXX -std=gnu++11)"
		else
			if [[ "${build_flag}" == "QT4" ]]; then
				mycmakeargs+=( "-DQT4=YES")
				export QT_SELECT=4
			fi
			# Needed for sys-devel/gcc:6.x.x
			append-cxxflags "$(test-flags-CXX -std=gnu++98)"
		fi

		if use debug ; then
			mycmakeargs+=( "-DVERBOSE=1" "-DCMAKE_BUILD_TYPE=Debug" "-DADM_DEBUG=1" )
		fi

		mkdir "${S%/}/${build_directory}" || die "mkdir failed"
		CMAKE_USE_DIR="${S%/}/${cmake_directory}" BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_configure
	done
}

src_compile() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_compile
	done
}
src_install() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		# cmake-utils_src_install doesn't respect BUILD_DIR - sometimes there is a preinstall phase present.
		pushd "${S%/}/${build_directory}" || die "pushd failed"
		grep -q '^preinstall/fast' "Makefile" && emake DESTDIR="${D%/}" preinstall/fast
		grep -q '^install/fast'	   "Makefile" && emake DESTDIR="${D%/}" install/fast
		popd || die "popd failed"
	done
	unset -v array_processes
}
