bobwya
======


Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!

	app-backup/fsarchiver : Flexible filesystem archiver for backup and deployment tool.
	app-benchmarks/i7z : A better Intel i7 (and now i3, i5) CPU reporting tool for Linux.
	app-crypt/chntpw : Offline NT Password & Registry Editor.
	app-office/libreoffice : LibreOffice, a full office productivity suite.
	app-office/libreoffice-l10 : Translations for the Libreoffice suite.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
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
	www-client/firefox-kde-opensuse : Firefox web browser, with OpenSUSE Patchset, for better KDE Desktop integration.

Custom GL lib switcher implementation (these packages are masked and are NOT extensively tested) - loosely based off the Arch-Linux GL lib switcher.

	app-eselect/eselect-opengl : Gentoo OpenGL implementation switcher (heavily customised)
	media-libs/mesa : OpenGL-like graphic library for Linux (patched version - to work with custom eselect-opengl switcher)
	x11-base/xorg-server : X.Org X servers (patched version - to work with custom eselect-opengl switcher)
	x11-drivers/nvidia-drivers : NVIDIA Accelerated Graphics Driver (patched version - to work with custom eselect-opengl switcher)


Credit to the Arch AUR firefox-kde-opensuse PKGBUILD script used as the main basis for the  www-client/firefox-kde-opensuse (OpenSUSE KDE patchset) ebuild.
