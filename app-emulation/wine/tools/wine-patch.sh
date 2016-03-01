# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global variables
new_wine_versions="1.8_rc1 1.8_rc2 1.8_rc3 1.8_rc4 1.8.1 1.9.0 1.9.1 1.9.2 1.9.3 1.9.4"
wine_staging_unsupported_versions="1.8.1"
legacy_gstreamer_wine_versions="1.6.* 1.7.* 1.8* 1.9.1"

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
rm "files/wine-1.7.45-libunwind-osx-only.patch" 2>/dev/null
rm "files/wine-1.7.47-critical-security-cookie-fix.patch" 2>/dev/null

# Remove obsolete ebuild files...
rm wine-1.{6,7}*.ebuild 2>/dev/null

# Remove ChangeLog files...
rm ChangeLog* 2>/dev/null


# Patch metadata.xml file
metadata_file="metadata.xml"
if ! grep -q 'gstreamer010' "${metadata_file}" ; then
	echo "processing metadata file: \"${metadata_file}\""
	mv "${metadata_file}" "${metadata_file}.bak"
	gawk 'BEGIN{
			flag_regexp="^[[:blank:]]+\<flag name\=\"([\-[:alnum:]]+)\"\>.+$"
			use_close_regexp="\<\/use\>"
			gstreamer_use_flag="gstreamer"
			gstreamer_legacy_use_flag="gstreamer010"
			gstreamer_pkg_regexp="media-libs\/gstreamer"
		}
		{
			flag_name=($0 ~ flag_regexp) ? gensub(flag_regexp, "\\1", "g") : ""
			if ((flag_name == "gstreamer") && (gstreamer_match == 0)) {
				sub(gstreamer_use_flag, gstreamer_legacy_use_flag)
				gsub(gstreamer_pkg_regexp, gstreamer_pkg_regexp ":0.1")
				flag_name=gstreamer_legacy_use_flag
				gstreamer_match=1
			}
			gstreamer_use=(flag_name == gstreamer_use_flag) ? 1 : gstreamer_use
			if (((flag_name > gstreamer_use_flag) || ($0 ~ use_close_regexp)) && ! gstreamer_use) {
				printf("\t\t<flag name=\"%s\">%s</flag>\n",
						gstreamer_use_flag,
						"Use <pkg>media-libs/gstreamer:1.0</pkg> to provide DirectShow functionality")
				gstreamer_use=1
			}
			printf("%s\n", $0)
		}' "${metadata_file}.bak" 1>"${metadata_file}" 2>/dev/null
	rm "${metadata_file}.bak"
fi

# Create latest unstable versions - if not in the main Gentoo tree already
for ebuild_file in *.ebuild; do
	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#wine-}"
	if [[ "${ebuild_version}" != "1.8" ]]; then
		continue
	fi

	for new_version in ${new_wine_versions}; do
		new_ebuild_file="${ebuild_file/1.8/${new_version}}"

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
			-vlegacy_gstreamer_wine_versions="${legacy_gstreamer_wine_versions}" \
			--file "tools/common-functions.awk" \
			--file "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done


# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
