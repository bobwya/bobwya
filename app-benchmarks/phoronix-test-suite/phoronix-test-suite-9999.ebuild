# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=8

inherit bash-completion-r1 optfeature

DESCRIPTION="Phoronix's comprehensive, cross-platform testing and benchmark suite"
HOMEPAGE="http://www.phoronix-test-suite.com"

LICENSE="GPL-3"
SLOT="0"

if [[ ${PV} == "9999" ]] ; then
	EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
	EGIT3_STORE_DIR="${T}"
	inherit git-r3
else
	major_version="$(ver_cut 1-3)"
	minor_version="$(ver_cut 4-5)"
	MY_PV="${major_version}"
	MY_P="${PN}-${MY_PV}"
	KEYWORDS="-* ~amd64 ~x86"
	if [ -n "${minor_version}" ]; then
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
		>=dev-lang/php-5.3[cli,curl,gd,posix,pcntl,sockets,ssl,truetype,xml,zip,zlib]
		dev-php/fpdf
		www-servers/apache
		sdl? (
			media-libs/libsdl
			media-libs/sdl-net
			media-libs/sdl-image
			media-libs/libsdl2
			media-libs/sdl2-net
			media-libs/sdl2-image
			media-libs/sdl2-mixer

		)"

check_php_config() {
	local slot
	for slot in $(eselect --brief php list cli); do
		local php_dir="/etc/php/cli-${slot}"

		if [[ -f "${EROOT}${php_dir}/php.ini" ]]; then
			dodir "${php_dir}"
			cp -f "${EROOT}${php_dir}/php.ini" "${ED}${php_dir}/php.ini" \
					|| die "cp failed: copy php.ini file"
			sed -i -e 's|^allow_url_fopen .*|allow_url_fopen = On|g' "${ED}${php_dir}/php.ini" \
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

src_prepare() {
	# BASH completion helper function "have" test is depreciated
	sed -i -e '/^have phoronix-test-suite &&$/d' "${S}/pts-core/static/bash_completion" \
			|| die "sed failed: remove PTS bash completion have test"
	# Remove all dependency resolving shell scripts - security vulnerability
	rm -rf "${S}/pts-core/external-test-dependencies/scripts"
	eapply_user
}

src_install() {
	# Store the contents of this file - since it will be installed / deleted before we need it.
	GENTOO_OPTIONAL_PKGS_XML="$(cat "${S}/pts-core/external-test-dependencies/xml/gentoo-packages.xml")"
	newbashcomp pts-core/static/bash_completion "${PN}"
	DESTDIR="${D}" "${S}/install-sh" "${EPREFIX}/usr"

	# Fix the cli-php config for downloading to work.
	check_php_config
}

pkg_postinst() {
	optfeature_header "Tthe following are optional package dependencies:"
	optfeature "csh" app-shells/tcsh
	optfeature "mongodb" dev-db/mongodb
	optfeature "redis-server" dev-db/redis
	optfeature "maven" dev-java/maven-bin
	optfeature "erlang" dev-lang/erlang
	optfeature "rust" dev-lang/rust
	optfeature "V8" dev-lang/R[java]
	optfeature "libconfigpp" dev-libs/libconfig
	optfeature "glibc-development" dev-libs/libpthread-stubs
	optfeature "tinyxml" dev-libs/tinyxml
	optfeature "perl-digest-md5" dev-perl/Digest-Perl-MD5
	optfeature "qt5-development" dev-qt/qtcore
	optfeature "jam" dev-util/ftjam
	optfeature "freeimage" media-libs/freeimage
	optfeature "glut" media-libs/freeglut
	optfeature "lib3ds" media-libs/lib3ds
	optfeature "portaudio-development" media-libs/portaudio
	optfeature "vaapi" media-video/libva-utils
	optfeature "atlas-development" sci-libs/atlas
	optfeature "python-sklearn" sci-libs/scikit-learn
	optfeature "python-scipy" dev-python/scipy
	optfeature "suitesparse" sci-libs/suitesparse
	optfeature "superlu" sci-libs/superlu
	optfeature "openmpi-development" sys-cluster/openmpi
	optfeature "uuid" sys-libs/libuuid
	optfeature "libstdcpp" sys-libs/libstdc++-v3
	optfeature "jpeg-development" virtual/jpeg
	optfeature "wine" virtual/wine
	optfeature "xorg-video" x11-libs/libXvMC
}
