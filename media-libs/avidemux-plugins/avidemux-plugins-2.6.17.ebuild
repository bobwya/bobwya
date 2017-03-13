# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit cmake-utils flag-o-matic python-single-r1

SLOT="2.6"

DESCRIPTION="Avidemux is a simple cross-platform video editor (plugins component)"
HOMEPAGE="http://fixounet.free.fr/avidemux"

MY_PN="${PN%-plugins}"
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
IUSE="aac aften a52 alsa amr cli debug dts fontconfig fribidi gtk jack lame libsamplerate cpu_flags_x86_mmx nvenc opengl opus oss pulseaudio qt4 qt5 vorbis truetype twolame xv xvid x264 x265 vapoursynth vdpau vpx"

REQUIRED_USE="|| ( cli gtk qt4 qt5 )"
DEPEND="
	~media-libs/avidemux-core-${PV}:${SLOT}[vdpau?]
	~media-video/avidemux-${PV}:${SLOT}[cli?,gtk?,opengl?,qt4?,qt5?]
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
		media-sound/jack-audio-connection-kit:0
		libsamplerate? ( media-libs/libsamplerate:0 )
	)
	lame? ( media-sound/lame:0 )
	nvenc? ( media-video/nvidia_video_sdk:0 )
	opus? ( media-libs/opus:0 )
	oss? ( virtual/os-headers:0 )
	pulseaudio? ( media-sound/pulseaudio:0 )
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
RDEPEND="$DEPEND"

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
	unset -v PATCHES
	export array_processes=( "buildPluginsCommon" "avidemux_plugins" )
	use cli && array_processes+=( "buildPluginsCli" "avidemux_plugins" )
	use gtk && array_processes+=( "buildPluginsGtk" "avidemux_plugins" )
	use qt4 && array_processes+=( "buildPluginsQt4" "avidemux_plugins" )
	use qt5 && array_processes+=( "buildPluginsQt5" "avidemux_plugins" )
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		CMAKE_USE_DIR="${S}/${cmake_directory}" BUILD_DIR="${S}/${build_directory}" cmake-utils_src_prepare
	done
}

src_configure() {
	# Add lax vector typing for PowerPC.
	if use ppc || use ppc64; then
		append-cflags -flax-vector-conversions
	fi

	# See bug 432322.
	use x86 && replace-flags -O0 -O1

	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		local 	build_flag=$(echo "${build_directory}" | sed '{s/^buildPlugins//;s/./\U&/g}')
		local -a mycmakeargs=(
			-DAVIDEMUX_SOURCE_DIR='${S}'
			-DPLUGIN_UI="${build_flag/QT*/QT4}"
			-DENABLE_"${build_flag}"=YES
			-DOPENGL=OFF
			-DVAPOURSYNTH=OFF
			-DFAAC="$(usex aac)"
			-DFAAD="$(usex aac)"
			-Dalsa="$(usex alsa)"
			-Daften="$(usex aften)"
			-DOPENCORE_AMRWB="$(usex amr)"
			-DOPENCORE_AMRNB="$(usex amr)"
			-DLIBDCA="$(usex dts)"
			-DFONTCONFIG="$(usex fontconfig)"
			-DJACK="$(usex jack)"
			-DLAME="$(usex lame)"
			-DNVENC="$(usex nvenc)"
			-DOPUS="$(usex opus)"
			-DOSS="$(usex oss)"
			-DPULSEAUDIOSIMPLE="$(usex pulseaudio)"
			-DFREETYPE2="$(usex truetype)"
			-DTWOLAME="$(usex twolame)"
			-DX264="$(usex x264)"
			-DX265="$(usex x265)"
			-DXVIDEO="$(usex xv)"
			-DXVID="$(usex xvid)"
			-DVDPAU="$(usex vdpau)"
			-DVORBIS="$(usex vorbis)"
			-DLIBVORBIS="$(usex vorbis)"
			-DVPX="$(usex vpx)"
		)

		if use debug ; then
			mycmakeargs+=( -DVERBOSE=1 -DCMAKE_BUILD_TYPE=Debug -DADM_DEBUG=1 )
		fi
		mkdir "${S}/${build_directory}" || die "mkdir failed"
		CMAKE_USE_DIR="${S}/${cmake_directory}" BUILD_DIR="${S}/${build_directory}" cmake-utils_src_configure
	done
	default
}

src_compile() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		BUILD_DIR="${S}/${build_directory}" cmake-utils_src_compile
	done
}

src_install() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		# cmake-utils_src_install doesn't respect BUILD_DIR
		# and there sometimes is a preinstall phase present.
		pushd "${S}/${build_directory}" || die "pushd failed"
		grep -q '^preinstall/fast' Makefile && emake DESTDIR="${D}" preinstall/fast
		grep -q '^install/fast'	   Makefile && emake DESTDIR="${D}" install/fast
		popd || die "popd failed"
	done

	unset -v array_processes
}
