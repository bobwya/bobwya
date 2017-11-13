bobwya
======


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

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine:0```; include:
* Customised **winecfg** utility - with clearer **Wine**/**Wine Staging** version information displayed in the **about** tab.
* Supports all **Wine** releases back to version 1.8.
  Uses custom Gentoo 11-part patchset: ```wine-1.8-gstreamer-1.0_{01,02,03,04,05,06,07,08,09,10,11}.patch``` to provide: GStreamer 1.0 support; for all these older versions of **Wine**.
  Includes various additional backported patches to allow building **Wine**/**Wine Staging** against newer system libraries.
* USE **+staging** supports live building against **Wine Staging** Git commits or branches.
* USE **+staging** supports live building against **Wine** Git commits or branches. In the event that **Wine Staging** is unsupported for the specified commit - a helper utility will walk the **Wine** and **Wine Staging** Git trees. This helper utility will determine (automatically) the closest (date/time based) **Wine** Git commit which supports the **Wine Staging** patchset and display this to the user.
* Supports **Wine** Release Candidate version mangling.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-desktop-common```:
* BASH script which generates a full selection of Wine desktop files, with broad locale support.
* BASH/awk script to extract scalable icons from the current Wine Git tree.
  The awk script (optionally) overlays Wine icon on Wine places icons
* BASH script to regenerate Makefile.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-gecko```:
* Supports **Wine Gecko** beta versions.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-staging:${PV}```; include:
* Customised **winecfg** utility - with clearer **Wine Staging** version information displayed in the **about** tab.
* Supports all **Wine Staging** releases back to version 1.8.
  Uses custom Gentoo 11-part patchset: ```wine-1.8-gstreamer-1.0_{01,02,03,04,05,06,07,08,09,10,11}.patch``` to provide: GStreamer 1.0 support; for all these older versions of **Wine Staging**.
  Includes various additional backported patches to allow building **Wine Staging** against newer system libraries.
* Supports live building against **Wine Staging** Git commits or branches.
* Supports live building against **Wine** Git commits or branches. In the event that **Wine Staging** is unsupported for the specified commit - a helper utility will walk the **Wine** and **Wine Staging** Git trees. This helper utility will determine (automatically) the closest (date/time based) **Wine** Git commit which supports the **Wine Staging** patchset.

Customisations, on top of the stock Gentoo ebuilds for: ```app-emulation/wine-vanilla:${PV}```; include:
* Customised **winecfg** utility - with clearer **Wine** version information displayed in the **about** tab.
* Supports all **Wine** releases back to version 1.8.
  Uses custom Gentoo 11-part patchset: ```wine-1.8-gstreamer-1.0_{01,02,03,04,05,06,07,08,09,10,11}.patch``` to provide: GStreamer 1.0 support; for all these older versions of **Wine**.
  Includes various additional backported patches to allow building **Wine** against newer system libraries.
* Supports **Wine** Release Candidate versions (which are typically not included in the main Gentoo Overlay).

Customisations, on top of the stock Gentoo package: ```app-eselect/eselect-wine```; include:
* Provides more detailed error messages.
* Supports more verbose output about operations.
* Handles specifying multiple Wine variants - for a larger set of **eselect wine** operations.
* Handles simultaneous installation of _multiple_ live versions, of ```app-emulation/wine-staging:9999_p*``` / ```app-emulation/wine-vanilla:9999_p*``` - on a single system.
* Live package versions of ```app-emulation/wine-staging:9999_p*``` / ```app-emulation/wine-vanilla:9999_p*``` stored **eselect** data includes Git metadata support (SHA-1 commit hash and Git commit date).
* Avoids using shell globbing for symbolic link validity tests.
* Features an unset option to allow detection and removal of hanging / orphaned symbolic links (associated with this module / not associated with any installed packages).
* Allows creation of ```/usr/lib{32,64}/wine``` symbolic links to allow building 3rd party applications (e.g. **wineasio**) against any installed version of Wine.
* Supplies a manual page entry.

**********************************************************************************************************************

Full listing of all **::bobwya Overlay** Wine package set:
```
app-eselect/eselect-wine : Manage active Wine version for multislot Wine variants.
app-emulation/wine:0 : Free implementation of Windows(tm) on Unix (single-slot version, supporting vanilla Wine & Wine Staging patchset).
app-emulation/wine-desktop-common : Core desktop menu entries and icons for Wine (shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-gecko : A Mozilla Gecko based version of Internet Explorer for Wine (multi-slot version - shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-mono : Wine Mono is a replacement for the .NET runtime and class libraries in Wine (multi-slot version - shared by all app-emulation/wine[-staging|-vanilla] packages).
app-emulation/wine-staging:${PV} : Free implementation of Windows(tm) on Unix (multi-slot version, only supports Wine with Wine Staging patchset automatically applied).
app-emulation/wine-vanilla:${PV} : Free implementation of Windows(tm) on Unix (multi-slot version, only supports vanilla Wine).
```

**********************************************************************************************************************

The Wine packages in the **::bobwya Overlay** are not compatible with the main **::gentoo** Wine packages.
It is highly recommended to mask the main **::gentoo** Wine packages, e.g.:

```
echo -e \
'app-emulation/wine::gentoo\n'\
'app-emulation/wine-any::gentoo\n'\
'app-emulation/wine-d3d9::gentoo\n'\
'app-emulation/wine-desktop-common::gentoo\n'\
'app-emulation/wine-gecko::gentoo\n'\
'app-emulation/wine-mono::gentoo\n'\
'app-emulation/wine-staging::gentoo\n'\
'app-emulation/wine-vanilla::gentoo\n'\
'virtual/wine::gentoo\n'\
  >> /etc/portage/package.mask/gentoo_wine
```

Using a mixture of Wine packages from **::bobwya** and **::gentoo** is not supported!

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
