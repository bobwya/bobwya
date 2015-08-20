#! /bin/bash

# Fix large font sizes
font_delta=${2:=0}
find "$1" -type f -name "*.ui" -print0 |
while IFS= read -r -d '' ui_path; do
	ui_path=$(readlink -f "${ui_path}")
	for pointsize in {8..16}; do	
		sed -i	-e "s|<pointsize>$((pointsize))</pointsize>|<pointsize>$((pointsize+font_delta))</pointsize>|g" \
				-e "s|font-size:$((pointsize))pt|font-size:$((pointsize+font_delta))pt|g" \
				"${ui_path}"
	done
	sed -i	-e "s|<bold>true</bold>|<bold>false</bold>|g" \
			-e "s|<weight>75</weight>|<weight>50</weight>|g" \
			"${ui_path}"
	ui_folder=$(dirname "${ui_path}")
	ui_file=$(basename "${ui_path}")
	/usr/bin/pyuic4 "${ui_file}" > "${ui_folder}/Ui_${ui_file%.ui}.py"
done
unset font_delta ui_file ui_folder ui_path

