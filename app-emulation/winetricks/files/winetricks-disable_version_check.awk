#!/bin/env awk

BEGIN{
	winetricks_latest_version_check="winetricks_latest_version_check"
	function_start_regex="^[_[:alpha:]][_[:alnum:]]*[(][)]$"
	function_end_regex="^}$"
	if_statement_regex[1]="^    if( |$)"
	fi_statement_regex[1]="^    fi( |$)"
	version_check_regex="[[] [!] \"[$]WINETRICKS_VERSION\" = \"[$][{]latest_version[}]\" []]"
}

{
	if ($1 ~ function_start_regex)
		current_function=$1

	if ((current_function == (winetricks_latest_version_check "()")) && !is_version_check_active)
		is_version_check_active=(($0 ~ if_statement_regex[1]) && ($0 ~ version_check_regex))

	if (!is_version_check_active) print $0
	
	if ((current_function == (winetricks_latest_version_check "()")) && is_version_check_active)
		is_version_check_active=($0 !~ fi_statement_regex[1])

	if ($0 ~ function_end_regex) current_function=""
}
