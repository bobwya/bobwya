# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )


# Rename all the local patch files
cd "${script_folder%/tools}/files"
for patch_file in *.patch; do
	if [[ "${patch_file##*/}" =~ firefox\-kde\-opensuse ]]; then
		continue
	fi

	new_patch_file="${patch_file/firefox/firefox-kde-opensuse}"
	if 	[[ "${patch_file}" != "${new_patch_file}" ]]; then
		echo "moving patch file: \"${patch_file}\" -> \"${new_patch_file}\""
		mv "${patch_file}" "${new_patch_file}"
	fi
done

# Rename and patch all the stock firefox ebuild files
cd "${script_folder%/tools}"

# Remove Changelogs - as this is an unofficial package
rm ChangeLog* 2>/dev/null

# Patch metadata.xml file
metadata_file="metadata.xml"
mv "${metadata_file}" "${metadata_file}.bak"
gawk 'BEGIN{
        flag_regexp="^[[:blank:]]+\<flag name\=\"([\-[:alnum:]]+)\"\>.+$"
        use_close_regexp="\<\/use\>"
        kde_use_flag="kde"
    }
    {
        flag_name=($0 ~ flag_regexp) ? gensub(flag_regexp, "\\1", "g") : ""
        kde_use=(flag_name == kde_use_flag) ? 1 : kde_use
        if (((flag_name > kde_use_flag) || ($0 ~ use_close_regexp)) && ! kde_use) {
            printf("\t<flag name=\"%s\">%s\n\t\t%s</flag>\n",
                    kde_use_flag,
                    "Use OpenSUSE patchset to build in support for native",
					"KDE4/Plasma 5 file dialog via <pkg>kde-misc/kmozillahelper</pkg>.")
            kde_use=1
        }
        printf("%s\n", $0)
    }' "${metadata_file}.bak" >"${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

# Rename and patch all ebuild files
for old_ebuild_file in *.ebuild; do
	# Don't process the ebuild files twice!
	if [[ "${old_ebuild_file##*/}" =~ firefox\-kde\-opensuse ]]; then
		ebuild_file="${old_ebuild_file}"
		continue
	fi

	ebuild_version="${old_ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#firefox-}"
	ebuild_file="${old_ebuild_file/firefox/firefox-kde-opensuse}"
	if [[ ${ebuild_version} == 43.0 ]]; then
		ebuild_file="${ebuild_file/43.0/43.0.4}"
	fi
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' -vebuild_file="${ebuild_file}" \
		--file "tools/${script_name%.*}.awk" \
		"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
	[ -f "${new_ebuild_file}" ] || exit 1
	mv "${new_ebuild_file}" "${ebuild_file}"
done

# Rebuild the master package Manifest file
[ -f "${ebuild_file}" ] && ebuild "${ebuild_file}" manifest
