bobwya
======


Gentoo Overlay containing various packages I have been unable to find @ Gentoo Portage Overlays website or elsewhere.
Testing and updating of these ebuild package build scripts is irregular. So YMMV - you have been warned!

### Main Overlay packages

	app-arch/unshield : Tool and library to extract CAB files from InstallShield installers.
	app-backup/fsarchiver : Flexible filesystem archiver for backup and deployment tool.
	app-benchmarks/i7z : A better Intel i7 (and now i3, i5) CPU reporting tool for Linux.
	app-crypt/chntpw : Offline NT Password & Registry Editor.
	app-forensics/pev : PE file analysis toolkit - for examining Windows PE binary files.
	app-text/hunspell : Hunspell is the spell checker of LibreOffice, OpenOffice.org, Mozilla Firefox 3 & Thunderbird, Google Chrome, etc.
	dev-cpp/pion : C++ framework for building lightweight HTTP interfaces.
	games-fps/dhewm3 : Doom 3 GPL source modification (with updates including SDL2 support).
	games-util/lutris : Lutris is an open gaming platform for Linux. It helps you install and manage your games in a unified interface.
	kde-misc/kmozillahelper : helper application that allows Mozilla Firefox to use KDE/Plasma 5 file dialogs, file associations, protocol handlers and other KDE/Plasma 5 integration features.
	mail-client/thunderbird-kde-opensuse : Thunderbird mail client, with OpenSUSE Patchset for better KDE Desktop integration. 
	media-libs/avidemux-core : Avidemux is a free open-source program designed for multi-purpose video editing and processing (core libraries).
	media-libs/avidemux-plugins : Avidemux is a free open-source program designed for multi-purpose video editing and processing (plugins).
	media-tv/freetuxtv : freetuxtv GTK+ WebTV and Web Radio player for Linux.
	media-video/avidemux : Avidemux is a free open-source program designed for multi-purpose video editing and processing (main frontends).
	media-video/filebot-bin : FileBot tool for organizing and renaming your movies, tv shows or anime, and music. (java jar)
	media-video/handbrake : Handbrake A/V Conversion Tool
	media-video/h264enc : h264enc is an advanced and powerful interactive menu-driven shell script written for the GNU/Linux operating system to encode video files
	net-dialup/dterm : dterm is a simple terminal emulator for serial connections.
	net-p2p/eiskaltdcpp  :  EiskaltDC++ is a cross-platform program that uses the Direct Connect and ADC protocols.
	sys-apps/uksmstat : Simple tool to monitor and control UKSM.
	sys-auth/pam_kwallet : PAM integration to automatically unlock kwallet when logging into a KDE4 Desktop Session.
	sys-auth/polkit-explorer : Polkit Explorer reads in a Polkit .policy file, parses its XML contents, and presents the information it contains, on a more human-readable GUI window.
	x11-apps/starfield : Reminiscence to the screensaver that shipped, with Windows, until WinXP...
	www-client/firefox-kde-opensuse : Firefox web browser, with OpenSUSE Patchset, for better KDE Desktop integration.

