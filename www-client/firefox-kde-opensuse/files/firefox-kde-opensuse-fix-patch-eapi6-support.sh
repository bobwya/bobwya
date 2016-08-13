#!/bin/bash

[[ -z "${1}" || ( ! "${1}" =~ ^[[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+|)$ ) ]] && \
	die "parameter 1: Firefox version number"
[[ -z "${2}" || ! -d "${2}" ]] && \
	die "parameter 2: working patch directory"

case "${1}" in
	38.8.0)
		# Make all patches -p1 compliant
		sed -i	-e '/^\(\-\-\-\|+++\)/{s/\/mozilla\-\(beta\|release\)\//\//g;s/\(\.c\|\.cpp\|\.h\)\.orig/\1/g;}' \
				-e 's/^\-\-\- js\//--- a\/js\//g' \
				-e 's/^+++ js\//+++ b\/js\//g' \
		"${2}"/*.patch || die "sed"
		excluded_patches="8010_bug114311-freetype26 8011_bug1194520-freetype261_until_moz43"
		;;
	*)
		die "parameter 1: unsupported Firefox version specified: ${1}"
		;;
esac

if [[ ! -z "${excluded_patches}" ]]; then
	for patch in ${excluded_patches}; do
		mv "${2}/${patch%.patch}.patch" "${2}/${patch%.patch}.patch.bak" || die "mv patch file"
	done
	unset -v excluded_patches patch
fi

exit 0
