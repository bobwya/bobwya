# !/bin/awk

function convert_version_list_to_regexp(version_list,
	version_regexp)
{
	version_regexp=version_list
	gsub("(\\.|\\-)", "\\\\&", version_regexp)
	gsub("\\*", ".*", version_regexp)
	gsub("[[:blank:]]+", "|", version_regexp)
	sub("^", "^(", version_regexp)
	sub("$", ")$", version_regexp)

	return (version_regexp)
}

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
	end_curly_bracket_regexp="^\}[[:blank:]]*$"
	if (line ~ end_curly_bracket_regexp) {
		for (i in array_ebuild_phases)
			array_phase_open[array_ebuild_phases[i]]=0
	}
}

function text2regexp(text, multi,
		endmarker,regexp,startmarker)
{
	regexp=text
	startmarker=sub("^\\^", "", regexp)
	endmarker=sub("\\$$", "", regexp)
	# Escape all control regex characters
	gsub("\\\\", "\x5c\x5c&", regexp)
	gsub("\\_|\\!|\\\"|\\#|\\$|\\%|\\&|\x27|\\(|\\)|\\+|\\,|\\-|\\.|\\/|\\:|\\;|\x3c|\\=|\x3e|\\?|\\@|\\[|\\]|\\{|\\|\\}|\\~", "\x5c\x5c&", regexp)
	multi || gsub("\\|", "\\|", regexp)
	gsub("\x20", "[[:blank:]]+", regexp)
	gsub("\\*", ".+", regexp)
	regexp=((startmarker ? "^" : "") regexp (endmarker ? "$" : ""))
	if (multi == 1) {
		regexp=gensub("(^[^\\(]*)\\\\\\\(", "\\1(", 1, regexp)
		regexp=gensub("\\\\\\\)([^\\)]*$)", ")\\1", 1, regexp)
	}
	else if (multi == 2) {
		regexp=gensub("\\\\\(\\(|\\))", "\\1", "g", regexp)
	}
	return regexp
}

function get_associated_command(array_ebuild_file, line,
		array_line,command,ifield,offset)
{
	for (offset=0; (line-offset) >= 1; ++offset) {
		if (((line-offset) >= 2) && (array_ebuild_file[line-offset-1] ~ "\\\\([[:blank:]]*|[[:blank:]]+\\#.+)$"))
			continue

		ifield=split(array_ebuild_file[line-offset], array_line)-1
		if (!offset && (array_ebuild_file[line-offset] !~ text2regexp(" die$"))) {
			while (--ifield >= 1) {
				if ((array_line[ifield+1] == "die") && (array_line[ifield+2] ~ "^\\#"))
					break
			}
		}
		while (--ifield >= 1) {
			if ((array_line[ifield] == "||") || (array_line[ifield] == "&&"))
				break
		}
		while (++ifield && (array_line[ifield] ~ "^[[:blank:]]*$"))
			;
		if (ifield && (array_line[ifield] ~ "^(cat|cd|cp|dodir|doins|echo|mkdir|mv|popd|pushd|rm|sed|unzip)$"))
			command=array_line[ifield]
		break
	}
	return (command)
}

function setup_global_regexps(variables,		i)
{
	bracketed_expression_open_regexp="\\("
	bracketed_expression_close_regexp="\\)"
	bracketed_expression_regexp="\\([^\\)]*\\)"
	blank_line_regexp="^[[:blank:]]*$"
	leading_ws_regexp="^[[:blank:]]+"
	trailing_ws_regexp="[[:blank:]]+$"
	comment_regexp=("^[[:blank:]]*\\#.*$")
	end_quote_regexp="(^|[^=])\"[[:blank:]]*(|\\#.+|\\\\)$"
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
