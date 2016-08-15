#!/bin/bash

[[ -z "${1}" || ( ! "${1}" =~ ^[[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+|)$ ) ]] && \
	die "parameter 1: ${PN} version number"
[[ -z "${2}" || ! -d "${2}" ]] && \
	die "parameter 2: working patch directory"

# Make all patches -p1 compliant
sed -i	-e '/^\(\-\-\-\|+++\)/{s/\/mozilla\-\(beta\|release\)\//\//g;s/\(\.c\|\.cpp\|\.h\)\.orig/\1/g;}' \
		-e 's/^\-\-\- js\//--- a\/js\//g' \
		-e 's/^+++ js\//+++ b\/js\//g' \
	"${2}"/*.patch || die "sed"

case "${1}" in
	24.8.0 | 31.8.0)
		;;
	38.*)
		excluded_patches="8010_bug114311-freetype26";;
	*)
		die "parameter 1: unsupported ${PN} version specified: ${1}"
		;;
esac

if [[ ! -z "${excluded_patches}" ]]; then
	for patch in ${excluded_patches}; do
		mv "${2}/${patch%.patch}.patch" "${2}/${patch%.patch}.patch.bak" || die "mv patch file"
	done
	unset -v excluded_patches patch
fi

exit 0
