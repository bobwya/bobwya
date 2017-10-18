# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=6

inherit autotools

DESCRIPTION="Fork of djbdns, a collection of DNS client/server software"
HOMEPAGE="http://pjp.dgplug.org/djbdns/index.html"

if [ "${PV}" == "9999" ]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/pjps/${PN}.git"
	SRC_URI=""
else
	COMMIT_ID="64d371b6f887621de7bf8bd495be10442b2accd0"
	SRC_URI="https://github.com/pjps/${PN}/archive/${COMMIT_ID}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="!!net-dns/djbdns
	!!sys-apps/ucspi-tcp"

src_prepare() {
	# Make sure root servers file is up to date.
	local root_servers
	root_servers=$(curl -s http://www.internic.net/domain/named.root | awk '{ if ($3 == "A") print $4; }')
	if [[ ! -z "${root_servers}" ]]; then
		echo "${root_servers}" > "${S}/etc/servers/dnsroots.global" || die "echo failed"
	fi

	eapply_user
	sed -i -e '\|^AM_CFLAGS|{s|-g -O2 ||g}' "Makefile.am" \
		|| die "sed failed"
	sed -i -e 's|/rc.d||' "etc/init.d/Makefile.am" \
		|| die "sed failed"
	eautoreconf
}

src_configure() {
	# Fix installation directory for systemd units
	local -a econf_args=( "--prefix=${EPREFIX%/}" )
	econf "${econf_args[@]}"
}