# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils

DESCRIPTION="A C++ development library for implementing lightweight HTTP interfaces"
HOMEPAGE="https://github.com/cloudmeter/pion"
SRC_URI="https://github.com/cloudmeter/pion/archive/${PV}.tar.gz"

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="+bzip2 debug doc logging log4cplus log4cxx log4cpp +ssl static-libs +zlib"

RDEPEND=">=dev-libs/boost-1.35.0[threads]
		bzip2? ( >=app-arch/bzip2-1.0.6 )
		log4cplus? ( >=dev-libs/log4cplus-1.0.3 )
		log4cxx? ( >=dev-libs/log4cxx-0.9.7 )
		log4cpp? ( dev-libs/log4cpp )
		ssl? ( >=dev-libs/openssl-0.9.8:0 )
		zlib? ( >=sys-libs/zlib-1.2.3 )
		!dev-cpp/pion-net"
DEPEND="${RDEPEND}
		>=dev-util/cmake-2.8.10
		doc? ( app-doc/doxygen )"
REQUIRED_USE="
		log4cplus? ( logging !log4cxx !log4cpp )
		log4cxx?   ( logging !log4cplus !log4cpp )
		log4cpp?   ( logging !log4cplus !log4cxx )"

pkg_pretend() {
	if  [[ $(gcc-version) < 4.1 ]]; then
		ewarn "gcc >= 4.1 is required to build ${PN}"
		ewarn "Make sure you set a suitable version of gcc with gcc-config"
	fi
}

src_prepare() {
	# Force generation of man, ps & pdf documentation files
	# (ps & pdf only if required Latex packages are installed).
	local generate_latex=false
	has_version dev-texlive/texlive-latex \
		&& has_version dev-texlive/texlive-latexextra \
		&& generate_latex=true
	if use doc; then
		# Force generation of man page, ps & pdf documentation with doxygen - appears to be broken?
		# (ps & pdf are only built if the required Latex packages are installed).
		sed -i -e 's/GENERATE\_MAN\(.*\)=\(.*\)NO/GENERATE_MAN\1=\2YES/g' \
				"${S}/doc/Doxyfile" \
				|| die "sed: unable to process ${S}/doc/Doxyfile to enable man page support"
		if [[ ${generate_latex} == true ]]; then
			sed -i \
				-e 's/GENERATE\_LATEX\(.*\)=\(.*\)NO/GENERATE_LATEX\1=\2YES/g' \
				-e 's/USE\_PDFLATEX\(.*\)=\(.*\)NO/USE_PDFLATEX\1=\2YES/g' \
					"${S}/doc/Doxyfile" \
				|| die "sed: unable to process ${S}/doc/Doxyfile to enable Latex support"
		fi
	fi
	"${S}/autogen.sh"
	# disable forced enabling of ggdb support
	epatch "${FILESDIR}/${PN}-5.0.1-disable_release_ggdb.patch"
}

src_configure() {
	local my_conf
	if use doc; then
		my_conf="--enable-doxygen-man --enable-doxygen-html"
		if [[ ${generate_latex} == true ]]; then
			my_conf="${my_conf} --enable-doxygen-pdf --enable-doxygen-ps"
		fi
	fi
	if use logging; then
		if use log4cplus; then
			my_conf="${my_conf} --with-log4cplus"
		elif use log4cxx; then
			my_conf="${my_conf} --with-log4cxx"
		elif use log4cpp; then
			my_conf="${my_conf} --with-log4cpp"
		else
			my_conf="${my_conf} --with-ostream-logging"
		fi
	fi
	econf \
			${my_conf} \
			$(use_with debug) \
			$(use_with bzip2 bzlib) \
			$(use_with zlib) \
			$(use_with ssl openssl) \
			$(use_enable doc doxygen-doc) \
			$(use_enable logging) \
			$(use_enable static-libs static)
	unset my_conf
}

src_compile() {
	emake all
	if use doc; then
		# Force single threaded build for Latex-based documentation
		if [[ ${generate_latex} == true ]]; then
			emake -j1 doxygen-doc
		else
			emake doxygen-doc
		fi
	fi
}

src_install() {
	emake DESTDIR="${D}" install

	dodoc AUTHORS ChangeLog doc/README* NEWS README.md TODO
	if use doc; then
		if [[ ${generate_latex} == true ]]; then
			dodoc doc/${PN}.*
		fi
		docinto "html"
		dodoc doc/html/*
		doman doc/man/man3/*.3
	fi
}

pkg_postinst() {
	if [[ ${generate_latex} == false ]]; then
		einfo
		einfo "${CATEGORY}/${PN}[doc] can make use of the following optional buildtime dependencies "
		einfo "to build postscript and pdf documentation:"
		einfo "dev-texlive/texlive-latex dev-texlive/texlive-latexextra"
	fi
	if ! has_version dev-libs/yajl; then
		einfo
		einfo "${CATEGORY}/${PN} can make use of the dev-libs/yajl optional buildtime dependency."
		einfo "YAJL is required to build support for the JSONCodec plugin."
	fi
	unset generate_latex
}
