
BEGIN{
	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="IUSE RDEPEND REQUIRED_USE"
	setup_global_regexps(variables)
	eclass_phases="moz_pkgsetup mozconfig_config mozconfig_init mozversion_extension_location mozlinguas_export mozlinguas_src_unpack mozlinguas_src_compile mozlinguas_src_install mozlinguas-v2_src_unpack mozlinguas-v2_src_compile mozlinguas-v2_src_install"
	setup_ebuild_phases(eclass_phases, array_eclass_phases, array_phase_open, array_eclass_phases_regexp)
}
{
	suppress_current_line=0

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	# Make ebuild's use consistent spacing/layout throughout...
	if ($0 ~ text2regexp("^( |)if",1))
		sub(text2regexp(" ; then"), "; then")

	# Alter current ebuild line before it is printed
	if (!preamble_over) {
		is_eclass_line=0
		if ($0 ~ text2regexp("^# ")) {
			sub("Copyright 1999\-[[:digit:]]{4} Gentoo Foundation", "Copyright 1999-2016 Gentoo Foundation")
			is_eclass_line=sub(text2regexp("@ECLASS: *$"), ("@ECLASS: " eclass_file))
			gsub(text2regexp(", and potentially seamonkey"), "")
			gsub(text2regexp(" and seamonkey "), " ")
			if ($0 ~ text2regexp("(This eclass is used in mozilla ebuilds|common mozilla engine compoments)",1))
				suppress_current_line=1
		}

		if (! is_eclass_line)
			gsub(text2regexp("moz(coreconf|extension)",1), "&-kde")
		if (eclass_file ~ "^mozlinguas") {
			if ((if_stack == 1) && ($0 ~ if_close))
				if_seamonkey_test_open=0
			if (if_seamonkey_test_open)
				sub("^", "\t")
			if ((if_stack == 2) && ($0 ~ if_open_regexp) && sub(text2regexp(" || { [[ ${PN} == seamonkey ]] && ! [[ ${PV} =~ alpha ]] ; }"), "")) {
				if_seamonkey_test_open=1
			}
			sub(text2regexp(" && ! [[ ${PN} == seamonkey ]]"), " ")
		}
		# Process initial variables
		if ($0 ~ array_variables_regexp["IUSE"]) {
			sub(text2regexp(" gstreamer-0 "), " ")
		}
		else if ($0 ~ array_variables_regexp["RDEPEND"]) {
			rdepend_open=1
		}
		else if ($0 ~ array_variables_regexp["REQUIRED_USE"]) {
			required_use_open=1
		}
		if (rdepend_open) {
			if (sub(text2regexp("gstreamer-0? ("), ""))
				gstreamer0_use_open=1
			if (gstreamer0_use_open) {
				suppress_current_line=1
				gstreamer0_use_open=($0 ~ text2regexp(")$")) ? 0 : 1
			}
			rdepend_open=($0 ~ end_quote_regexp) ? 0 : 1
		}
		else if (required_use_open) {
			if (sub(text2regexp("?? ( gstreamer gstreamer-0 )"), "") && ($0 ~ blank_line_regexp))
				suppress_current_line=1
			required_use_open=($0 ~ end_quote_regexp) ? 0 : 1
		}
		if (required_use_comment_open)
			sub(text2regexp("^# also"), "#")
		if ($0 ~ text2regexp("^# only one of gstreamer and gstreamer-0 can be enabled at a time")) {
			suppress_current_line=1
			required_use_comment_open=1
		}
	}

	if ((eclass_file == "mozlinguas-kde-v2.eclass") || (eclass_file == "mozlinguas-kde.eclass")) {
		$0=gensub((text2regexp("(mozlinguas)(-v2|)_(export|src_unpack|mozconfig|src_compile|src_install|xpistage_langpacks)",2) "([^\\-\\_[:alpha:]]|$)"), "\\1-kde\\2_\\3\\4", "g")
	}

	sub(text2regexp("^# inherit mozconfig-"), "# inherit mozconfig-kde-")


	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_eclass_phases, array_phase_open, array_eclass_phases_regexp)) {
		preamble_over=1
		if_stack=0
		target_block_open=0
	}

	# Ebuild phase based pre-checks
	if (array_phase_open["moz_pkgsetup"]) {
		gsub(text2regexp("${PN}"), "${MOZ_PN}")
	}
	else if	(array_phase_open["mozconfig_config"]) {
		gsub(text2regexp("${PN}"), "${MOZ_PN}")
		if ($0 ~ text2regexp("(gstreamer-0|gstreamer:0.10)",1))
			suppress_current_line=1
		if ($0 ~ text2regexp("if [[ ${MOZ_PN} != seamonkey ]]; then")) {
			seamonkey_if_test_open=1
			suppress_current_line=1
		}
		if (seamonkey_if_test_open)
			sub(indent, "")
		if (seamonkey_if_test_open && ($0 ~ if_close_regexp)) {
			seamonkey_if_test_open=0
			suppress_current_line=1
		}
	}
	else if (array_phase_open["mozconfig_init"]) {
		gsub(text2regexp("${PN}"), "${MOZ_PN}")
		if ($0 ~ text2regexp("if [[ ${MOZ_PN} != seamonkey ]]; then")) {
			seamonkey_if_test_open=1
			suppress_current_line=1
		}
		if (seamonkey_if_test_open)
			sub(indent, "")
		if (seamonkey_if_test_open && ($0 ~ if_close_regexp)) {
			seamonkey_if_test_open=0
			suppress_current_line=1
		}
		if ($0 ~ text2regexp("${MOZ_PN} == seamonkey"))
			suppress_current_line=1
		if ($0 ~ text2regexp("^ case ${MOZ_PN}"))
			case_moz_pn_open=1
		if (case_moz_pn_open) {
			if ($0 ~ text2regexp("^ seamonkey)"))
				seamonkey_case_open=1
			suppress_current_line=suppress_current_line || seamonkey_case_open
			if ($0 ~ text2regexp(";;$"))
				seamonkey_case_open=0
			case_moz_pn_open=($0 ~ text2regexp("^ esac")) ? 0 : 1
		}
	}
	else if (array_phase_open["mozversion_extension_location"]) {
		gsub(text2regexp("${PN}"), "${MOZ_PN}")
	}
	else if (array_phase_open["mozlinguas_export"]) {
		if ((if_stack == 1) && ($0 ~ text2regexp("if [[ ${PN} == seamonkey ]]; then")))
			seamonkey_if_test_open=1
		if (seamonkey_if_test_open) {
			if (($0 ~ else_regexp) || ($0 ~ if_open_regexp) || ($0 ~ if_close_regexp))
				suppress_current_line=1
			else
				sub(indent, "")
			seamonkey_if_test_open=($0 ~ if_close_regexp) ? 0 : 1
		}
	}
	else if (array_phase_open["mozlinguas_src_compile"]) {
		gsub(text2regexp("${PN}"), "${MOZ_PN}")
		if ($0 ~ text2regexp("^ case ${MOZ_PN}"))
			case_moz_pn_open=1
		if (case_moz_pn_open) {
			if ($0 ~ text2regexp("^ seamonkey)"))
				seamonkey_case_open=1
			suppress_current_line=suppress_current_line || seamonkey_case_open
			if ($0 ~ text2regexp(";;$"))
				seamonkey_case_open=0
			case_moz_pn_open=($0 ~ text2regexp("^ esac")) ? 0 : 1
		}
	}

	# Print current line in ebuild
	if (!suppress_current_line) {
		# Eat more than 1 empty line
		blank_lines=($0 ~ blank_line_regexp) ? blank_lines+1 : 0
		if (blank_lines <= 1) {
			print $0
			array_ebuild_file[++ebuild_line]=$0
		}
	}

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=substr($0, RSTART, RLENGTH)

	# Print extra stuff after the current ebuild line has been printed
	if (!preamble_over) {
		if (! is_description_printed  && ($0 ~ text2regexp("^# @DESCRIPTION:"))) {
			if (eclass_file ~ "^mozconfig") {
				printf("%s\n", "# This eclass is used in mozilla ebuilds (firefox-kde-opensuse, thunderbird-kde-opensuse),")
				printf("%s\n", "# patched with the unofficial OpenSUSE KDE patchset.")
				printf("%s\n", "# Providing a single location for common mozilla engine components.")
				is_description_printed=1
			}
		}

	}
	# Ebuild phase based post-checks


	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_eclass_phases, array_phase_open)
}

