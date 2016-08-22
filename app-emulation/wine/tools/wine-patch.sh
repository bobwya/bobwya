# !/bin/bash

script_path=$(readlink -f $0)
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global variables
wine_versions_new="1.8-r3 1.8.1-r3 1.8.2-r2 1.8.3-r2 1.8.4 1.9.0-r3 1.9.1-r3 1.9.2-r3 1.9.3-r3 1.9.4-r3 1.9.5-r3 1.9.6-r3 1.9.7-r3 1.9.8-r2 1.9.9-r2 1.9.10-r2 1.9.11-r2 1.9.12-r2 1.9.13-r2 1.9.14-r2 1.9.15-r2 1.9.16-r2 1.9.17-r1 9999"
#wine_versions_staging_supported="${wine_versions_new}"

wine_versions_staging_supported="1.8 1.8.1 1.8.2 1.8.3 1.9.0 1.9.1 1.9.2 1.9.3 1.9.4 1.9.5 1.9.6 1.9.7 1.9.8 1.9.9 1.9.10 1.9.11 1.9.12 1.9.13 1.9.14 1.9.15 1.9.16 1.9.17 9999"
wine_versions_no_csmt_staging="1.9.6 1.9.7 1.9.8 1.9.9"
wine_versions_legacy_gstreamer_patch_1_0="1.8 1.8.1 1.8.2 1.8.3 1.8.4 1.9.0 1.9.1 9999"
wine_versions_no_sysmacros_patch="1.8.3 1.8.4 1.9.9 1.9.10 1.9.11 1.9.12 1.9.13 1.9.14 1.9.15 1.9.16 1.9.17 9999"
wine_versions_no_gnutls_patch="1.8.4 1.9.13 1.9.14 1.9.15 1.9.16 1.9.17 9999"
wine_versions_staging_eapply_supported="1.9.17 9999"


# Move to main package directory
cd "${script_folder%/tools}"

# Clean existing ebuilds and rebase off the main (base) Gentoo stable release version (1.8)
rm *.ebuild
rsync -achv --progress "/usr/portage/app-emulation/wine"/wine-1.8-r*.ebuild .
rsync -achv --progress "/usr/portage/app-emulation/wine"/metadata.xml .

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
rm "files/wine-1.4_rc2-multilib-portage.patch" 2>/dev/null
rm "files/wine-1.9.5-multilib-portage.patch" 2>/dev/null

# Remove obsolete ebuild files...
rm wine-1.{6,7}*.ebuild 2>/dev/null

# Remove ChangeLog files...
rm ChangeLog* 2>/dev/null

# Patch metadata.xml file
metadata_file="metadata.xml"
mv "${metadata_file}" "${metadata_file}.bak"
awk 'BEGIN{
        flag_open_regexp="^[[:blank:]]+<flag name\=\"([\-[:alnum:]]+)\">.+$"
        flag_close_regexp="<\/flag>"
        use_close_regexp="<\/use>"
        maintainer_open_regexp="^[[:blank:]]*<maintainer.*>"
		maintainer_close_regexp="^[[:blank:]]*<\/maintainer>"
        upstream_open_regexp="^[[:blank:]]*<upstream.*>"
		upstream_close_regexp="^[[:blank:]]*<\/upstream>"
		gstreamer_block_open=0
		prelink_block_open=0
		upstream_open=0
    }
    {
		maintainer_open=maintainer_open || ($0 ~ maintainer_open_regexp)
		if (maintainer_open) {
			maintainer_open=($0 !~ maintainer_close_regexp)
			next
		}
		flag_name=""
		if ($0 ~ flag_open_regexp) {
			flag_name=$0
			sub("^[[:blank:]]+<flag name\=\"", "", flag_name)
			sub("\">.+$", "", flag_name)
		}
		d3d9_block_open=(flag_name == "d3d9") ? 1 : d3d9_block_open
		if (d3d9_block_open) {
			d3d9_block_open=($0 ~ flag_close_regexp) ? 0 : 1
			next
		}
		gstreamer_block_open=(flag_name == "gstreamer") ? 1 : gstreamer_block_open
		if (gstreamer_block_open)
			sub(flag_close_regexp, "")
		upstream_open=upstream_open || ($0 ~ upstream_open_regexp)
		if (upstream_open) {
			sub("sourceforge", "github") && sub("wine","wine-mirror/wine")
			if ($0 ~ upstream_close_regexp) {
				printf("\t\t%s\n", "<remote-id type=\"github\">mstefani/wine-stable</remote-id>")
				upstream_open=0
			}
		}
		prelink_block_open=(flag_name == "prelink") ? 1 : prelink_block_open
		if (prelink_block_open) {
			sub("versions before wine\-1\.7\.55 or", "Gentoo")
			prelink_block_open=($0 ~ flag_close_regexp) ? 0 : 1
		}
        printf("%s\n", $0)
        if (gstreamer_block_open) {
			printf("\t\t\t%s\n", "for versions: wine-1.9.0, wine-1.9.1 ; a stable branch patch is applied in an unofficial capacity</flag>")
			gstreamer_block_open=0
        }

    }' "${metadata_file}.bak" >"${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

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
		1.8_rc* | 1.8 | 1.8.[1-4] | 1.9.[0-2] )
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
		1.8_rc* | 1.8 | 1.8.[1-4] | 1.9.[0-4] )
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
			-vwine_versions_staging_eapply_supported="${wine_versions_staging_eapply_supported}" \
			-vwine_gecko_version="${wine_gecko_version}" -vwine_staging_gecko_version="${wine_staging_gecko_version}" \
			-vwine_mono_version="${wine_mono_version}"   -vwine_staging_mono_version="${wine_staging_mono_version}" \
			-f "tools/common-functions.awk" \
			-f "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done


# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
