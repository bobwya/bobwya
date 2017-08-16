#!/bin/bash

for variant_file in "${EROOT%/}/etc/eselect/wine/links"/*; do
	variant="${variant_file//*\//--}"
	echo "Updating Wine variant: ${variant#--} ; symbolic links"
	for target in $(eselect wine list ${variant} | awk '{if (NR>1) print $2}'); do
		eselect wine set ${target} ${variant} --force
	done
	sed -i '/^\(bin\|man\)=/d' "${variant_file}"
done

exit 0

