# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

inherit bash-completion-r1 versionator

DESCRIPTION="Phoronix's comprehensive, cross-platform testing and benchmark suite"
HOMEPAGE="http://www.phoronix-test-suite.com"
SRC_URI=""

LICENSE="GPL-3"
SLOT="0"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	EGIT3_STORE_DIR="${T}"
	inherit git-r3
	SRC_URI=""
	KEYWORDS=""
else
	major_version="$(get_version_component_range 1-3)"
	minor_version="$(get_version_component_range 4)"
	MY_PV="${major_version}"
	MY_P="${PN}-${MY_PV}"
	KEYWORDS="~amd64 ~x86"
	if [ ! -z "${minor_version}" ]; then
		KEYWORDS=""
		MY_PV="${MY_PV}${minor_version/pre/m}"
		MY_P="${MY_P}${minor_version/pre/m}"
	fi
	SRC_URI="https://github.com/phoronix-test-suite/${PN}/archive/v${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	S="${WORKDIR}/${MY_P}"
	unset -v minor_version major_version
fi

IUSE="sdl"

DEPEND=""
RDEPEND="${DEPEND}
		app-arch/p7zip
		media-libs/libpng
		>=dev-lang/php-5.3:=[cli,curl,gd,json,posix,pcntl,sockets,truetype,zip]
		www-servers/apache
		x11-base/xorg-server
		sdl? (
			media-libs/libsdl
			media-libs/sdl-net
			media-libs/sdl-image
			media-libs/libsdl2
			media-libs/sdl2-net
			media-libs/sdl2-image
			media-libs/sdl2-mixer

		)"

check_php_config()
{
	local slot
	for slot in $(eselect --brief php list cli); do
		local php_dir="etc/php/cli-${slot}"
		if [[ -f "${ROOT}${php_dir}/php.ini" ]]; then
			dodir "${php_dir}"
			cp -f "${ROOT}${php_dir}/php.ini" "${D}${php_dir}/php.ini" \
					|| die "cp failed: copy php.ini file"
			sed -i -e 's|^allow_url_fopen .*|allow_url_fopen = On|g' "${D}${php_dir}/php.ini" \
					|| die "sed failed: modify php.ini file"
		elif [[ "$(eselect php show cli)" == "${slot}" ]]; then
			ewarn "${slot} does not have a php.ini file."
			ewarn "${PN} needs the 'allow_url_fopen' option set to \"On\""
			ewarn "for downloading to work properly."
			ewarn
		else
			elog "${slot} does not have a php.ini file."
			elog "${PN} may need the 'allow_url_fopen' option set to \"On\""
			elog "for downloading to work properly if you switch to ${slot}"
			elog
		fi
	done
}

get_optional_dependencies()
{
	awk '{
		category=($0 ~ "<(GenericName|Name)>")
		packages=($0 ~ "<(PackageName|PackageManager)>")
		if ($0 ~ "<FileCheck>")
			next
		sub("^[[:blank:]]*<[^>]*>","")
		sub("<\/[^>]*>[[:blank:]]*$", (category ? ":" : ""))
		if ($0 ~ "^[[:blank:]]$")
			next
		padding=""
		if (category)
			padding=sprintf("%*s",25-length($0)," ")
		else if (packages)
			padding="\n"
		printf("%s%s", $0, padding)
		}' \
		"${EROOT%/}/usr/share/phoronix-test-suite/pts-core/external-test-dependencies/xml/gentoo-packages.xml"
}

src_prepare() {
	# BASH completion helper function "have" test is depreciated
	sed -i -e '/^have phoronix-test-suite &&$/d' "${S}/pts-core/static/bash_completion" \
			|| die "sed failed: remove PTS bash completion have test"
	# Remove all dependency resolving shell scripts - security vulnerability
	rm -rf "${S}/pts-core/external-test-dependencies/scripts"
	eapply_user
}

src_install() {
	newbashcomp pts-core/static/bash_completion "${PN}"
	DESTDIR="${D}" "${S}/install-sh" "${EPREFIX%/}/usr"

	# Fix the cli-php config for downloading to work.
	check_php_config
}

pkg_postinst() {
	gnome2_icon_cache_update
	fdo-mime_desktop_database_update

	ewarn "${PN} has the following optional package dependencies:"
	ewarn "$(get_optional_dependencies)"
}
