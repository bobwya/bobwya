# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
package_unsupported_versions="24"
ebuild_revisions="24.8.0(1) 31.8.0(1) 38.7.0(1) 38.8.0(1) 45.2.0(1)"


# Global section
cd "${script_folder%/tools}"

# Import function declarations
. "tools/common-functions.sh"

# Rename all the local patch files
cd "${script_folder%/tools}/files"
# Fix pathes in supplied patches - to be EAPI 6 patch -p1 compliant
sed -i  -e 's:comm\-esr31.orig:a:g' \
		-e 's:comm\-esr31:b:g' \
		-e 's:porg\-build\-2015\.05\.17\-10h30m39s\/::g' \
		"thunderbird-31.7.0-gcc5-1.patch"
sed -i  -e '/^\(diff\|\-\-\-\) /s: a/: a/mailnews/extensions/enigmail/:g' \
		-e '/^\(diff\|+++\) /s: b/: b/mailnews/extensions/enigmail/:g' \
		"enigmail-1.6.0-parallel-fix.patch"
for patch_file in *.patch; do
	if [[ "${patch_file##*/}" =~ thunderbird\-kde\-opensuse ]]; then
		continue
	fi

	new_patch_file="${patch_file/thunderbird/thunderbird-kde-opensuse}"
	if 	[[ "${patch_file}" != "${new_patch_file}" ]]; then
		new_patch_file="${new_patch_file/5-1/5.1}"
		echo "moving patch file: \"${patch_file}\" -> \"${new_patch_file}\""
		mv "${patch_file}" "${new_patch_file}"
	elif [[ "${patch_file}" == "enigmail-1.6.0-parallel-fix.patch" ]]; then
		new_patch_file="thunderbird-kde-opensuse-${patch_file}"
		echo "moving patch file: \"${patch_file}\" -> \"${new_patch_file}\""
		mv "${patch_file}" "${new_patch_file}"
	fi
done

# Rename and patch all the stock thunderbird ebuild files
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
        maintainer_open_regexp="^[[:blank:]]*\<maintainer.+>"
		maintainer_close_regexp="^[[:blank:]]*\<\/maintainer>"
    }
    {
		maintainer_open=maintainer_open || ($0 ~ maintainer_open_regexp)
		if (maintainer_open) {
			maintainer_open=($0 !~ maintainer_close_regexp)
			next
		}
        flag_name=($0 ~ flag_regexp) ? gensub(flag_regexp, "\\1", "g") : ""
        kde_use=(flag_name == kde_use_flag) ? 1 : kde_use
        if (((flag_name > kde_use_flag) || ($0 ~ use_close_regexp)) && ! kde_use) {
            printf("\t<flag name=\"%s\">%s\n\t\t%s</flag>\n",
                    kde_use_flag,
                    "Use OpenSUSE patchset to build in support for native",
					"Plasma Desktop file dialog via <pkg>kde-misc/kmozillahelper</pkg>.")
            kde_use=1
        }
        if (flag_name == "gstreamer-0")
			next
        printf("%s\n", $0)
    }' "${metadata_file}.bak" >"${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

# Rename and patch all ebuild files
for old_ebuild_file in *.ebuild; do
	# Don't process the ebuild files twice!
	if [[ "${old_ebuild_file##*/}" =~ thunderbird\-kde\-opensuse ]]; then
		ebuild_file="${old_ebuild_file}"
		continue
	fi

	ebuild_version="${old_ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#thunderbird-}"
	ebuild_file="${old_ebuild_file/thunderbird/thunderbird-kde-opensuse}"
	for package_unsupported_version in ${package_unsupported_versions}; do
		test_ebuild_version=$(compare_ebuild_versions "thunderbird-kde-opensuse-${package_unsupported_version}" "${ebuild_file}")
		if (( test_ebuild_version == 0)) ; then
			echo "removing ebuild file: \"${ebuild_file}\" (unsupported)"
			rm "${old_ebuild_file}"
			continue 2
		fi
	done
	for ebuild_revision in ${ebuild_revisions}; do
		version="${ebuild_revision%(*}"
		revision="${ebuild_revision#*(}"
		revision="${revision%)}"
		if [[ "${ebuild_version}" == "${version}" ]]; then
			while (( --revision >= 0 )); do
				ebuild_file=$(increment_ebuild_revision "${ebuild_file}")
			done
			break
		fi
	done
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	[[ "${old_ebuild_file}" != "${ebuild_file}" ]]  && mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' -vebuild_file="${ebuild_file}" \
		-vthunderbird_version="${ebuild_version}" \
		--file "tools/${script_name%.*}.awk" \
		--file "tools/common-functions.awk" \
		"${ebuild_file}" 1>"${new_ebuild_file}" #2>/dev/null
	[ -f "${new_ebuild_file}" ] || exit 1
	mv "${new_ebuild_file}" "${ebuild_file}"
done

# Rebuild the master package Manifest file
[ -f "${ebuild_file}" ] && ebuild "${ebuild_file}" manifest
