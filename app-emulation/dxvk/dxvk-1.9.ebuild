# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

LTO_ENABLE_FLAGOMATIC="yes"

inherit dxvk flag-o-matic meson mingw64 multilib-minimal ninja-utils virtualx

DESCRIPTION="A Vulkan-based translation layer for Direct3D 9/10/11 supporting Linux + Wine"
HOMEPAGE="https://github.com/doitsujin/dxvk"

if [[ ${PV} == "9999" ]]; then
	EGIT_REPO_URI="https://github.com/doitsujin/dxvk.git"
	EGIT_BRANCH="master"
	inherit git-r3
	SRC_URI=""
else
	SRC_URI="https://github.com/doitsujin/dxvk/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64"
fi

LICENSE="ZLIB"
SLOT=0

IUSE="async +d3d9 +d3d10 +d3d11 debug +dxgi test video_cards_nvidia"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

# FIXME: the test suite is unsuitable for us, as it requires full access to
# installed Wine and native Vulkan stack.
RESTRICT="test"

RDEPEND="
	|| (
		video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-440.31 )
		>=media-libs/mesa-20.2
	)
	|| (
		>=app-emulation/wine-vanilla-5.14:*[${MULTILIB_USEDEP},vulkan]
		>=app-emulation/wine-staging-5.14:*[${MULTILIB_USEDEP},vulkan]
	)"

DEPEND="${RDEPEND}
	dev-util/glslang
	dev-util/vulkan-headers"

BDEPEND="
	>=dev-util/meson-0.46"

pkg_pretend() {
	mingw64_check_requirements "6.0.0" "8.0.0"
}

pkg_setup() {
	mingw64_check_requirements "6.0.0" "8.0.0"
}

src_prepare() {
	PATCHES=()
	use async && PATCHES+=( "${FILESDIR}/${PN}-1.8-async.patch" )

	filter-flags "-Wl,--hash-style*"
	[[ "$(is-flag "-march=*")" == "true" ]] && append-flags "-mno-avx"

	default

	dxvk_fix_setup_script
	dxvk_fix_readme
	multilib_foreach_abi dxvk_set_setup_path
	multilib_foreach_abi dxvk_set_meson_options
	dxvk_set_configuration_path "${EPREFIX}/etc/dxvk.conf"
}

multilib_src_configure() {
	local emesonargs=(
		--cross-file="${S}/$(dxvk_get_abi_build_file)"
		--libdir="$(get_libdir)/dxvk"
		--bindir="$(get_libdir)/dxvk"
		--buildtype="release"
		"$(usex debug '' '--strip')"
		"$(meson_use d3d9 'enable_d3d9')"
		"$(meson_use d3d10 'enable_d3d10')"
		"$(meson_use d3d11 'enable_d3d11')"
		"$(meson_use dxgi 'enable_dxgi')"
		"$(meson_use test 'enable_tests')"
	)
	meson_src_configure
}

multilib_src_compile() {
	meson_src_compile
}

multilib_src_test() {
	dxvk_tests "${BUILD_DIR}/tests"
}

multilib_src_install() {
	meson_src_install
}

multilib_src_install_all() {
	find "${D}" -name '*.a' -delete -print

	newbin "setup_dxvk.sh" "dxvk-setup"

	insinto /etc
	doins "dxvk.conf"

	default
}
