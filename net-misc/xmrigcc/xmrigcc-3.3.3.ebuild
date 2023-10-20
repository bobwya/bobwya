# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake flag-o-matic systemd toolchain-funcs

CUDA_PV="6.17.0"
MY_PN="${PN%cc}CC"

DESCRIPTION="XMRigCC is an open source RandomX, GhostRider, KawPow, CryptoNight CPU/GPU miner"
HOMEPAGE="https://github.com/Bendr0id/xmrigCC"

if [[ ${PV} == *9999 ]] ; then
	EGIT_REPO_URI="https://github.com/Bendr0id/${MY_PN}.git"
	inherit git-r3
else
	SRC_URI="https://github.com/Bendr0id/${MY_PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64"
fi

LICENSE="Apache-2.0 GPL-3+ MIT"
SLOT="0"
IUSE="cpu_flags_x86_sse4_1 +ccclient +ccclientexec +ccserver cuda donate +http hwloc opencl +ssl"
REQUIRED_USE="http? ( ssl )"

DEPEND="
	dev-libs/libuv:=
	cuda? ( ~net-misc/xmrig-cuda-${CUDA_PV} )
	hwloc? ( >=sys-apps/hwloc-2.5.0:= )
	opencl? ( virtual/opencl )
	ssl? ( dev-libs/openssl:= )
"
RDEPEND="
	${DEPEND}
	!arm64? ( sys-apps/msr-tools )
"

S="${WORKDIR}/${MY_PN}-${PV}"

src_prepare() {
	if ! use donate ; then
		sed -i -e '/DonateLevel = /{s/[0-9]\+;/0;/g}' \
			"src/donate.h" \
			|| die "sed failed"
	fi
	if use opencl; then
		PATCHES+=( "${FILESDIR}/${PN}-3.3.3-fix_opencl_support.patch" )
	fi
	cmake_src_prepare
}

src_configure() {
	# JIT broken with FORTIFY_SOURCE=3
	# Bug #913420
	if tc-enables-fortify-source; then
		filter-flags -D_FORTIFY_SOURCE=3
		append-cppflags -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2
	fi

	local mycmakeargs=(
		-DWITH_CC_CLIENT=$(usex ccclient)
		-DWITH_CC_SHELL_EXEC=$(usex ccclientexec)
		-DWITH_CC_SERVER=$(usex ccserver)
		-DWITH_SSE4_1=$(usex cpu_flags_x86_sse4_1)
		-DWITH_HWLOC=$(usex hwloc)
		-DWITH_HTTP=$(usex http)
		-DWITH_TLS=$(usex ssl)
		-DWITH_OPENCL=$(usex opencl)
		-DWITH_CUDA=$(usex cuda)
	)

	cmake_src_configure
}

src_install() {
	default
	keepdir "/etc/xmrigcc"
	systemd_dounit "${FILESDIR}/xmrigcc.service"
	dobin "${BUILD_DIR}/xmrigDaemon"
	dobin "${BUILD_DIR}/xmrigMiner"
	dobin "${BUILD_DIR}/xmrigServer"
	for sh in "enable_1gb_pages.sh" "randomx_boost.sh"; do
		newbin "${S}/scripts/${sh}" "${PN}_${sh}"
	done
	dodoc doc/*.md
}
