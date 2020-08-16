# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

LTO_ENABLE_FLAGOMATIC="yes"

inherit flag-o-matic meson mingw64 multilib-minimal ninja-utils

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

IUSE="+d3d9 +d3d10 +d3d11 debug +dxgi test video_cards_nvidia"
REQUIRED_USE="|| ( abi_x86_32 abi_x86_64 )"

RESTRICT="test"

RDEPEND="
	|| (
		video_cards_nvidia? ( >=x11-drivers/nvidia-drivers-440.31 )
		>=media-libs/mesa-19.2
	)
	|| (
		>=app-emulation/wine-vanilla-4.5:*[${MULTILIB_USEDEP},vulkan]
		>=app-emulation/wine-staging-4.5:*[${MULTILIB_USEDEP},vulkan]
	)"

DEPEND="${RDEPEND}
	dev-util/glslang
	dev-util/vulkan-headers"

BDEPEND="
	>=dev-util/meson-0.46"

get_abi_bit_count() {
	[[ "${ABI}" = "x86" ]]   && echo "32"
	[[ "${ABI}" = "amd64" ]] && echo "64"
}

pkg_pretend() {
	mingw64_check_requirements "6.0.0" "8.0.0"
}

pkg_setup() {
	mingw64_check_requirements "6.0.0" "8.0.0"
}

src_prepare() {
	PATCHES=(
		"${FILESDIR}/${PN}-1.7-pass_gentoo_build_chain_flags.patch"
	)

	filter-flags "-Wl,--hash-style*"
	[[ "$(is-flag "-march=*")" == "true" ]] && append-flags "-mno-avx"

	default

	sed -i -e 's|./setup_dxvk.sh|dxvk_setup|g' "${S}/README.md" \
		|| die "sed failed"
	sed -i -e "s|basedir=.*|basedir=\"${EPREFIX}/usr\"|" "${S}/setup_dxvk.sh" \
		|| die "sed failed"

	# Delete installation instructions for unused ABIs.
	if use abi_x86_32; then
		# shellcheck disable=SC2016
		sed -i '\|installFile "$win32_sys_path"|d' "${S}/setup_dxvk.sh" \
			|| die "sed failed"
	fi
	if use abi_x86_64; then
		# shellcheck disable=SC2016
		sed -i '\|installFile "$win64_sys_path"|d' "${S}/setup_dxvk.sh" \
			|| die "sed failed"
	fi

	bootstrap_dxvk() {
		# Set DXVK location for each ABI
		sed -i -e "s|x$(get_abi_bit_count)|$(get_libdir)/dxvk|" "${S}/setup_dxvk.sh" \
			|| die "sed failed"

		# Add *FLAGS to cross-file
		sed -i \
			-e "s|@CFLAGS@|$(_meson_env_array "${CFLAGS}")|" \
			-e "s|@CXXFLAGS@|$(_meson_env_array "${CXXFLAGS}")|" \
			-e "s|@LDFLAGS@|$(_meson_env_array "${LDFLAGS}")|" \
			"${S}/build-win$(get_abi_bit_count).txt" \
			|| die "sed failed"
	}

	multilib_foreach_abi bootstrap_dxvk

	# Load configuration file from /etc/dxvk.conf.
	sed -Ei 's|filePath = "^(\s+)dxvk.conf";$|\1filePath = "/etc/dxvk.conf";|' \
		"${S}/src/util/config/config.cpp" \
		|| die "sed failed"
}

multilib_src_configure() {
	local emesonargs=(
		--cross-file="${S}/build-win$(get_abi_bit_count).txt"
		--libdir="$(get_libdir)/dxvk"
		--bindir="$(get_libdir)/dxvk/bin"
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

multilib_src_install() {
	meson_src_install
}

multilib_src_install_all() {
	find "${D}" -name '*.a' -delete -print

	newbin "setup_dxvk.sh" "dxvk-setup"

	insinto etc
	doins "dxvk.conf"

	default
}

pkg_postinst() {
	elog "dxvk is installed, but not activated. You have to create DLL overrides"
	elog "in order to make use of it. To do this:"
	elog "export WINEPREFIX=/path/to/.wine-prefix"
	elog "dxvk-setup install --symlink."
}
