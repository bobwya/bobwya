# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

PLOCALES="ca cs da de el en es eu fr hu it ja pl pt_BR ru sr sr@latin tr zh_TW"

inherit cmake-utils flag-o-matic l10n versionator

SLOT="0"

DESCRIPTION="Avidemux is a simple cross-platform video editor"
HOMEPAGE="http://fixounet.free.fr/${PN}"

MY_PN="${PN}"
if [[ "${PV}" == *9999* ]]; then
	inherit git-r3
	MY_P="${P}"
	MY_PV="${PV}"
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/mean00/${MY_PN}2.git"

else
	MY_P="${MY_PN}_${PV}"
	version_components=( $(get_version_components) )
	MY_PV="${version_components[0]}${version_components[1]}"
	unset -v version_components
	SRC_URI="mirror://sourceforge/${MY_PN}/${MY_PN}/${PV}/${MY_P}.tar.gz"
	KEYWORDS="~amd64"
fi

# Multiple licenses because of all the bundled stuff.
LICENSE="GPL-1 GPL-2 MIT PSF-2 public-domain"

IUSE="cli debug gtk opengl nls qt4 qt5 sdl vaapi vdpau xv"

REQUIRED_USE="|| ( cli gtk qt4 qt5 )"
DEPEND="
	!media-video/avidemux:2.6
	~media-libs/avidemux-core-${PV}:0[nls?,sdl?,vaapi?,vdpau?,xv?]
	gtk? ( x11-libs/gtk+:3 )
	opengl? ( virtual/opengl:0 )
	qt4? (	>=dev-qt/qtcore-4.8.3:4
		>=dev-qt/qtgui-4.8.3:4 )
	qt5? (	dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtnetwork:5
		dev-qt/qtwidgets:5 )
	vaapi? ( x11-libs/libva:0 )
	"
RDEPEND="$DEPEND"
PDEPEND="~media-libs/avidemux-plugins-${PV}:0=[cli?,gtk?,opengl?,qt4?,qt5?]"

S="${WORKDIR}/${MY_P}"

pkg_pretend() {
	if use gtk; then
		ewarn "The Gtk frontend, for ${CATEGORY}/${PN}, is considered obsolete by Upstream"
		ewarn "and currently does not build successfully."
	fi
}

src_prepare() {
	export array_processes
	local use_flag
	if use cli; then
		use_flag="cli"
		sed -i  "s|${PN}3_${use_flag}|${PN}${MY_PV}_${use_flag}|g" "${S%/}/${PN}/${use_flag}/CMakeLists.txt" \
			|| die "sed failed"
		array_processes=( "buildCli" "${PN}/${use_flag}" )
	fi
	if use gtk; then
		use_flag="gtk"
		sed -i  "s|${PN}3_${use_flag}|${PN}${MY_PV}_${use_flag}|g" "${S%/}/${PN}/${use_flag}/CMakeLists.txt" \
			|| die "sed failed"
		sed -i '1 i #include <string>' "${S%/}/${PN}/${use_flag}/ADM_userInterfaces/ui_support.cpp" \
			|| die "sed failed"
		eapply --binary "${FILESDIR}/${PN}-2.6.14-avidemux_gtk_cmake_path.patch"
		array_processes+=( "buildGtk" "${PN}/${use_flag}" )
	fi
	if use qt4 || use qt5; then
		use_flag="qt4"
		# shellcheck disable=SC2016
		sed -i  "s|${PN}3_"'${QT_EXTENSION}'"|${PN}${MY_PV}_"'${QT_EXTENSION}'"|g" \
				"${S%/}/${PN}/${use_flag}"/{adm_default.cmake,CMakeLists.txt,ADM_jobs/src/ADM_runOneJob.cpp} \
			|| die "sed failed"
		# shellcheck disable=SC2016
		sed -i  "s|${PN}3_jobs_"'${QT_EXTENSION}'"|${PN}${MY_PV}_jobs_"'${QT_EXTENSION}'"|g" \
				"${S%/}/${PN}/${use_flag}/ADM_jobs/src/CMakeLists.txt" \
			|| die "sed failed"
		use qt4 && array_processes+=( "buildQt4" "${PN}/${use_flag}" )
		use qt5 && array_processes+=( "buildQt5" "${PN}/${use_flag}" )
	fi

	create_desktop_file() {
		local __use_flag="${1}" __type="${2}"

		sed -e "\|Name=|s|${PN}.*$|${PN^}${__type:+ }${__type^} (${__use_flag^})|" \
			-e "\|Exec=|s|${PN}.*$|${PN}${MY_PV}${__type:+_}${__type}_${__use_flag}|" \
			-e "\|Icon=|s|${PN}.*$|${PN}${MY_PV}|" \
			-e "\|Categories=|s|Application;AudioVideo|AudioVideo;|" \
			"${S%/}/${PN}2.desktop" >"${S%/}/${PN}${MY_PV}${__type:+_}${__type}_${__use_flag}.desktop" \
			|| die "sed failed"
	}

	local use_flag
	for use_flag in "gtk" "qt4" "qt5"; do
		use ${use_flag} || continue

		create_desktop_file "${use_flag}"
		create_desktop_file "${use_flag}" "jobs"
	done
	rm "${S%/}/${PN}2.desktop"

	# Remove "Build Option" dialog because it doesn't reflect what the GUI can or has been built with. (Bug #463628)
	sed -i -e '/Build Option/d' "${S%/}/avidemux/common/ADM_commonUI/myOwnMenu.h" \
		|| die "sed failed"

	# Fix underlinking to work with gold linker
	sed -i -e 's/-lm/-lXext -lm/' "${S%/}/avidemux/qt4/CMakeLists.txt" \
		|| die "sed failed"

	eapply_user
}

