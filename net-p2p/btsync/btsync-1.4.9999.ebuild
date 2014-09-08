# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils pax-utils user flag-o-matic multilib autotools pam systemd versionator

DESCRIPTION="Sync files & folders using BitTorrent protocol"
HOMEPAGE="http://labs.bittorrent.com/experiments/sync.html"
SRC_URI="amd64? ( http://download-new.utorrent.com/endpoint/${PN}/os/linux-x64/track/stable -> ${PN}.tar.gz )
	x86? ( http://download-new.utorrent.com/endpoint/${PN}/os/linux-i386/track/stable -> ${PN}.tar.gz )
	ppc? ( http://download-new.utorrent.com/endpoint/${PN}/os/linux-powerpc/track/stable -> ${PN}.tar.gz )
	arm? ( http://download-new.utorrent.com/endpoint/${PN}/os/linux-arm/track/stable -> ${PN}.tar.gz )"

RESTRICT="mirror strip"
LICENSE="BitTorrent"
SLOT="0"
KEYWORDS="**"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${WORKDIR}"

QA_PREBUILT="/opt/${PN}/"

src_install() {
	dodoc "${S}/LICENSE.TXT"

	newconfd "${FILESDIR}/${PN}_confd" "/${PN}"
	
	# system-v-init support
	newinitd "${FILESDIR}/${PN}_initd" "/${PN}"
	
	# systemd support
	systemd_dounit "${FILESDIR}/${PN}.service"
	systemd_newunit "${FILESDIR}/${PN}_at.service" "${PN}@.service"
	systemd_newuserunit "${FILESDIR}/${PN}_user.service" "${PN}.service"

	exeinto "/opt/${PN}/bin"
	doexe "${FILESDIR}/${PN}_setup"
	doexe "${PN}"
}

pkg_preinst() {
	enewgroup "${PN}"
	enewuser "${PN}" -1 -1 -1 "${PN}"
	dodir "/run/${PN}"
	fowners "${PN}":"${PN}" "/run/${PN}"
	dodir "/var/lib/${PN}"
	fowners "${PN}":"${PN}" "/var/lib/${PN}"
	# Dirty hack to create system configuration file!
	STORAGE_PATH="/var/lib/${PN}"
	PID_FILE="/run/${PN}/${PN}.pid"
	"${D}/opt/${PN}/bin/${PN}" --dump-sample-config > "${D}/${PN}.conf"
	sed -i \
        -e "s|\"password\" : \"password\"|\"password\" : \"\"|"	\
        -e "s|\"device_name\": \"My Sync Device\"|\"device_name\": \"$(hostname -f 2>/dev/null||hostname)\"|"	\
        -e "s|\"login\" : \"admin\"|\"login\" : \"${PN}\"|"														\
        -e "s|\"listen\" : \"0.0.0.0:8888\"|\"listen\" : \"127.0.0.1:8888\"|"					\
        -e "s|\"storage_path\" : \"/home/user/.sync\"|\"storage_path\" : \"${STORAGE_PATH}\"|"					\
        -e "/\/\/ uncomment next line if you want to set location of pid file/d" 								\
        -e "s|\/\/ \"pid_file\" : \"/var/run/${PN}/${PN}.pid\"|   \"pid_file\" : \"${PID_FILE}\"|" "${D}/${PN}.conf"
	insinto "/etc"
	doins "${D}/${PN}.conf"
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
