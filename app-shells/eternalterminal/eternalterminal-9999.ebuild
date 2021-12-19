# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit cmake systemd

DESCRIPTION="Re-connectable secure remote shell"
HOMEPAGE="https://eternalterminal.dev"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	SRC_URI=""
	KEYWORDS=""
	EGIT_REPO_URI="https://github.com/MisterTea/EternalTerminal"
else
	MY_PN="EternalTerminal-et"
	MY_P="${MY_PN}-v${PV}"
	SRC_URI="https://github.com/MisterTea/EternalTerminal/archive/et-v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/${MY_P}"
fi

LICENSE="Apache-2.0"
SLOT="0"
IUSE="selinux systemd utempter"

DEPEND="
	dev-libs/libsodium
	dev-cpp/gflags
	dev-libs/protobuf
	app-arch/unzip
	net-misc/wget
	selinux? ( sys-libs/libselinux )
	systemd? ( sys-apps/systemd )
	utempter? ( sys-libs/libutempter )
"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-6.1.9-fix_cmake_optional_packages.patch"
	"${FILESDIR}/${P}-fix_const_typing.patch"
)

src_configure() {
	local mycmakeargs=(
		"-DDISABLE_VCPKG=ON"
		"-DWITH_SELINUX=$(usex selinux)"
		"-DWITH_UTEMPTER=$(usex utempter)"
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install

	insinto "/etc"
	doins "etc/et.cfg"
	use systemd && systemd_dounit "systemctl/et.service"
}
