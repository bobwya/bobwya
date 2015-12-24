#!/bin/bash

if [ "$#" -ne 1 ] || [ ! -d "${1}" ]; then
	exit 1 
fi

find "${1}" -type f -print0 | xargs -0 file -F '|' -0 | awk -F '|' '{if ($2 ~ /shell script/) printf("%s", $1) }' | xargs -0 chmod +x

exit 0