src_configure() {
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		local build_flag
		build_flag=$(echo "${build_directory}" | sed '{s/^build//;s/./\U&/g}')
		local -a mycmakeargs=(
			"-DAVIDEMUX_SOURCE_DIR='${S%/}'"
			"-DENABLE_${build_flag}=YES"
			"-DOPENGL=OFF"
			"-DGETTEXT=$(usex nls)"
			"-DSDL=$(usex sdl)"
			"-DLIBVA=$(usex vaapi)"
			"-DVDPAU=$(usex vdpau)"
			"-DXVBA=NO"
			"-DXVIDEO=$(usex xv)"
		)
		use debug && mycmakeargs+=( "-DVERBOSE=1" "-DCMAKE_BUILD_TYPE=Debug" "-DADM_DEBUG=1" )
		mkdir "${S%/}/${build_directory}" || die "mkdir \"${S%/}/${build_directory}\" failed"
		cd "${S%/}/${build_directory}" || die "cd failed"
		if [[ "${build_directory}" =~ Qt4$ ]]; then
			append-cxxflags "$(test-flags-CXX -std=gnu++98)" # Needed for gcc-6
		else
			append-cxxflags "$(test-flags-CXX -std=gnu++11)"
		fi
		CMAKE_USE_DIR="${S%/}/${cmake_directory}" BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_configure
	done

	# Filter problematic compiler flags.
	filter-flags -ftracer -flto

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
			QT_SELECT=4 BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_compile
		elif use qt5; then
			QT_SELECT=5 BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_compile
		else
			BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_compile
		fi
	done
}

DOCS=( "AUTHORS" "README" )

src_install() {
	local use_flag
	xargs -n2 <<<"${array_processes[@]}" | while read -r build_directory cmake_directory; do
		BUILD_DIR="${S%/}/${build_directory}" cmake-utils_src_install
	done

	newicon "${S%/}/${PN}_icon.png" "${PN}${MY_PV}.png"

	install_executable_file() {
		local	__use_flag="${1}" __type="${2}"
		local	__extension="${MY_PV}${__type:+_}${__type}_${__use_flag}"

		if [[ -f "${D%/}/usr/bin/${PN}${__extension}" ]]; then
			fperms +x "/usr/bin/${PN}${__extension}"
		fi
	}

	install_desktop_file() {
		local	__use_flag="${1}" __type="${2}"
		local	__extension="${MY_PV}${__type:+_}${__type}_${__use_flag}"

		if [[ -f "${S%/}/${PN}${__extension}.desktop" ]]; then
			domenu "${S%/}/${PN}${__extension}.desktop"
		fi
	}

	install_executable_file "cli"
	for use_flag in "gtk" "qt4" "qt5"; do
		use "${use_flag}" || continue

		install_executable_file "${use_flag}"
		install_executable_file "${use_flag}" "jobs"
		install_desktop_file "${use_flag}"
		install_desktop_file "${use_flag}" "jobs"
	done
	unset -v array_processes
}
