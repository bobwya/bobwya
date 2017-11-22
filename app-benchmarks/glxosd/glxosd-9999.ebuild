# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit cmake-multilib multilib toolchain-funcs

MY_PN="${PN^^}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="GLXOSD is an on-screen overlay for X11/OpenGL applications running on Linux."
HOMEPAGE="https://github.com/dimibyte/GLXOSD"

if [ "${PV}" == "9999" ]; then
	EGIT_REPO_URI="https://github.com/dimibyte/${MY_PN}.git"
	EGIT3_STORE_DIR="${EGIT3_STORE_DIR:-${T}}"
	EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_P}"
	EGIT_BRANCH="master"
	inherit git-r3
else
	SRC_URI="https://github.com/dimibyte/${MY_PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE="+abi_x86_32 +abi_x86_64 nvidia"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

DEPEND="dev-libs/boost
		media-libs/fontconfig[${MULTILIB_USEDEP}]
		media-libs/freetype:2[${MULTILIB_USEDEP}]
		media-libs/mesa[${MULTILIB_USEDEP}]
		sys-apps/lm_sensors[${MULTILIB_USEDEP}]
		virtual/glu[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]
		x11-proto/xproto[${MULTILIB_USEDEP}]
		nvidia? ( x11-drivers/nvidia-drivers[static-libs,${MULTILIB_USEDEP}] )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	local cmakelists_file
	while IFS= read -r -d '' cmakelists_file; do
		# shellcheck disable=SC2016
		sed -i  -e 's|lib/\${CMAKE_LIBRARY_ARCHITECTURE}|\${CMAKE_LIBRARY_PATH}|g' "${cmakelists_file}" \
			|| die "sed failed"
	done< <(find "${S%/}/src" -type f -name "CMakeLists.txt" -printf '%p\0' -exec false {} + \
				&& die "find failed - no CMakeLists.txt file matches in \"${S}\""
			)
	# shellcheck disable=SC2016
	sed -i  -e '\|^get_filename_component(OUTPUT_DIR \"bin/\" ABSOLUTE)|{s|\"bin/\"|${OUTPUT_DIR}|}' \
		"${S}/CMakeLists.txt" || die "sed failed"
	cmake-utils_src_prepare
}

multilib_src_configure() {
	local libdir
	libdir="$(get_libdir)"
	local -a mycmakeargs=(
		"-DCMAKE_C_FLAGS=${CFLAGS}"
		"-DCMAKE_CXX_FLAGS=${CXXFLAGS}"
		"-DOUTPUT_DIR=${libdir}"
		"-DCMAKE_LIBRARY_ARCHITECTURE=${ABI}"
		"-DCMAKE_LIBRARY_PATH=${libdir}"
		"-DCMAKE_INSTALL_PREFIX=/usr"
		"-DINSTALLATION_SUFFIX_32=/lib32/"
		"-DINSTALLATION_SUFFIX_64=/lib64/"
		"-DATTEMPT_NVIDIA_LINK=$(usex nvidia TRUE FALSE)"
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-multilib_src_compile
}

src_install() {
	cmake-multilib_src_install
}
