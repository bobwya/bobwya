# !/bin/awk

function setup_ebuild_phases(ebuild_phases, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp,
		i)
{
	split(ebuild_phases, array_ebuild_phases)
	for (i in array_ebuild_phases) {
		array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
		array_phase_open[array_ebuild_phases[i]]=0
	}
}

function process_ebuild_phase_open(line, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp,
		new_phase_active, i)
{
	for (i in array_ebuild_phases) {
		if (line ~ array_ebuild_phases_regexp[array_ebuild_phases[i]]) {
			new_phase_active=i
			break
		}
	}
	if (new_phase_active == "")
		return 0

	for (i in array_ebuild_phases)
		array_phase_open[array_ebuild_phases[i]]=0
	array_phase_open[array_ebuild_phases[new_phase_active]]=1
	return 1
}

function process_ebuild_phase_close(line, array_ebuild_phases, array_phase_open,
		end_curly_bracket_regexp, i)
{
	end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
	if (line ~ end_curly_bracket_regexp) {
		for (i in array_ebuild_phases)
			array_phase_open[array_ebuild_phases[i]]=0
	}
}

function setup_global_regexps(variables,		i)
{
	bracketed_expression_open_regexp="\\("
	bracketed_expression_close_regexp="\\)"
	bracketed_expression_regexp="\\([^\\)]*\\)"
	blank_line_regexp="^[[:blank:]]*$"
	leading_ws_regexp="^[[:blank:]]+"
	trailing_ws_regexp="[[:blank:]]+$"
	comment_regexp=(leading_ws_regexp "\\#")
	end_quote_regexp="[^=]\"[[:blank:]]*$"
	quote_or_ws_seperator_regexp="([[:blank:]]+|\")"
	end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
	closing_bracket_regexp="\\)$"
	if_open_regexp="^[[:blank:]]*if.+then$"
	else_regexp="^[[:blank:]]*else"
	if_close_regexp="^[[:blank:]]*fi"
	ebuild_version_comparision_regexp="[\\<\\=\\>\\!]+"
	package_version_regexp="\\-[\\.[:digit:]]+(\\-r[[:digit:]]+|)$"
	keywords_regexp="^[[:blank:]]+KEYWORDS=\".+\""
	keyword_regexp="\\~{0,1}(alpha|amd64|arm|arm64|hppa|ia64|mips|ppc|ppc64|s390|sh|sparc|x86|amd64\\-fbsd|x86\\-fbsd|x86\\-freebsd|amd64\\-linux|arm\\-linux|ia64\\-linux|x86\\-linux|sparc\\-solaris|x64\\-solaris|x86\\-solaris)"
	ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
	gentoo_copyright_header_regexp="^# Copyright.+Gentoo Foundation$"

	split(variables, array_variables)
	for (i in array_variables)
		array_variables_regexp[array_variables[i]]=("^[[:blank:]]*" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)")
}
