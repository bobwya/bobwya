# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit cmake systemd

DESCRIPTION="Re-connectable secure remote shell"
HOMEPAGE="https://eternalterminal.dev"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/MisterTea/EternalTerminal"
else
	MY_PN="EternalTerminal-et"
	MY_P="${MY_PN}-v${PV}"
	SRC_URI="https://github.com/MisterTea/EternalTerminal/archive/et-v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="+client +sentry selinux +server systemd utempter"
REQUIRED_USE="
	|| ( client server )
	systemd? ( server )"

DEPEND="
	dev-cpp/catch
	dev-cpp/cpp-httplib
	dev-cpp/nlohmann_json
	dev-libs/cxxopts
	dev-libs/jsoncpp
	dev-libs/libsodium
	dev-libs/protobuf
	app-arch/unzip
	net-misc/wget
	selinux? ( sys-libs/libselinux )
	systemd? ( sys-apps/systemd )
	utempter? ( sys-libs/libutempter )
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${P}-fix_cmake_package_detection.patch"
	"${FILESDIR}/${P}-sentry_native_support_gcc_13.patch"
)

src_configure() {
	local mycmakeargs=(
		"-DWITH_SELINUX=$(usex selinux)"
		"-DWITH_SENTRY=$(usex sentry)"
		"-DWITH_UTEMPTER=$(usex utempter)"
	)

	cmake_src_configure
}

src_install() {
	if use client; then
		for client_bin in "et" "htm" "htmd"; do
			dobin "${BUILD_DIR}/${client_bin}"
		done
	fi

	if use server; then
		for server_bin in "etserver" "etterminal"; do
			dobin "${BUILD_DIR}/${server_bin}"
		done
		insinto "/etc"
		doins "etc/et.cfg"
		use systemd && systemd_dounit "systemctl/et.service"
	fi
}
