bobwya
======

![example workflow](https://github.com/bobwya/bobwya/actions/workflows/repoman.yml/badge.svg) [![License](http://img.shields.io/:license-gpl-green.svg)](https://tldrlegal.com/license/gnu-general-public-license-v2)

Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!


### Main Overlay packages
-------------------------
	app-arch/cabextract : Tool to extract files from Microsoft cabinet archive files.
	app-arch/unshield : Tool and library to extract CAB files from InstallShield installers.
	app-benchmarks/glxosd : GLXOSD is an extensible on-screen display (OSD)/overlay for OpenGL applications running on Linux with X11 which aims to provide similar functionality to MSI Afterburner/RivaTuner OSD.
	app-benchmarks/i7z : A better Intel i7 (and now i3, i5) CPU reporting tool for Linux.
	app-benchmarks/phoronix-test-suite : Phoronix's comprehensive, cross-platform testing and benchmark suite.
	app-forensics/pev : PE file analysis toolkit - for examining Windows PE binary files.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
	games-util/lutris : Lutris is an open gaming platform for Linux. It helps you install and manage your games in a unified interface.
	kde-misc/kmozillahelper : helper application that allows Mozilla Firefox to use Plasma file dialogs, file associations, protocol handlers and other desktop integration features.
	mail-client/thunderbird : Thunderbird mail client, with optional OpenSUSE Patchset for better Plasma Desktop integration.
	media-sound/neroaac : Nero AAC reference quality MPEG-4 and 3GPP audio codec.
	media-video/ffx264 : Script to encode video files to H.264/AVC video using the FFmpeg encoder.
	media-video/filebot : Java-based tools to rename TV shows, download subtitles, and validate checksums.
	media-video/h264enc : h264enc is an advanced and powerful interactive menu-driven shell script written for the GNU/Linux operating system to encode video files
	net-dialup/dterm : dterm is a simple terminal emulator for serial connections.
	net-dns/ndjbdns : Fork of djbdns, a collection of DNS client/server software.
	sys-apps/cpuid : Utility to get detailed information about CPU(s) using the CPUID instruction.
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

### Custom GL lib switcher implementation package set
-----------------------------------------------------

These packages are masked and are NOT extensively tested (but I use them personally!) Loosely based off the Arch-Linux GL lib switcher. Has some rudimentary support for **PRIMUS** setups. The **x11-drivers/nvidia-drivers** package is customised to support the **GLXOSD** fork in the **::bobwya** Overlay. 

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

See [Arch AUR freetype2-infinality-ultimate package](https://aur.archlinux.org/packages/freetype2-infinality-ultimate/).

##
Credit to the Arch AUR **firefox-kde-opensuse** PKGBUILD script used as the main basis for the Gentoo **www-client/firefox** package (with optional OpenSUSE KDE patchset support).
