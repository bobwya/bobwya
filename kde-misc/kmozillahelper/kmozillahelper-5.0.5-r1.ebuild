# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=8

inherit ecm kde.org

DESCRIPTION="Mozilla KDE Desktop Integration"
HOMEPAGE="https://github.com/openSUSE/kmozillahelper"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/openSUSE/kmozillahelper.git"
	inherit git-r3
else
	SRC_URI="https://github.com/openSUSE/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"
fi

LICENSE="MIT"
SLOT="5"
IUSE=""

COMMON_DEPEND="
	kde-frameworks/kconfig:5
	kde-frameworks/kconfigwidgets:5
	kde-frameworks/kcoreaddons:5
	kde-frameworks/kcrash:5
	kde-frameworks/kdbusaddons:5
	kde-frameworks/kguiaddons:5
	kde-frameworks/ki18n:5
	kde-frameworks/kio:5
	kde-frameworks/knotifications:5
	kde-frameworks/kservice:5
	kde-frameworks/kwidgetsaddons:5
	kde-frameworks/kwindowsystem:5
	dev-qt/qtconcurrent:5
	dev-qt/qtdbus:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
"
DEPEND="${COMMON_DEPEND}
	kde-frameworks/kinit:5
	dev-libs/mpfr:0
	sys-devel/gettext
"
RDEPEND="${COMMON_DEPEND}"

src_prepare() {
	# Don't allow running as root: may break sandboxing during Portage-based
	# install of Mozilla applications (Firefox)
	# See https://github.com/bobwya/bobwya/issues/7#issuecomment-202017441
	local PATCHES=(
		"${FILESDIR}/${PN}-5.0.5-dont_run_as_root.patch"
	)

	ecm_src_prepare
}

src_configure() {
	local mycmakeargs=()

	ecm_src_configure
}

pkg_postinst() {
	ecm_pkg_postinst
}
