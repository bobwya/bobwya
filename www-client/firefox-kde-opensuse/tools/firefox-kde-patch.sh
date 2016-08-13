# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
ebuild_revisions="38.8.0(1) 45.2.0(1) 47.0.1(1)"


# Global section
cd "${script_folder%/tools}"

# Import function declarations
. "tools/common-functions.sh"

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
        printf("%s\n", $0)
    }' "${metadata_file}.bak" >"${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

# re-add firefox 47.0.1 as firefox 48.0 could be unstable on some platforms
new_version="47.0.1"
base_version="48.0"
PATCH="${MOZ_PN}-48.0-patches-01"
if [[ -f "firefox-${base_version}.ebuild" && ! -f "firefox-${new_version}.ebuild" && ! -f "firefox-kde-opensuse-${new_version}.ebuild" ]]; then
	cp "firefox-${base_version}.ebuild" "firefox-${new_version}.ebuild"
	sed -i  -e 's:\${PN}\-48\.0\-patches\-01:${MOZ_PN}-47.0-patches-0.1:g' \
			-e 's:>=dev\-libs/nss\-3\.24:>=dev-libs/nss-3.23:g' \
			-e 's:mozconfig\-v6\.48:mozconfig-v6.47:g' \
			-e 's:mozlinguas\-v2:mozlinguas:g' \
			-e '/mozconfig_annotate '\'\'' \-\-enable-extensions="${MEXTENSIONS}"/a \\tmozconfig_annotate '\'\'' --disable-mailnews' \
		"firefox-${new_version}.ebuild"
fi
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
	mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' \
		-vebuild_file="${ebuild_file}" \
		-vfirefox_version="${ebuild_version}" \
		--file "tools/common-functions.awk" \
		--file "tools/${script_name%.*}.awk" \
		"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
	[ -f "${new_ebuild_file}" ] || exit 1
	mv "${new_ebuild_file}" "${ebuild_file}"
done

# Rebuild the master package Manifest file
[ -f "${ebuild_file}" ] && ebuild "${ebuild_file}" manifest
