# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global version constants
eclass_unsupported_versions="mozcoreconf-2 mozilla-launcher"

# Global section
cd "${script_folder%/tools}"

# Import function declarations
. "tools/common-functions.sh"


# Rename and patch all the stock Mozilla eclass files
cd "${script_folder%/tools}"
rsync -achvu --progress /usr/portage/eclass/moz* .

# Rename and patch all eclass files
for old_eclass_file in *.eclass; do
	# Don't process the eclass files twice!
	if [[ "${old_eclass_file##*/}" =~ \-kde[\-\.] ]]; then
		eclass_file="${old_eclass_file}"
		continue
	fi

	for eclass_unsupported_version in ${eclass_unsupported_versions}; do
		if [[ "${old_eclass_file%.eclass}" == "${eclass_unsupported_version}" ]]; then
			echo "removing eclass file: \"${old_eclass_file}\" (unsupported)"
			rm "${old_eclass_file}"
			continue 2
		fi
	done

	eclass_version=$(echo "${old_eclass_file%.eclass}" | sed 's/^[^\.[:digit:]]\+\(.*\)/\1/')
	[[ -z "${eclass_version}" ]] && eclass_version="1"
	eclass_file=$( echo "${old_eclass_file}" | sed 's/\([[:alpha:]]\+\)\(\-kde\|\)/\1-kde/' )
	new_eclass_file="${eclass_file}.new"
	echo "processing eclass file: \"${old_eclass_file}\" -> \"${eclass_file}\""
	mv "${old_eclass_file}" "${eclass_file}"
	awk -F '[[:blank:]]+' \
		-veclass_file="${eclass_file}" \
		-veclass_version="${eclass_version}" \
		--file "tools/common-functions.awk" \
		--file "tools/${script_name%.*}.awk" \
		"${eclass_file}" 1>"${new_eclass_file}" 2>/dev/null
	[ -f "${new_eclass_file}" ] || exit 1
	mv "${new_eclass_file}" "${eclass_file}"
done
