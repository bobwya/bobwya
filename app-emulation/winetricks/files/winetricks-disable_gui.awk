#!/bin/env awk

BEGIN{
	winetricks_detect_gui="winetricks_detect_gui"
	winetricks_detect_gui_regex=("^[[:blank:]]*" winetricks_detect_gui "$")
	gui_option_regex="^[[:blank:]]*[-][-]gui[)[:blank:]]"
	function_start_regex="^[_[:alpha:]][_[:alnum:]]*\(\)$"
	function_end_regex="^}$"
}

{
	if ($1 ~ function_start_regex)
		current_function=$1

	if ((current_function != (winetricks_detect_gui "()")) && ($0 !~ winetricks_detect_gui_regex) && ($0 !~ gui_option_regex))
		print $0

	if ($0 ~ function_end_regex)
		current_function=""
}