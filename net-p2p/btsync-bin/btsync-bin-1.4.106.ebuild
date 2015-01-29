# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils pax-utils user flag-o-matic multilib autotools pam systemd versionator

DESCRIPTION="Sync files & folders using BitTorrent protocol"
HOMEPAGE="http://labs.bittorrent.com/experiments/sync.html"

MY_PN="${PN%-bin}"
SRC_URI="amd64? ( http://syncapp.bittorrent.com/${PV}/${MY_PN}_x64-${PV}.tar.gz )
	x86? ( http://syncapp.bittorrent.com/${PV}/${MY_PN}_i386-${PV}.tar.gz )
	ppc? ( http://syncapp.bittorrent.com/${PV}/${MY_PN}_powerpc-${PV}.tar.gz )
	arm? ( http://syncapp.bittorrent.com/${PV}/${MY_PN}_arm-${PV}.tar.gz )"
RESTRICT="mirror strip"
LICENSE="BitTorrent"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~arm ~ppc"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}"

QA_PREBUILT="/opt/${MY_PN}/"

src_install() {
	dodoc "${S}/LICENSE.TXT"

	newconfd "${FILESDIR}/${MY_PN}_confd" "/${MY_PN}"
	
	# system-v-init support
	newinitd "${FILESDIR}/${MY_PN}_initd" "/${MY_PN}"
	
	# systemd support
	systemd_dounit "${FILESDIR}/${MY_PN}.service"
	systemd_newunit "${FILESDIR}/${MY_PN}_at.service" "${MY_PN}@.service"
	systemd_newuserunit "${FILESDIR}/${MY_PN}_user.service" "${MY_PN}.service"

	exeinto "/opt/${MY_PN}/bin"
	doexe "${FILESDIR}/${MY_PN}_setup"
	doexe "${MY_PN}"
}

pkg_preinst() {
	enewgroup "${MY_PN}"
	enewuser "${MY_PN}" -1 -1 -1 "${MY_PN}"
	dodir "/run/${MY_PN}"
	fowners "${MY_PN}":"${MY_PN}" "/run/${MY_PN}"
	dodir "/var/lib/${MY_PN}"
	fowners "${MY_PN}":"${MY_PN}" "/var/lib/${MY_PN}"
	# Dirty hack to create system configuration file!
	STORAGE_PATH="/var/lib/${MY_PN}"
	PID_FILE="/run/${MY_PN}/${MY_PN}.pid"
	"${D}/opt/${MY_PN}/bin/${MY_PN}" --dump-sample-config > "${D}/${MY_PN}.conf"
	sed -i \
        -e "s|\"password\" : \"password\"|\"password\" : \"\"|"	\
        -e "s|\"device_name\": \"My Sync Device\"|\"device_name\": \"$(hostname -f 2>/dev/null||hostname)\"|"	\
        -e "s|\"login\" : \"admin\"|\"login\" : \"${MY_PN}\"|"														\
        -e "s|\"listen\" : \"0.0.0.0:8888\"|\"listen\" : \"127.0.0.1:8888\"|"					\
        -e "s|\"storage_path\" : \"/home/user/.sync\"|\"storage_path\" : \"${STORAGE_PATH}\"|"					\
        -e "/\/\/ uncomment next line if you want to set location of pid file/d" 								\
        -e "s|\/\/ \"pid_file\" : \"/var/run/${MY_PN}/${MY_PN}.pid\"|   \"pid_file\" : \"${PID_FILE}\"|" "${D}/${MY_PN}.conf"
	insinto "/etc"
	doins "${D}/${MY_PN}.conf"
}

pkg_postinst() {
ewarn "Downgrading to branches 1.3, or earlier, is not possible after installing Sync 1.4 branch!"
ewarn "If you want to downgrade - please uninstall btsync and remove all settings."
ewarn "Then install the earlier branch (<1.4) and configure all folders from scratch."
einfo "Auto-generated configuration file is located at /etc/btsync.conf"
einfo "(use this file as a template for user-level privilege service units)"
einfo ""
einfo "systemd"
einfo "btsync.service:"
einfo " run as a system service as user/group btsync:btsync"
einfo " uses /var/lib/btsync for btsync working data"
einfo "btsync@<user>.service"
einfo " run as a system service but with user privilege"
einfo " uses /home/<user>/.btsync/btsync.conf for btsync working data"
einfo "btsync_user.service"
einfo " run as a standard user service"
einfo " uses /home/<user>/.btsync/btsync.conf for btsync working data"
einfo ""
einfo "Ensure you open the following ports in your firewall:"
einfo " btsync.conf specified sync listening port (UDP/TCP)"
einfo " port 3838 (UDP) for DHT tracking"
einfo ""
einfo "WebUI listens on:"
einfo "localhost:8888 (system)"
einfo "localhost:(8888+UID) (user)"
}
