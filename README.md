bobwya
======

![https://travis-ci.org/bobwya/bobwya](https://travis-ci.org/bobwya/bobwya.svg?branch=master) ![https://tldrlegal.com/license/gnu-general-public-license-v2](http://img.shields.io/:license-gpl-red.svg)

Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!

### Main Overlay packages
-------------------------

	app-arch/unshield : Tool and library to extract CAB files from InstallShield installers.
	app-benchmarks/i7z : A better Intel i7 (and now i3, i5) CPU reporting tool for Linux.
	app-forensics/pev : PE file analysis toolkit - for examining Windows PE binary files.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
	games-util/lutris : Lutris is an open gaming platform for Linux. It helps you install and manage your games in a unified interface.
	kde-misc/kmozillahelper : helper application that allows Mozilla Firefox to use KDE/Plasma 5 file dialogs, file associations, protocol handlers and other KDE/Plasma 5 integration features.
	mail-client/thunderbird-kde-opensuse : Thunderbird mail client, with OpenSUSE Patchset for better KDE Desktop integration. 
	media-libs/avidemux-core : Avidemux is a free open-source program designed for multi-purpose video editing and processing (core libraries).
	media-libs/avidemux-plugins : Avidemux is a free open-source program designed for multi-purpose video editing and processing (plugins).
	media-video/avidemux : Avidemux is a free open-source program designed for multi-purpose video editing and processing (main frontends).
	media-video/filebot : Java-based tools to rename TV shows, download subtitles, and validate checksums.
	media-video/h264enc : h264enc is an advanced and powerful interactive menu-driven shell script written for the GNU/Linux operating system to encode video files
	net-dialup/dterm : dterm is a simple terminal emulator for serial connections.
	net-dns/ndjbdns : Fork of djbdns, a collection of DNS client/server software.
	net-p2p/eiskaltdcpp  :  EiskaltDC++ is a cross-platform program that uses the Direct Connect and ADC protocols.
	sys-apps/cpuid : Utility to get detailed information about CPU(s) using the CPUID instruction.
	sys-apps/hw-probe : A tool to probe system hardware, check operability and upload results.
	sys-fs/exfat-nofuse : Non-fuse kernel driver for exFat and VFat file systems.
	sys-fs/exfat-utils-nofuse : exFAT filesystem utilities (without fuse).
	www-client/firefox-kde-opensuse : Firefox web browser, with OpenSUSE Patchset, for better KDE Desktop integration.
	x11-apps/starfield : Reminiscence to the screensaver that shipped, with Windows, until Windows XP.


### Customised Wine package set
-------------------------------

These packages are based heavily on NP's hard work - packaging Wine in the main Gentoo Portage tree. Thanks for his hardwork on this!
Now Gentoo has the most awesome Wine support of any GNU/Linux distribution!

Note: the **::bobwya Overlay** Wine packages _do_ _not_ support the **Gallium 9** / **D3D9** patchset. This is purely down to lack of a testing system, which doesn't use the Nvidia Proprietary graphics driver.

See: [Wiki: Wine Packages](https://github.com/bobwya/bobwya/wiki/Wine-Packages) for more information.

### Custom GL lib switcher implementation package set
-----------------------------------------------------

These packages are masked and are NOT extensively tested (but I use them personally!) Loosely based off the Arch-Linux GL lib switcher. Has some rudimentary support for **PRIMUS** setups.

	app-eselect/eselect-opengl : Gentoo OpenGL implementation switcher (heavily customised)
	media-libs/mesa : OpenGL-like graphic library for Linux (patched version - to work with custom eselect-opengl switcher)
	x11-base/xorg-server : X.Org X servers (patched version - to work with custom eselect-opengl switcher)
	x11-drivers/nvidia-drivers : NVIDIA Accelerated Graphics Driver (patched version - to work with custom eselect-opengl switcher)

***

### Infinality Fonts package set
--------------------------------

Package Set to provide updated Infinality Fonts (subpixel font rendering enhancements for freetype2 and associated packages). These four packages are designed to be used __in__ __conjunction__ with each other. The __media-libs/fontconfig-infinality__ package is in the main __Gentoo__ Portage tree.

	media-libs/fontconfig-infinality : Provides configuration to be used in conjunction with the freetype-infinality subpixel hinting.
	media-libs/fontconfig : A library for configuring and customizing font access - with updated infinality support.
	media-libs/fontconfig-ultimate : A set of font rendering and replacement rules for fontconfig-infinality.
	media-libs/freetype : A high-quality font engine - with updated infinality support.

See [Gentoo Wiki: Fontconfig (Infinality)](https://wiki.gentoo.org/wiki/Fontconfig#Infinality "Gentoo Wiki: Fontconfig (Infinality)").

See [Arch Wiki: Infinality](https://wiki.archlinux.org/index.php/Infinality "Arch Wiki: Infinality").

_todo_: update to support latest build. See [Arch AUR freetype2-infinality-ultimate package](https://aur.archlinux.org/packages/freetype2-infinality-ultimate/).
***

Credit to the Arch AUR firefox-kde-opensuse PKGBUILD script used as the main basis for the  www-client/firefox-kde-opensuse (OpenSUSE KDE patchset) ebuild.
