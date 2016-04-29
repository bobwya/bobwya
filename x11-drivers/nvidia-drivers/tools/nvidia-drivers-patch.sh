# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
eselect_opengl_supported_version="1.3.2"
xorg_server_supported_version="1.16.4-r6"
nvidia_supported_kms_versions="364.*"
package_unsupported_versions="96 173"
package_name="${script_name%-patch.sh}"

# Global constants
patched_file_comment='experimental version of ${CATEGORY}/${PN}'


# Global section
cd "${script_folder%/tools}"

# Import function declarations
. "tools/common-functions.sh"

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
