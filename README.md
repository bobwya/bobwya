bobwya
======

[![pkgcheck action](https://github.com/bobwya/bobwya/actions/workflows/pkgcheck_scan.yml/badge.svg)](https://github.com/bobwya/bobwya/actions/workflows/pkgcheck_scan.yml) [![License](http://img.shields.io/:license-gpl-green.svg)](https://tldrlegal.com/license/gnu-general-public-license-v2)

Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!


### Main Overlay packages
-------------------------
	app-arch/cabextract : Tool to extract files from Microsoft cabinet archive files.
	app-arch/unshield : Tool and library to extract CAB files from InstallShield installers.
	app-benchmarks/phoronix-test-suite : Phoronix's comprehensive, cross-platform testing and benchmark suite.
	app-forensics/pev : PE file analysis toolkit - for examining Windows PE binary files.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
	kde-misc/kmozillahelper : helper application that allows Mozilla Firefox to use Plasma file dialogs, file associations, protocol handlers and other desktop integration features.
	mail-client/thunderbird : Thunderbird mail client, with optional OpenSUSE Patchset for better Plasma Desktop integration.
	media-sound/neroaac : Nero AAC reference quality MPEG-4 and 3GPP audio codec.
	media-video/ffx264 : Script to encode video files to H.264/AVC video using the FFmpeg encoder.
	media-video/h264enc : h264enc is an advanced and powerful interactive menu-driven shell script written for the GNU/Linux operating system to encode video files
	net-dialup/dterm : dterm is a simple terminal emulator for serial connections.
	net-dns/ndjbdns : Fork of djbdns, a collection of DNS client/server software.
	sys-apps/hw-probe : A tool to probe system hardware, check operability and upload results.
	sys-fs/exfat-nofuse : Non-fuse kernel driver for exFat and VFat file systems.
	sys-fs/exfat-utils-nofuse : exFAT filesystem utilities (without fuse).
	www-client/firefox : Firefox web browser, with optional OpenSUSE Patchset, for better Plasma Desktop integration.
	x11-apps/starfield : Reminiscence to the screensaver that shipped, with Windows, until Windows XP.


### Customised Wine package set
-------------------------------

These Wine packages are more than a cosmetic fork of the main Gentoo Portage and other Overlay Wine packages. So don't "mix and match" these!

See: [Wiki: Wine Packages](https://github.com/bobwya/bobwya/wiki/Wine-Packages) for more information.

Note: the **::bobwya Overlay** Wine packages _do_ _not_ support the **Gallium 9** / **D3D9** patchset. This is purely down to testing systems only using the Nvidia Proprietary graphics driver.


##
Credit to the Arch AUR **firefox-kde-opensuse** PKGBUILD script used as the main basis for the Gentoo **www-client/firefox** package (with optional OpenSUSE KDE patchset support).
