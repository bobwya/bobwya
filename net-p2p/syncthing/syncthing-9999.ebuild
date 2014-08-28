# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: This ebuild is from mva overlay; Bumped by mva; $

EAPI=5

inherit eutils base systemd git-r3

if [ "$PV" != "9999" ]; then
	SRC_URI="https://github.com/syncthing/syncthing/archive/v${PV}.tar.gz"
else
	SRC_URI=""
	EGIT_REPO_URI="https://github.com/syncthing/${PN}"
	KEYWORDS=""
fi

KEYWORDS="~amd64 ~x86 ~arm ~darwin ~winnt ~fbsd"
DESCRIPTION="Syncthing replaces proprietary sync and cloud services with something open, trustworthy and decentralized."
HOMEPAGE="http://syncthing.net"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="tools"

DEPEND="
	dev-lang/go
	app-misc/godep
"
RDEPEND="${DEPEND}"

DOCS=( README.md CONTRIBUTORS LICENSE CONTRIBUTING.md )

export GOPATH="${S}"

GO_PN="github.com/syncthing/${PN}"
EGIT_CHECKOUT_DIR="${S}/src/${GO_PN}"
S="${EGIT_CHECKOUT_DIR}"

src_prepare() {
	ewarn "You should are recommended not to use the builtin upgrade-mechanism in this software."
}

src_compile() {
	# XXX: All the stuff below needs for "-version" command to show actual info
	local version="$(git describe --always)";
	local date="$(git show -s --format=%ct)";
	local user="$(whoami)"
	local host="$(hostname)"; host="${host%%.*}";
	local lf="-w -X main.Version ${version} -X main.BuildStamp ${date} -X main.BuildUser ${user} -X main.BuildHost ${host}"

	godep go build -ldflags "${lf}" ./cmd/syncthing

	use tools && (
		godep go build ./cmd/stcli
		godep go build ./cmd/stpidx
		godep go build ./discover/cmd/discosrv
	)
}

src_install() {
	dobin syncthing
	use tools && dobin stcli stpidx discosrv
	base_src_install_docs
	
	# systemd support
	systemd_dounit "${FILESDIR}/${PN}-discosrv.service"
	systemd_newunit "${FILESDIR}/${PN}_at.service" "${PN}@.service"
}
