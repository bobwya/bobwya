# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
eselect_opengl_supported_version="1.3.2"
xorg_server_supported_version="1.16.4-r6"
nvidia_supported_kms_versions="364.* 367.*"
package_unsupported_versions="96 173"
package_name="${script_name%-patch.sh}"

# Global constants
patched_file_comment='experimental version of ${CATEGORY}/${PN}'


# Global section
# Import function declarations
. "${script_folder}/common-functions.sh"

cd "${script_folder%/tools}/files"

echo "Processing full patchset to ensure EAPI=6 patch -p1 support"
sed -i  -e "/^Binary files.*differ$/d" \
		-e "/^\(\-\-\-\|diff \)/{s/ NVIDIA\-Linux\-x86\_64\-355\.06\.orig\// a\//g;s/ work\.orig\// a\//g;s/ kernel\.orig\// a\/kernel\//g;s/ NVIDIA\_GLX\-1\.0\-4191\// a\//g;s/ usr\// a\/usr\//g;s/gl\.g\.orig./gl\.h /g}" \
		-e "/^\(+++\|diff \)/{s/ NVIDIA\-Linux\-x86\_64\-355\.06\// b\//g;s/ work\// b\//g;s/ kernel\// b\/kernel\//g;s/ NVIDIA\_GLX\-1\.0\-4191\.new\// b\//g;s/ usr\// b\/usr\//g}" \
	*.patch
echo "Processing full patchset to revision bump patches that have been modified"
while read patch_file; do
	[[ -f "${patch_file}" ]] || continue
	patch_file="${patch_file#${PWD%/}/}"
	revision=$(get_patch_revision "${patch_file}")
	new_patch_file=$(increment_patch_revision "${patch_file}")
	echo "Creating new revision (${new_patch_file}) of patch file: ${patch_file}"
	mv "${patch_file}" "${new_patch_file}"
	term1="$(echo "${patch_file}"		| sed -e '{s/^nvidia\-drivers/${PN}/;s/[-\.\$]/\\&/g}' )"
	term2="$(echo "${new_patch_file}"	| sed -e '{s/^nvidia\-drivers/${PN}/;s/[-\.\$]/\\&/g}' )"
	echo "Update all ebuild files from: ${patch_file} -> ${new_patch_file}"
	sed -i -e 's:'"${term1}"':'"${term2}"':g' "${script_folder%/tools}"/*.ebuild
done <<<"$(diff -qr "${script_folder%/tools}/files/" "/usr/portage/x11-drivers/nvidia-drivers/files/" | gawk '{ if ($1 == "Files") printf("%s\n\n", $2) }')"

cd "${script_folder%/tools}"

# Remove Changelogs - as this is an unofficial package
rm ChangeLog* 2>/dev/null


# Remove all obsolete ebuild files
declare -a array_ebuilds
for ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q "${patched_file_comment}" "${ebuild_file}" ; then
		continue
	fi

	for package_unsupported_version in ${package_unsupported_versions}; do
		test_ebuild_version=$(compare_ebuild_versions "nvidia-drivers-${package_unsupported_version}" "${ebuild_file}")
		if (( test_ebuild_version == 0)) ; then
			echo "removing ebuild file: \"${ebuild_file}\" (unsupported)"
			rm "${ebuild_file}"
			continue 2
		fi
	done

	if [[ $(compare_ebuild_versions "nvidia-drivers-${package_supported_version}" "${ebuild_file}") -eq 1 ]] ; then
		echo "removing ebuild file: \"${ebuild_file}\" (unsupported)"
		rm "${ebuild_file}"
		continue
	fi

	remove_obsolete_ebuild_revisions "${ebuild_file}"
done

# Process all remaining ebuild files
for old_ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q "${patched_file_comment}" "${old_ebuild_file}" ; then
		continue
	fi

	ebuild_file=$(increment_ebuild_revision "${old_ebuild_file}")
	new_ebuild_file="${ebuild_file}.new"
	echo "Processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	mv "${old_ebuild_file}" "${ebuild_file}"
	nvidia_version="${ebuild_file#${package_name}-}"
	nvidia_version="${nvidia_version%-*.ebuild}"
	awk -F '[[:blank:]]+' \
			-veselect_opengl_supported_version="${eselect_opengl_supported_version}" \
			-veselect_opengl_supported_version="${eselect_opengl_supported_version}" \
			-vxorg_server_supported_version="${xorg_server_supported_version}" \
			-vnvidia_supported_kms_versions="${nvidia_supported_kms_versions}" \
			-vnvidia_version="${nvidia_version}" \
			--file "tools/common-functions.awk" \
			--file "tools/${script_name%.*}.awk" \
			"${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done

# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
