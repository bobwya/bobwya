# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CMAKE_MAKEFILE_GENERATOR=emake
NVCCFLAGS="-allow-unsupported-compiler"

inherit cmake cuda flag-o-matic

DESCRIPTION="NVIDIA CUDA plugin for XMRig miner"
HOMEPAGE="https://xmrig.com https://github.com/xmrig/xmrig-cuda"

if [[ "${PV}" == *"9999" ]] ; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/xmrig/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-3+"
SLOT="0"
IUSE=""

DEPEND="
	dev-libs/libuv:=
	dev-util/nvidia-cuda-toolkit:=
"
RDEPEND="
	${DEPEND}
"

PATCHES=( "${FILESDIR}/${P}-drop_unsupported_cuda_versions.patch" )

src_prepare() {
	cuda_src_prepare
	declare -a mycmakeargs=(
		"-DCUDA_CUDART_LIBRARY=${ESYSROOT}/opt/cuda/$(get_libdir)/libcudart.so"
		"-DCUDA_NVCC_FLAGS=${NVCCFLAGS}"
		"-DNVCCFLAGS=${NVCCFLAGS}"
		"-DCUDA_TOOLKIT_ROOT_DIR=${ESYSROOT}/opt/cuda/"
		"-DCUDA_ROOT=${ESYSROOT}/opt/cuda/"
	)

	append-cflags "-I${ESYSROOT}/opt/cuda/include"
	append-cppflags "-I${ESYSROOT}/opt/cuda/include"

	cmake_src_prepare
}

src_configure() {
	local -x LDFLAGS="${LDFLAGS}"
	append-ldflags -L"${ESYSROOT}/opt/cuda/$(get_libdir)"

	cmake_src_configure
}

src_install() {
	pushd "${BUILD_DIR}" || die "pushd failed"
	insinto "/usr/$(get_libdir)"
	insopts -m 755
	doins "libxmrig-cuda.so"
	popd || die "popd failed"
	einstalldocs
}
