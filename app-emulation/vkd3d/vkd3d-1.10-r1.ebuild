# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit autotools multilib-minimal

if [[ "${PV}" == "9999" ]]; then
	EGIT_REPO_URI="https://source.winehq.org/git/vkd3d.git"
	inherit git-r3
else
	KEYWORDS="-* ~amd64 ~x86"
	SRC_URI="https://dl.winehq.org/vkd3d/source/${P}.tar.xz"
fi

IUSE="doc demos ncurses opengl spirv-tools xcb"
RESTRICT="test" # see: https://bugs.gentoo.org/838655

RDEPEND=">=media-libs/vulkan-loader-1.3.228[${MULTILIB_USEDEP}]
		ncurses? ( sys-libs/ncurses:= )
		spirv-tools? ( dev-util/spirv-tools:=[${MULTILIB_USEDEP}] )
		xcb? (
			x11-libs/xcb-util:=[${MULTILIB_USEDEP}]
			x11-libs/xcb-util-keysyms:=[${MULTILIB_USEDEP}]
			x11-libs/xcb-util-wm:=[${MULTILIB_USEDEP}]
		)"
DEPEND="${RDEPEND}
		>=dev-util/spirv-headers-1.3.228
		>=dev-util/vulkan-headers-1.3.228
		opengl?  ( media-libs/mesa[X(+),${MULTILIB_USEDEP}] )"
BDEPEND="
		sys-devel/flex
		sys-devel/bison
		virtual/pkgconfig
		doc? ( app-text/doxygen[doc] )"

DESCRIPTION="D3D12 to Vulkan translation library"
HOMEPAGE="https://source.winehq.org/git/vkd3d.git/"

LICENSE="LGPL-2.1"
SLOT="0"

_fix_idl_header_paths() {
	local idl_input_file
	local output_header_file
	local output_header_full_path

	while read -r idl_input_file; do
		output_header_file="${idl_input_file%.idl}"
		output_header_full_path="${S}/${output_header_file}"
		sed -i -e "s|${output_header_file}|${output_header_full_path}|g" \
			"Makefile.am" \
			|| die "sed failed"
	done < <(find "tests/" -type f -name "*.idl" -printf '%f\0' 2>/dev/null)
}

_install_demos() {
	local demo_bin

	while IFS= read -r -d '' demo_bin; do
		newbin "${demo_bin}" "${PN}-${demo_bin}"
	done < <(find . -maxdepth 1 -executable -type f -printf '%f\0' 2>/dev/null)
}

src_prepare() {
	_fix_idl_header_paths
	default
	eautoreconf
}

multilib_src_configure() {
	local myconf=(
		"$(use_enable doc doxygen-doc)"
		"$(multilib_native_use_enable demos)"
		"$(multilib_native_use_with ncurses)"
		"$(use_with opengl)"
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
		_install_demos
	fi
	if use doc; then
		dodoc -r "doc/html"
		dodoc "doc/${PN}.pdf"
	fi
}

multilib_src_install_all() {
	find "${ED}" -type f -name '*.la' -delete || die
}
