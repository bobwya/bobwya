#!/bin/env awk

function max(a,b) {
	return (a > b) ? a : b
}

function process_winetricks_detect_gui() {
	if (!kde_use) {
		if ($0 ~ "which kdialog")
			delete_lines=max(delete_lines,3)
	}
	else if ($0 ~ echo_command_regex) {
		sub("zenity", (gtk_use ? "& or kdialog" : "kdialog"))
	}
	if (!gtk_use) {
		if ($0 ~ "which zenity")
			delete_lines=max(delete_lines,5)
		else if ($0 ~ "which kdialog")
			sub("elif", "if")
	}
	if (($0 ~ echo_command_regex) && ($0 ~ "Zenity not found!."))
		delete_lines=max(delete_lines,1)
}

BEGIN{
	echo_command_regex="^[[:blank:]]+echo[[:blank:]]+\".*\"$"
	function_start_regex="^[_[:alpha:]][_[:alnum:]]*\(\)$"
	function_end_regex="^}$"
}

{
	if ($1 ~ function_start_regex)
		current_function=$1
	if (current_function == "winetricks_detect_gui()")
		process_winetricks_detect_gui()
	if ($0 ~ function_end_regex)
		current_function=""
	if (--delete_lines < 0)
		print $0
}