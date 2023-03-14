# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/get-iplayer/${PN}.git"
else
	KEYWORDS="-* ~amd64 ~x86"
	SRC_URI="https://github.com/get-iplayer/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"
fi

DESCRIPTION="A utility for downloading programmes from BBC iPlayer and BBC Sounds"
HOMEPAGE="https://github.com/get-iplayer/get_iplayer"

LICENSE="GPL-3"
SLOT="0"
IUSE=""

RDEPEND="
		dev-perl/CGI
		dev-perl/libwww-perl
		dev-perl/LWP-Protocol-https
		dev-perl/Mojolicious
		dev-perl/XML-Simple
		dev-perl/XML-LibXML
		media-video/atomicparsley
		media-video/ffmpeg
		virtual/perl-JSON-PP
"
DEPEND=""

src_prepare() {
	sed -i \
		-e "/default[[:blank:]]*=>[[:blank:]]*10,/{s/10,/10000,/}" \
		-e "s/[[]'10','25','50','100','200','400'[]]/['10','100','1000','10000']/" \
			"${S}/get_iplayer.cgi" \
		|| die "sed failed"
	default
}

src_install() {
	dobin "${PN}" "${PN}.cgi"
	doman "${PN}.1"
	dodoc "README.md" "CHANGELOG.md" "CONTRIBUTORS"
}
