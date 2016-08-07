# !/bin/bash

script_path=$(readlink -f $0)
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global variables
wine_versions_new="1.8_rc1-r2 1.8_rc2-r2 1.8_rc3-r2 1.8_rc4-r2 1.8-r2 1.8.1-r2 1.8.2-r1 1.8.3-r1 1.9.0-r2 1.9.1-r2 1.9.2-r2 1.9.3-r2 1.9.4-r2 1.9.5-r2 1.9.6-r2 1.9.7-r2 1.9.8-r1 1.9.9-r1 1.9.10-r1 1.9.11-r1 1.9.12-r1 1.9.13-r1 1.9.14-r1 1.9.15-r1 1.9.16-r1 9999"
#wine_versions_staging_supported="${wine_versions_new}"

wine_versions_staging_supported="1.8_rc* 1.8.1 1.8.2 1.8.3 1.9.0 1.9.1 1.9.2 1.9.3 1.9.4 1.9.5 1.9.6 1.9.7 1.9.8 1.9.9 1.9.10 1.9.11 1.9.12 1.9.13 1.9.14 1.9.15 1.9.16 9999"
wine_versions_no_csmt_staging="1.9.6 1.9.7 1.9.8 1.9.9"
wine_versions_legacy_gstreamer_patch_1_0="1.8_rc* 1.8 1.8.1 1.8.2 1.8.3 1.9.0 1.9.1 9999"
wine_versions_no_sysmacros_patch="1.8.3 1.9.9 1.9.10 1.9.11 1.9.12 1.9.13 1.9.14 1.9.15 1.9.16 9999"
wine_versions_no_gnutls_patch="1.9.13 1.9.14 1.9.15 1.9.16 9999"

# Rename and patch all the stock mesa ebuild files
cd "${script_folder%/tools}"

# Remove unneeded patch files...
rm "files/wine-1.1.15-winegcc.patch" 2>/dev/null
rm "files/wine-1.5.17-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.0-freetype-header-location.patch" 2>/dev/null
rm "files/wine-1.7.19-makefile-race-cond.patch" 2>/dev/null
rm "files/wine-1.7.2-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.2-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.38-gstreamer-v5-staging-post.patch" 2>/dev/null
rm "files/wine-1.7.38-gstreamer-v5-staging-pre.patch" 2>/dev/null
rm "files/wine-1.7.39-gstreamer-v5-staging-post.patch" 2>/dev/null
rm "files/wine-1.7.39-gstreamer-v5-staging-pre.patch" 2>/dev/null
rm "files/wine-1.7.55-gstreamer-v5-staging-post.patch" 2>/dev/null
rm "files/wine-1.7.55-gstreamer-v5-staging-pre.patch" 2>/dev/null
rm "files/wine-1.7.45-libunwind-osx-only.patch" 2>/dev/null
rm "files/wine-1.7.47-critical-security-cookie-fix.patch" 2>/dev/null

# Remove obsolete ebuild files...
rm wine-1.{6,7}*.ebuild 2>/dev/null

# Remove ChangeLog files...
rm ChangeLog* 2>/dev/null


# Create all new wine versions from base version 1.8
for ebuild_file in *.ebuild; do
	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#wine-}"
	[[ "${ebuild_version}" != "1.8-r"* ]] &&  continue
	for new_version in ${wine_versions_new}; do
		[[ "${new_version}" == "1.8-r"* ]] &&  continue
		new_ebuild_file="wine-${new_version}.ebuild"
		[ -f "${new_ebuild_file}" ] &&  continue
		cp "${ebuild_file}" "${new_ebuild_file}"
	done
done

# Patch all ebuild files
for ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q 'STABLE_RELEASE' "${ebuild_file}" ; then
		continue
	fi

	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version%-r[0-9]*}"
	ebuild_version="${ebuild_version#wine-}"

	# Wine-Gecko
	case "${ebuild_version}" in
		1.8_rc* | 1.8 | 1.8.[1-3] | 1.9.[0-2] )
			wine_gecko_version="2.40";;
		1.9.[3-9] | 1.9.1[0-2] )
			wine_gecko_version="2.44";;
		*)
			wine_gecko_version="2.47";;
	esac
	case "${ebuild_version}" in
		1.9.1[0-2] )
			wine_staging_gecko_version="2.47-beta1";;
		*)
			wine_staging_gecko_version="${wine_gecko_version}";;
	esac

	# Wine-Mono
	case "${ebuild_version}" in
		1.8_rc* | 1.8 | 1.8.[1-3] | 1.9.[0-4] )
			wine_mono_version="4.5.6";;
		1.9.[5-7] )
			wine_mono_version="4.6.0";;
		1.9.[8-9] | 1.9.1[0-1] )
			wine_mono_version="4.6.2";;
		*)
			wine_mono_version="4.6.3";;
	esac
	wine_staging_mono_version="${wine_mono_version}"

	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${ebuild_file}\""
	awk -F '[[:blank:]]+' \
			-vwine_version="${ebuild_version}" \
			-vwine_versions_staging_supported="${wine_versions_staging_supported}" \
			-vwine_versions_no_csmt_staging="${wine_versions_no_csmt_staging}" \
			-vwine_versions_legacy_gstreamer_patch_1_0="${wine_versions_legacy_gstreamer_patch_1_0}" \
			-vwine_versions_no_sysmacros_patch="${wine_versions_no_sysmacros_patch}" \
			-vwine_versions_no_gnutls_patch="${wine_versions_no_gnutls_patch}" \
			-vwine_gecko_version="${wine_gecko_version}" -vwine_staging_gecko_version="${wine_staging_gecko_version}" \
			-vwine_mono_version="${wine_mono_version}"   -vwine_staging_mono_version="${wine_staging_mono_version}" \
			--file "tools/common-functions.awk" \
			--file "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done


# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
