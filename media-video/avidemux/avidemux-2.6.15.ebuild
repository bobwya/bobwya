# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

PLOCALES="ca cs da de el en es eu fr hu it ja pl pt_BR ru sr sr@latin tr zh_TW"

inherit cmake-utils flag-o-matic l10n

SLOT="2.6"

DESCRIPTION="Avidemux is a simple cross-platform video editor"
HOMEPAGE="http://fixounet.free.fr/${PN}"

MY_PN="${PN}"
if [[ ${PV} == *9999* ]] ; then
	MY_P="${P}"
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/mean00/${MY_PN}2.git git://github.com/mean00/${MY_PN}2.git"
	inherit git-r3
else
	MY_P="${PN}_${PV}"
	KEYWORDS="~amd64"
	SRC_URI="mirror://sourceforge/${PN}/${PN}/${PV}/${MY_P}.tar.gz"
fi

# Multiple licenses because of all the bundled stuff.
LICENSE="GPL-1 GPL-2 MIT PSF-2 public-domain"
IUSE="cli debug gtk opengl nls qt4 qt5 sdl vaapi vdpau video_cards_fglrx xv"

REQUIRED_USE="|| ( cli gtk qt4 qt5 )"
DEPEND="
	~media-libs/avidemux-core-${PV}:${SLOT}[nls?,sdl?,vaapi?,vdpau?,video_cards_fglrx?,xv?]
	gtk? ( x11-libs/gtk+:3 )
	opengl? ( virtual/opengl:0 )
	qt4? ( >=dev-qt/qtcore-4.8.3:4
		   >=dev-qt/qtgui-4.8.3:4 )
	qt5? (	 dev-qt/qtcore:5
			 dev-qt/qtgui:5
			 dev-qt/qtnetwork:5
		 	 dev-qt/qtwidgets:5 )
	vaapi? ( x11-libs/libva:0 )
	video_cards_fglrx? (
		|| ( >=x11-drivers/ati-drivers-14.12-r3
			   x11-libs/xvba-video:0 )
		)
"
RDEPEND="$DEPEND"
PDEPEND="~media-libs/avidemux-plugins-${PV}:${SLOT}[cli?,gtk?,opengl?,qt4?,qt5?]"

S="${WORKDIR}/${MY_P}"

pkg_pretend() {
	if use gtk; then
		ewarn "The Gtk frontend, for ${CATEGORY}/${PN}, is considered obsolete by Upstream"
		ewarn "and currently does not build successfully."
	fi
}

src_prepare() {
	export array_processes
	use cli && array_processes=( "buildCli" "avidemux/cli" )
	if use gtk; then
		sed -i '1 i #include <string>' "${S}/avidemux/gtk/ADM_userInterfaces/ui_support.cpp"
		eapply --binary "${FILESDIR}/${PN}-2.6.14-avidemux_gtk_cmake_path.patch"
		array_processes+=( "buildGtk" "avidemux/gtk" )
	fi
	use qt4 && array_processes+=( "buildQt4" "avidemux/qt4" )
	use qt5 && array_processes+=( "buildQt5" "avidemux/qt4" )

	default

	# Remove "Build Option" dialog because it doesn't reflect what the GUI can or has been built with. (Bug #463628)
	sed -i -e '/Build Option/d' "${S}/avidemux/common/ADM_commonUI/myOwnMenu.h" \
		|| die "sed failed"
}

src_configure() {
	use qt5 && append-cxxflags -std=c++11
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		local build_flag=$(echo "${build_directory}" | sed '{s/^build//;s/./\U&/g}')
		local -a mycmakeargs=(
			-DAVIDEMUX_SOURCE_DIR='${S}'
			-DENABLE_"${build_flag}"=YES
			-DOPENGL=OFF
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
		mkdir "${S}/${build_directory}" || die "mkdir \"${S}/${build_directory}\" failed"
		cd "${S}/${build_directory}" || die "cd failed"
		CMAKE_USE_DIR="${S}/${cmake_directory}" BUILD_DIR="${S}/${build_directory}" cmake-utils_src_configure
	done

	# Add lax vector typing for PowerPC.
	if use ppc || use ppc64; then
		append-cflags -flax-vector-conversions
	fi

	# See bug 432322.
	use x86 && replace-flags -O0 -O1
}

src_compile() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		if use qt4; then
			QT_SELECT=4 BUILD_DIR="${S}/${build_directory}" cmake-utils_src_compile
		elif use qt5; then
			QT_SELECT=5 BUILD_DIR="${S}/${build_directory}" cmake-utils_src_compile
		else
			BUILD_DIR="${S}/${build_directory}" cmake-utils_src_compile
		fi
	done
}

DOCS=( AUTHORS README )

src_install() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		BUILD_DIR="${S}/${build_directory}" cmake-utils_src_install
	done

	if [[ -f "${ED}"/usr/bin/avidemux3_cli ]]; then
		fperms +x /usr/bin/avidemux3_cli
	fi

	if [[ -f "${ED}"/usr/bin/avidemux3_jobs ]]; then
		fperms +x /usr/bin/avidemux3_jobs
	fi

	cd "${S}" || die "cd failed"
	newicon ${PN}_icon.png ${PN}-2.6.png

	local use_flag
	for use_flag in gtk qt4 qt5; do
		use "${use_flag}" || continue
		fperms +x "/usr/bin/avidemux3_${use_flag}"
		domenu "${FILESDIR}/${PN}2-6_${use_flag}.desktop"
	done
	unset -v array_processes
}
