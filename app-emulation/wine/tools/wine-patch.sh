# !/bin/bash

script_path=$(readlink -f $0)
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global variables
new_wine_versions="1.8_rc1-r1 1.8_rc2-r1 1.8_rc3-r1 1.8_rc4-r1 1.8.1-r1 1.8.2 1.9.0-r1 1.9.1-r1 1.9.2-r1 1.9.3-r1 1.9.4-r1 1.9.5-r1 1.9.6-r1 1.9.7-r1 1.9.8 9999"
wine_staging_unsupported_versions=""
legacy_gstreamer_patch_1_0_versions="1.8_rc* 1.8-r1 1.8.1-r1 1.8.2 1.9.0-r1 1.9.1-r1 9999"
updated_multilib_patch_wine_versions="1.8.2 1.9.5-r1 1.9.6-r1 1.9.7-r1 1.9.8 9999"
no_sysmacros_patch_wine_versions="9999"
wine_gecko_version2_44_wine_versions="1.9.3-r1 1.9.4-r1 1.9.5-r1 1.9.6-r1 1.9.7-r1 1.9.8 9999"
wine_mono_version4_6_0_wine_versions="1.9.5-r1 1.9.6-r1 1.9.7-r1"
wine_mono_version4_6_2_wine_versions="1.9.8 9999"

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

# Create latest unstable versions - if not in the main Gentoo tree already
for ebuild_file in *.ebuild; do
	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#wine-}"
	if [[ "${ebuild_version}" != "1.8-r1" ]]; then
		continue
	fi

	for new_version in ${new_wine_versions}; do
		new_ebuild_file="${ebuild_file/1.8-r1/${new_version}}"

		[ -f "${new_ebuild_file}" ] && continue

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
	ebuild_version="${ebuild_version#wine-}"
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${ebuild_file}\""
	awk -F '[[:blank:]]+' \
			-vwine_version="${ebuild_version}" \
			-vwine_staging_unsupported_versions="${wine_staging_unsupported_versions}" \
			-vlegacy_gstreamer_patch_1_0_versions="${legacy_gstreamer_patch_1_0_versions}" \
			-vupdated_multilib_patch_wine_versions="${updated_multilib_patch_wine_versions}" \
			-vno_sysmacros_patch_wine_versions="${no_sysmacros_patch_wine_versions}" \
			-vwine_gecko_version2_44_wine_versions="${wine_gecko_version2_44_wine_versions}" \
			-vwine_mono_version4_6_0_wine_versions="${wine_mono_version4_6_0_wine_versions}" \
			-vwine_mono_version4_6_2_wine_versions="${wine_mono_version4_6_2_wine_versions}" \
			--file "tools/common-functions.awk" \
			--file "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done


# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
