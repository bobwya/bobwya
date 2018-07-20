# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: gnome2-icon-utils.eclass
# @MAINTAINER:
# gnome@gentoo.org
# @BLURB: Auxiliary functions commonly used by Gnome packages.
# @DESCRIPTION:
# This eclass provides a set of auxiliary functions needed by most Gnome
# packages. It may be used by non-Gnome packages as needed for handling various
# Gnome stack related functions such as:
#  * Gtk+ icon cache management

[[ ${EAPI:-0} == [012345] ]] && inherit multilib
[[ ${EAPI:-0} == [012345] ]] && inherit eutils
inherit xdg-utils-r1

case "${EAPI:-0}" in
	0|1|2|3|4|5|6|7) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# @ECLASS-VARIABLE: GNOME2_ECLASS_ICONS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of icons provided by the package

DEPEND=">=sys-apps/sed-4"

# @FUNCTION: gnome2_icon_savelist
# @DESCRIPTION:
# Find the icons that are about to be installed and save their location
# in the GNOME2_ECLASS_ICONS environment variable. This is only
# necessary for eclass implementations that call
# gnome2_icon_cache_update conditionally.
# This function should be called from pkg_preinst.
gnome2_icon_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME2_ECLASS_ICONS=$(find 'usr/share/icons' -maxdepth 1 -mindepth 1 -type d 2> /dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome2_icon_cache_update
# @DESCRIPTION:
# Updates Gtk+ icon cache files under /usr/share/icons.
# This function should be called from pkg_postinst and pkg_postrm.
gnome2_icon_cache_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GTK_UPDATE_ICON_CACHE}"

	if [[ ! -x "${updater}" ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	ebegin "Updating icons cache"

	local retval=0
	local fails=( )

	for dir in "${EROOT%/}"/usr/share/icons/*
	do
		if [[ -f "${dir}/index.theme" ]]; then
			local rv=0

			"${updater}" -qf "${dir}"
			rv=$?

			if [[ ! $rv -eq 0 ]]; then
				debug-print "Updating cache failed on ${dir}"

				# Add to the list of failures
				fails+=( "${dir}" )

				retval=2
			fi
		elif [[ $(ls "${dir}") = "icon-theme.cache" ]]; then
			# Clear stale cache files after theme uninstallation
			rm "${dir}/icon-theme.cache"
		fi

		if [[ -z $(ls "${dir}") ]]; then
			# Clear empty theme directories after theme uninstallation
			rmdir "${dir}"
		fi
	done

	eend ${retval}

	for f in "${fails[@]}" ; do
		eerror "Failed to update cache with icon $f"
	done
}

