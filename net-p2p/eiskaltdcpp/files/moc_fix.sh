#! /bin/bash

# Upstream bug https://bugreports.qt.io/browse/QTBUG-22829 workaround
local header_file
find "$1" -type f -name *.h -print0 |
while IFS= read -r -d '' header_file; do
	cp "${header_file}" "${header_file}.bak"
	awk 'BEGIN{
		regexp_dcc="^\#include[[:blank:]]+(\"dcpp\/.+h\"|<dcpp\/.+h>)$"
		regexp_wrapper_start="^\#ifndef Q_MOC_RUN"
		regexp_wrapper_end="^\#endif"
	}
	{
		if (($0 ~ regexp_dcc) && (previous_record !~ regexp_dcc) && (previous_record !~ regexp_wrapper_start))
			print "#ifndef Q_MOC_RUN"
		else if (($0 !~ regexp_dcc) && (previous_record ~ regexp_dcc) && ($0 !~ regexp_wrapper_end))
			print "#endif"
		print $0

		previous_record=$0
	}' "${header_file}.bak" 1>"${header_file}" 2>/dev/null
	rm "${header_file}.bak"
done
unset header_file
