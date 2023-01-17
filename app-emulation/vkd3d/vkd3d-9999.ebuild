# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit autotools multibuild multilib-minimal

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://source.winehq.org/git/vkd3d.git"
	inherit git-r3
else
	KEYWORDS="-* ~amd64 ~x86"
	SRC_URI="https://dl.winehq.org/vkd3d/source/${P}.tar.xz"
fi

IUSE="doc demos ncurses spirv-tools xcb"
RDEPEND=">=media-libs/vulkan-loader-1.2.139[${MULTILIB_USEDEP}]
		ncurses? ( sys-libs/ncurses:= )
		spirv-tools? ( dev-util/spirv-tools:=[${MULTILIB_USEDEP}] )
		xcb? (
			x11-libs/xcb-util:=[${MULTILIB_USEDEP}]
			x11-libs/xcb-util-keysyms:=[${MULTILIB_USEDEP}]
			x11-libs/xcb-util-wm:=[${MULTILIB_USEDEP}]
		)"
DEPEND="${RDEPEND}
		>=dev-util/spirv-headers-1.2.139
		>=dev-util/vulkan-headers-1.2.139"
BDEPEND="
		doc? (
			app-doc/doxygen
			app-text/texlive
		)
		sys-devel/flex
		sys-devel/bison
		virtual/pkgconfig"

DESCRIPTION="D3D12 to Vulkan translation library"
HOMEPAGE="https://source.winehq.org/git/vkd3d.git/"

LICENSE="LGPL-2.1"
SLOT="0"

_install_demos() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local demo_path="${1}" demo_bin

	pushd "${demo_path}" || die "pushd failed"
	while IFS= read -r -d '' demo_bin; do
		newbin "${demo_bin}" "${PN}-${demo_bin}"
	done < <(find . -maxdepth 1 -executable -type f -printf '%f\0' 2>/dev/null)
	popd || die "popd failed"
}

src_prepare() {
	default
	eautoreconf
}

multilib_src_configure() {
	local myconf=(
		"$(use_enable doc doxygen-doc)"
		"$(multilib_native_use_enable demos)"
		"$(multilib_native_use_with ncurses)"
		"$(use_with spirv-tools)"
		"$(use_with xcb)"
	)

	ECONF_SOURCE=${S} econf "${myconf[@]}"
}

multilib_src_install() {
	default

	multilib_is_native_abi || return

	dobin ".libs/vkd3d-compiler"
	if use demos; then
		_install_demos "${BUILD_DIR}/demos/.libs/"
	fi
	if use doc; then
		dodoc -r "doc/html"
		dodoc "doc/${PN}.pdf"
	fi
}

multilib_src_install_all() {
	find "${ED}" -type f -name '*.la' -delete || die
}