***
### Customised Wine package set
These packages are based heavily on NP's hard work - packaging Wine in the main Gentoo Portage tree. Thanks for his hardwork on this!
Now Gentoo has the most awesome Wine support of any GNU/Linux distribution!

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine:0```; include:
* Customised **winecfg** utility - with clearer Wine/Wine Staging version information displayed.
* Supports all **Wine** releases back to version 1.8. Includes custom Gentoo ```wine-1.8-gstreamer-1.0.patch``` to provide: GStreamer 1.0 support; for these older versions of **Wine**.
* Supports all **Wine** releases back to version 1.8. Additional patches to provide this support: ```wine-1.8-gnutls-3.5-compat.patch``` , ```wine-cups-2.2-cupsgetppd-build-fix.patch```.
* USE **+staging** supports live building against **Wine Staging** Git commits or branches.
* USE **+staging** supports live building against **Wine** Git commits or branches. In the event that **Wine Staging** is unsupported for the specified commit - a helper utility will walk the **Wine** and **Wine Staging** Git trees. This helper utility will determine (automatically) the closest (date/time based) **Wine** Git commit which supports the **Wine Staging** patchset.
* Supports **Wine** Release Candidate versions.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-desktop-common```:
* installs oic_winlogo.ico globally - so ```app-emulation/wine[-staging|-vanilla]``` packages do not need to reference the ```wine-desktop-common.tar.gz``` tarball directly.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-gecko```:
* Supports **Wine Gecko** beta versions.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-staging:${PV}```; include:
* Customised **winecfg** utility - with clearer Wine Staging version information displayed.
* Supports all **Wine Staging** releases back to version 1.8. Includes custom Gentoo ```wine-1.8-gstreamer-1.0.patch``` to provide: GStreamer 1.0 support; for these older versions of **Wine**.
* Supports all **Wine Staging** releases back to version 1.8. Additional patches to provide this support: ```wine-1.8-gnutls-3.5-compat.patch``` , ```wine-cups-2.2-cupsgetppd-build-fix.patch```.
* Supports live building against **Wine Staging** Git commits or branches.
* Supports live building against **Wine** Git commits or branches. In the event that **Wine Staging** is unsupported for the specified commit - a helper utility will walk the **Wine** and **Wine Staging** Git trees. This helper utility will determine (automatically) the closest (date/time based) **Wine** Git commit which supports the **Wine Staging** patchset.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-vanilla:${PV}```; include:
* Customised **winecfg** utility - with clearer Wine version information displayed.
* Supports all **Wine** releases back to version 1.8. Includes custom Gentoo ```wine-1.8-gstreamer-1.0.patch``` to provide: GStreamer 1.0 support; for these older versions of Wine.
* Supports all **Wine** releases back to version 1.8. Additional patches to provide this support: ```wine-1.8-gnutls-3.5-compat.patch``` , ```wine-cups-2.2-cupsgetppd-build-fix.patch```.
* Supports **Wine** Release Candidate versions (which are typically not included in the main Gentoo Overlay).

Customisations, on top of the stock Gentoo package: ```app-eselect/eselect-wine```; include:
* Provides more detailed error messages.
* Supports more verbose output about operations.
* Handles multiple variants - for more eselect wine operations.
* Handles multiple live versions, of ```app-emulation/wine-staging:9999_p*``` / ```app-emulation/wine-vanilla:9999_p*``` - which all can all be installed simulatenously on a single system.
* Live package versions of ```app-emulation/wine-staging:9999_p*``` / ```app-emulation/wine-vanilla:9999_p*``` are stored with Git metadata support (SHA-1 commit hash and Git commit date).
* Avoids using shell globbing for symbolic link validity tests.
* Features an unset option to allow detection and removal of hanging / orphaned symbolic links (associated with this module / not associated with any installed packages).
* Has a bundled manual page entry.

```
app-eselect/eselect-wine : Manage active Wine version for multislot Wine variants.
app-emulation/wine:0 : Free implementation of Windows(tm) on Unix (single-slot version, supporting vanilla Wine & Wine Staging patchset).
app-emulation/wine-desktop-common : Core desktop menu entries and icons for Wine (shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-gecko : A Mozilla Gecko based version of Internet Explorer for Wine (multi-slot version - shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-mono : Wine Mono is a replacement for the .NET runtime and class libraries in Wine (multi-slot version - shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-staging:${PV} : Free implementation of Windows(tm) on Unix (multi-slot version, only supports Wine with Wine Staging patchset automatically applied).
app-emulation/wine-vanilla:${PV} : Free implementation of Windows(tm) on Unix (multi-slot version, only supports vanilla Wine).
```

***

### Custom GL lib switcher implementation package set
These packages are masked and are NOT extensively tested (but I use them personally!) Loosely based off the Arch-Linux GL lib switcher. Has some rudimentary support for **PRIMUS** setups.

	app-eselect/eselect-opengl : Gentoo OpenGL implementation switcher (heavily customised)
	media-libs/mesa : OpenGL-like graphic library for Linux (patched version - to work with custom eselect-opengl switcher)
	x11-base/xorg-server : X.Org X servers (patched version - to work with custom eselect-opengl switcher)
	x11-drivers/nvidia-drivers : NVIDIA Accelerated Graphics Driver (patched version - to work with custom eselect-opengl switcher)

***

### Infinality Fonts package set

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
