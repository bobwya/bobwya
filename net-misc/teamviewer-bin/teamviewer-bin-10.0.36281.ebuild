# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/teamviewer/teamviewer-9.0.30203.ebuild,v 1.1 2014/07/16 16:14:55 hasufell Exp $

EAPI=5

inherit eutils gnome2-utils systemd unpacker

# Major version
MV=${PV/\.*}
MY_PN=${PN%-bin}
MY_PNV=${MY_PN}${MV}
DESCRIPTION="All-In-One Solution for Remote Access and Support over the Internet"
HOMEPAGE="http://www.teamviewer.com"
SRC_URI="http://www.teamviewer.com/download/version_${MV}x/teamviewer_linux.deb -> ${P}.deb"

LICENSE="TeamViewer !system-wine? ( LGPL-2.1 )"
SLOT=${MV}
KEYWORDS="~amd64 ~x86"
IUSE="system-wine"

RESTRICT="mirror"

RDEPEND="
	app-shells/bash
	x11-misc/xdg-utils
	!system-wine? (
		amd64? (
			app-emulation/emul-linux-x86-baselibs
			app-emulation/emul-linux-x86-soundlibs
			|| (
				(
					x11-libs/libSM[abi_x86_32]
					x11-libs/libX11[abi_x86_32]
					x11-libs/libXau[abi_x86_32]
					x11-libs/libXdamage[abi_x86_32]
					x11-libs/libXext[abi_x86_32]
					x11-libs/libXfixes[abi_x86_32]
					x11-libs/libXtst[abi_x86_32]
				)
				app-emulation/emul-linux-x86-xlibs
			)
		)
		x86? (
			sys-libs/zlib
			x11-libs/libSM
			x11-libs/libX11
			x11-libs/libXau
			x11-libs/libXdamage
			x11-libs/libXext
			x11-libs/libXfixes
			x11-libs/libXtst
		)
	)
	system-wine? ( app-emulation/wine )
	!net-misc/teamviewer:${MV}"

QA_PREBUILT="opt/teamviewer${MV}/*"

S="${WORKDIR}/opt/${MY_PN}/tv_bin"

make_winewrapper() {
	cat << EOF > "${T}/${MY_PNV}"
#!/bin/sh
export WINEDLLPATH=/opt/${MY_PNV}
exec wine "/opt/${MY_PNV}/TeamViewer.exe" "\$@"
EOF
	chmod go+rx "${T}/${MY_PNV}"
	exeinto /opt/bin
	doexe "${T}/${MY_PNV}"
}

src_prepare() {
	epatch "${FILESDIR}"/${P}-gentoo.patch

	sed \
		-e "s#@TVV@#${MV}/tv_bin#g" \
		"${FILESDIR}"/${MY_PN}d.init > "${T}"/${MY_PN}d${MV} || die
	sed -i "s:/opt/${MY_PN}/tv_bin/:/opt/${MY_PNV}/tv_bin/:g"		\
		"desktop/${MY_PN}-${MY_PN}.desktop"							\
		"script/${MY_PN}d.service"
}

src_install () {
	if use system-wine ; then
		make_winewrapper
		exeinto /opt/${MY_PNV}
		doexe wine/drive_c/TeamViewer/*
	else
		# install scripts and .reg
		insinto /opt/${MY_PNV}/tv_bin
		doins -r *

		exeinto /opt/${MY_PNV}/tv_bin
		doexe TeamViewer_Desktop
		exeinto /opt/${MY_PNV}/tv_bin/script
		doexe script/teamviewer script/tvw_{aux,config,exec,extra,main,profile}

		dosym /opt/${MY_PNV}/tv_bin/script/${MY_PNV} /opt/bin/${MY_PNV}

		# fix permissions
		fperms 755 /opt/${MY_PNV}/tv_bin/wine/bin/wine{,-preloader,server}
		fperms 755 /opt/${MY_PNV}/tv_bin/wine/drive_c/TeamViewer/TeamViewer.exe
		find "${D}"/opt/${MY_PNV} -type f -name "*.so*" -execdir chmod 755 '{}' \;
	fi

	# install daemon binary
	exeinto /opt/${MY_PNV}/tv_bin
	doexe ${MY_PN}d

	# set up logdir
	keepdir /var/log/${MY_PNV}
	dosym /var/log/${MY_PNV} /opt/${MY_PNV}/logfiles

	# set up config dir
	keepdir /etc/${MY_PNV}
	dosym /etc/${MY_PNV} /opt/${MY_PNV}/config

	doinitd "${T}"/${MY_PN}d${MV}
	systemd_newunit script/${MY_PN}d.service ${MY_PN}d${MV}.service

	newicon -s 48 desktop/${MY_PN}.png ${MY_PN}.png
	make_desktop_entry ${MY_PNV} TeamViewer ${MY_PNV}
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update

	if use system-wine ; then
		echo
		eerror "IMPORTANT NOTICE!"
		elog "Using ${MY_PN} with system wine is not supported and experimental."
		elog "Do not report gentoo bugs while using this version."
		echo
	fi

	eerror "STARTUP NOTICE:"
	elog "You cannot start the daemon via \"teamviewer --daemon start\"."
	elog "Instead use the provided gentoo initscript:"
	elog "  /etc/init.d/${MY_PN}d${MV} start"
	elog
	elog "Logs are written to \"/var/log/teamviewer${MV}\""
}

pkg_postrm() {
	gnome2_icon_cache_update
}
