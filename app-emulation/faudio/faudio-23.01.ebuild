# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

CMAKE_MAKEFILE_GENERATOR="ninja"
MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit cmake-multilib

FAUDIO_PN="FAudio"
FAUDIO_PV="${PV}"
FAUDIO_P="${FAUDIO_PN}-${FAUDIO_PV}"

if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/FNA-XNA/${FAUDIO_PN}.git"
else
	SRC_URI="https://github.com/FNA-XNA/${FAUDIO_PN}/archive/${FAUDIO_PV}.tar.gz -> ${FAUDIO_P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
	S="${WORKDIR}/${FAUDIO_P}"
fi

DESCRIPTION="FAudio - Accuracy-focused XAudio reimplementation for open platforms"
HOMEPAGE="https://fna-xna.github.io/"
LICENSE="ZLIB"
SLOT="0"

IUSE="+abi_x86_32 +abi_x86_64 debug dumpvoices xnasong test utils"
RESTRICT="!test? ( test )"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

COMMON_DEPEND="
	>=media-libs/libsdl2-2.0.9[sound,${MULTILIB_USEDEP}]
"
RDEPEND="${COMMON_DEPEND}
"
DEPEND="${COMMON_DEPEND}
"

PATCHES=( "${FILESDIR}/${PN}-19.01-install_tests.patch" )

multilib_src_configure() {
	local mycmakeargs=(
		"-DCMAKE_INSTALL_BINDIR=bin"
		"-DCMAKE_INSTALL_INCLUDEDIR=include/${FAUDIO_PN}"
		"-DCMAKE_INSTALL_LIBDIR=$(get_libdir)"
		"-DCMAKE_INSTALL_PREFIX=${EPREFIX}/usr"
		"-DCMAKE_BUILD_TYPE=$(usex debug Debug Release)"
		"-DFORCE_ENABLE_DEBUGCONFIGURATION=$(usex debug ON OFF)"
		"-DBUILD_TESTS=$(usex test ON OFF)"
		"-DBUILD_UTILS=$(usex utils ON OFF)"
		"-DDUMP_VOICES=$(usex dumpvoices ON OFF)"
		"-DXNASONG=$(usex xnasong ON OFF)"
	)
	cmake_src_configure
}

src_configure() {
	cmake-multilib_src_configure
}

multilib_src_compile() {
	cmake_build
}

multilib_src_test() {
	# FIXME: tests don't detect any audio devices

	local faudio_tests test_ok=0

	faudio_tests="faudio_tests"
	"./${faudio_tests}" && tests_ok=1

	((tests_ok)) || die "${PN} tests failed"
}

multilib_src_install() {
	# FIXME: do we want to install the FAudio tools?
	cmake_src_install
}
