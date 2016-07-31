bobwya
======


Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!

	app-arch/unshield : Tool and library to extract CAB files from InstallShield installers.
	app-backup/fsarchiver : Flexible filesystem archiver for backup and deployment tool.
	app-benchmarks/i7z : A better Intel i7 (and now i3, i5) CPU reporting tool for Linux.
	app-crypt/chntpw : Offline NT Password & Registry Editor.
	app-text/hunspell : Hunspell is the spell checker of LibreOffice, OpenOffice.org, Mozilla Firefox 3 & Thunderbird, Google Chrome, etc.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
	games-util/lutris : Lutris is an open gaming platform for Linux. It helps you install and manage your games in a unified interface.
	kde-misc/kmozillahelper : helper application that allows Mozilla Firefox to use KDE/Plasma 5 file dialogs, file associations, protocol handlers and other KDE/Plasma 5 integration features.
	mail-client/thunderbird-kde-opensuse : Thunderbird mail client, with OpenSUSE Patchset for better KDE Desktop integration. 
	media-tv/freetuxtv : freetuxtv GTK+ WebTV and Web Radio player for Linux.
	media-video/filebot-bin : FileBot tool for organizing and renaming your movies, tv shows or anime, and music. (java jar)
	media-video/handbrake : Handbrake A/V Conversion Tool
	media-video/h264enc : h264enc is an advanced and powerful interactive menu-driven shell script written for the GNU/Linux operating system to encode video files
	net-misc/fatrat : Open source download manager for Linux written in C++ and built on top of the Qt 4 library.
	net-misc/teamviewer : TeamViewer is a proprietary computer software package for remote control, desktop sharing, online meetings, web conferencing and file transfer between computers. (binary proprietary / Wine wrapper) 
	net-dialup/dterm : dterm is a simple terminal emulator for serial connections.
	net-p2p/btsync : BitTorrent Sync uses advanced peer-to-peer technology to share files between devices. (binary proprietary)
	net-p2p/eiskaltdcpp  :  EiskaltDC++ is a cross-platform program that uses the Direct Connect and ADC protocols.
	sys-apps/uksmstat : Simple tool to monitor and control UKSM.
	sys-auth/pam_kwallet : PAM integration to automatically unlock kwallet when logging into a KDE4 Desktop Session.
	sys-auth/polkit-explorer : Polkit Explorer reads in a Polkit .policy file, parses its XML contents, and presents the information it contains, on a more human-readable GUI window.
	x11-apps/starfield : Reminiscence to the screensaver that shipped, with Windows, until WinXP...
	www-client/firefox-kde-opensuse : Firefox web browser, with OpenSUSE Patchset, for better KDE Desktop integration.

***

Custom GL lib switcher implementation (these packages are masked and are NOT extensively tested) - loosely based off the Arch-Linux GL lib switcher.

	app-eselect/eselect-opengl : Gentoo OpenGL implementation switcher (heavily customised)
	media-libs/mesa : OpenGL-like graphic library for Linux (patched version - to work with custom eselect-opengl switcher)
	x11-base/xorg-server : X.Org X servers (patched version - to work with custom eselect-opengl switcher)
	x11-drivers/nvidia-drivers : NVIDIA Accelerated Graphics Driver (patched version - to work with custom eselect-opengl switcher)

***

Package Set to provide updated Infinality Fonts (subpixel font rendering enhancements patchset for freetype2 and associated packages). These three packages are designed to be used in conjunction with each other. The __media-libs/fontconfig-infinality__ package is in the main __Gentoo__ Portage tree.

	media-libs/fontconfig-infinality : Provides configuration to be used in conjunction with the freetype-infinality subpixel hinting.
	media-libs/fontconfig : A library for configuring and customizing font access - with updated infinality support.
	media-libs/fontconfig-ultimate : A set of font rendering and replacement rules for fontconfig-infinality.
	media-libs/freetype : A high-quality font engine - with updated infinality support.

See [Gentoo Wiki: Fontconfig (Infinality)](https://wiki.gentoo.org/wiki/Fontconfig#Infinality "Gentoo Wiki: Fontconfig (Infinality)").

See [Arch Wiki: Infinality](https://wiki.archlinux.org/index.php/Infinality "Arch Wiki: Infinality").

***

Credit to the Arch AUR firefox-kde-opensuse PKGBUILD script used as the main basis for the  www-client/firefox-kde-opensuse (OpenSUSE KDE patchset) ebuild.
