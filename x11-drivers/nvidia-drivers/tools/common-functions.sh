#!/bin/bash

# Function Definitions
increment_ebuild_revision ()
{
	echo "${1}" | awk -F'[\-\_\.]' \
		'{
			if (NF < 3)
				exit 1
			if ($NF != "ebuild")
				exit 2
			
			ebuild=$0
			revision=$(NF-1)
			if (sub("^r", "", revision) == 1)
				sub("\\-r[[:digit:]]+\\.ebuild$", ("-r" revision+1 ".ebuild"), ebuild)
			else
				sub("\\.ebuild$", "-r1.ebuild", ebuild)
			print ebuild
		}' 2>/dev/null
}

get_ebuild_revision ()
{
	echo "${1}" | awk -F'[\-\_\.]' \
		'{
			if (NF < 3)
				exit 1
			if ($NF != "ebuild")
				exit 2

			revision=$(NF-1)
			if (sub("^r", "", revision) == 0)
				revision=0
			print revision
		}' 2>/dev/null
}

get_ebuild_version ()
{
	selected_version="${2:-*}"
	echo "${1}" | awk -F'[\-\_\.]' -vselected_version="${selected_version}" \
		'{
			number_regex="^[[:digit:]]+$"
			if (NF < 3)
				exit 1
			if ($NF != "ebuild")
				exit 2
			if (selected_version == "*") {
				selected_version=1
				select_all=1
			}
			if (selected_version !~ number_regex)
				exit 3

			for (ifield=2; (ifield < NF) && ((selected_version > 0) || (select_all == 1)); ++ifield) {
				if ($ifield ~ number_regex)
					found_number=1
				else if (found_number == 1)
					break
				if ((found_number != 1) || (--selected_version > 0))
					continue
				printf("%s%s", (is_output == 1) ? "." : "", $ifield)
				is_output=1
			}
			if (is_output == 1)
				printf("\n")
		}' 2>/dev/null
}

compare_ebuild_versions ()
{
	local ebuild1="${1%.ebuild}.ebuild"
	local ebuild2="${2%.ebuild}.ebuild"
	local compare_active=true
	local i=1
	local result=0


	while [[ ${compare_active} == true ]]; do
		version1=$(get_ebuild_version ${ebuild1} ${i})
		version2=$(get_ebuild_version ${ebuild2} ${i})
		if [[ "${version1}" == "" ]] || [[ "${version2}" == "" ]]; then
			break
		fi

		compare_active=false
		if (( version1 < version2 )); then
			result=-1
		elif (( version1 > version2 )); then
			result=1
		else
			compare_active=true
			i=$((++i))
		fi
	done
	echo ${result}
}

remove_obsolete_ebuild_revisions ()
{
	local ebuild_file="${1}"
	local is_match=false
	local ebuild_version=$(get_ebuild_version ${ebuild_file})
	local ebuild_revision=$(get_ebuild_revision ${ebuild_file})
	local array_size=${#array_ebuilds[@]}
	local i

	for (( i = 0 ; i < array_size ; i++ )); do
		iebuild_version=$(get_ebuild_version "${array_ebuilds[i]}")
		if [[ "${iebuild_version}" != "${ebuild_version}" ]]; then
			continue
		fi
		is_match=true
		iebuild_revision=$(get_ebuild_revision "${array_ebuilds[i]}")
		if (( iebuild_revision < ebuild_revision )); then
			local tmp="${array_ebuilds[i]}"
			array_ebuilds[${i}]="${ebuild_file}"
			ebuild_file="${tmp}"
		fi
		echo "removing ebuild file: \"${ebuild_file}\" (older revision)"
		rm "${ebuild_file}"
		break
	done
	if [[ ${is_match} == false ]]; then
		array_ebuilds[${array_size}]="${ebuild_file}"
	fi
}