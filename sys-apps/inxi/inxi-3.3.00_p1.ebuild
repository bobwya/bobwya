# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

DESCRIPTION="Perl script that collects and displays system information."
HOMEPAGE="https://github.com/smxi/inxi"

if [ "${PV}" = "9999" ]; then
	inherit git-r3
	MY_P="${P}"
	EGIT_REPO_URI="https://github.com/smxi/${PN}.git"
	KEYWORDS=""
else
	MY_PV="${PV/_p/-}"
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://github.com/smxi/${PN}/archive/${MY_PV}.tar.gz -> ${MY_P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="
	app-text/tree
	dev-lang/perl:0=
	dev-perl/Cpanel-JSON-XS
	sys-apps/pciutils
	sys-apps/usbutils
	virtual/perl-HTTP-Tiny
	virtual/perl-IO-Socket-IP
	virtual/perl-Time-HiRes
	"

S="${WORKDIR}/${MY_P}"

get_recommended_packages() {
	local inxi_bin="${ROOT}/usr/bin/inxi"
	[[ -f "${inxi_bin}" ]] || die "inxi script not valid"

	"${inxi_bin}" --recommends | awk \
	'function dump_array(out_array,
			i) {
		for (i=1; i<=out_array[0]; ++i) {
				printf("%s\n", out_array[i])
		}
	}

	BEGIN{
		section_regex="^\-\-\-\-"
	}
	{
		if ($0 ~ section_regex) {
			if (dump_section) {
				++block_number
				array_section[++array_section[0]]=$0
				dump_array(array_section)
				dump_section=0
			}
			delete array_section
			if (block_number == 0)
				array_section[++array_section[0]]=$0
		}

		if (($NF == "Present") || ($0 ~ section_regex))
			next

		dump_section=dump_section || ($NF == "Missing")
		array_section[++array_section[0]]=$0
	}
	END{
		if (dump_section)
			dump_array(array_section)
	}' 2>/dev/null
}

src_install() {
		dobin "${PN}"
		doman "${PN}.1"
}

pkg_postinst() {
	ewarn "Please run:  emerge --config =${CATEGORY}/${P}"
	ewarn "to check optional package dependencies."
	ewarn
}

pkg_config() {
	ewarn "$(get_recommended_packages)"
}
