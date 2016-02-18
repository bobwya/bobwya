# !/bin/awk

BEGIN{
	setup_ebuild_phases("pkg_pretend pkg_setup src_prepare src_compile src_install src_install-libs pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	
	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="QA_TEXTRELS_x86 QA_TEXTRELS_x86_fbsd QA_TEXTRELS_amd64 QA_EXECSTACK_x86 QA_EXECSTACK_amd64 QA_WX_LOAD_x86 QA_WX_LOAD_amd64 QA_FLAGS_IGNORED_amd64 QA_FLAGS_IGNORED_x86"
	setup_global_regexps(variables)
	nvidia_glx_libraries_variable_regexp=(leading_ws_regexp "NV\\_GLX\\_LIBRARIES[+]{0,1}\\=\\(")
	eselect_opengl_check_regexp="app\\-eselect\\\/eselect\\-opengl"
	x11_base_xorg_server_regexp="x11\\-base\\\/xorg\\-server"
	donvidia_call_regexp=(leading_ws_regexp "donvidia")
	X_use_test_regexp="use X"
	has_version_test_regexp="has_version"
	gl_root_regexp="[[:blank:]]+\\$\\{GL\\_ROOT\\}"
	nvidia_xorg_lib_extension_dir_regexp="\\\/opengl\\\/nvidia\\\/extensions"
	nvidia_opengl_lib_dir_regexp="\\\/opengl\\\/nvidia\\\/lib"
	nvidia_xorg_lib_extension_dir="\/xorg\/nvidia\/extensions"
	nvidia_specific_lib_regexp="lib[\\-\\_[:alnum:]]*nvidia[\\-\\_[:alpha:]]*\\.so"
}
{
	suppress_current_line=0	

	if (preamble_over == 0) {
		if ($0 ~ gentoo_copyright_header_regexp)
			sub("[[:digit:]]{4}\\-[[:digit:]]{4}", "1999-2016")

		if (($0 ~ "^IUSE\=\".+\"$") && ($0 ~ "[^+]compat")) {
			sub("compat", "+compat")
			use_compat_found=1
		}
		for (i_variable_regexp in array_variables_regexp) {
			if ($0 ~ array_variables_regexp[i_variable_regexp]) {
				variable_declaration_open=1
				break
			}
		}
		if (variable_declaration_open == 1) {
			gsub(nvidia_xorg_lib_extension_dir_regexp, nvidia_xorg_lib_extension_dir)
		}
		if ($0 ~ end_quote_regexp)
			variable_declaration_open=0
			
		# Change dependency on app-eselect/eselect_opengl to an out-of-tree, patched version
		if ($0 ~ (leading_ws_regexp ebuild_version_comparision_regexp eselect_opengl_check_regexp)) {
			sub(package_version_regexp, ("-" eselect_opengl_supported_version))
			sub(/>=/, "=")
		}
		if ($0 ~ (leading_ws_regexp ebuild_version_comparision_regexp x11_base_xorg_server_regexp)) {
			printf("%s%s>=x11-base/xorg-server-%s\n", indent, indent, xorg_server_supported_version)
			suppress_current_line=1
		}
		
		# Mark all converted ebuilds as unstable
		if ($0 ~ keywords_regexp)
			$0=gensub(keyword_regexp, "~\\1", "g")
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp) == 1) {
		preamble_over=1
		target_block_open=0
	}
	
	# Ebuild phase based pre-checks
	if (array_phase_open["src_install"] == 1) {
		if_stack+=($0 ~ if_open_regexp) ? 1 : 0
		if_stack+=($0 ~ if_close_regexp) ? -1 : 0
		gsub(nvidia_xorg_lib_extension_dir_regexp, nvidia_xorg_lib_extension_dir)
		if (($0 ~ if_open_regexp) && ($0 ~ has_version_test_regexp) && ($0 ~ x11_base_xorg_server_regexp) && (if_stack == 2)) {
			has_version_xorg_server_open=1
			suppress_current_line=1
		}
		if (has_version_xorg_server_open == 1) {
			sub("\\t", "")
			if ($0 ~ if_close_regexp) {
				suppress_current_line=1
				has_version_xorg_server_open=0
			}
		}
	}
	if (array_phase_open["src_install-libs"] == 1) {
		if_stack+=($0 ~ if_open_regexp) ? 1 : 0
		if_stack+=($0 ~ if_close_regexp) ? -1 : 0
		if (($0 ~ (if_open_regexp X_use_test_regexp)) && (if_stack == 1))
			if_use_X_open=1
		if (if_use_X_open == 1) {
			if ($0 ~ nvidia_glx_libraries_variable_regexp)
				nvidia_glx_libraries_variable_open=1
			if ($0 ~ donvidia_call_regexp)
				donvidia_call_open=1
		}
		if (($0 ~ nvidia_specific_lib_regexp) && ((nvidia_glx_libraries_variable_open == 1) || (donvidia_call_open == 1))) {
			sub(gl_root_regexp, "")
		}
		if ($0 ~ end_quote_regexp)
			donvidia_call_open=0
		if ($0 ~ closing_bracket_regexp)
			nvidia_glx_libraries_variable_open=0
		if (($0 ~ if_close_regexp) && (if_stack == 1))
			if_use_X_open=0
	}
	if ((array_phase_open["pkg_postinst"] ==1) &&  ($0 ~ end_curly_bracket_regexp)) {
		if (use_compat_found == 1) {
			printf("%s%s\n", indent, "if ! use compat; then")
			printf("%s%s%s\n", indent,  indent, "ewarn \"USE=compat controls whether the non-GLVND libGL library is installed.\"")
			printf("%s%s%s\n", indent,  indent, "ewarn \"Installing the GLVND libGL library (chosen option) may cause issues with\"")
			printf("%s%s%s\n", indent,  indent, "ewarn \"applications that rely on non-standards compliant Nvidia driver behaviour.\"")
			printf("%s%s\n", indent, "fi")
			printf("\n")
		}
		printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix\"")
		printf("%s%s\n", indent, "ewarn \"issues when switching GL providers.\"")
		printf("%s%s\n", indent, "ewarn \"This package should only be used in conjuction with patched versions of:\"")
		printf("%s%s\n", indent, "ewarn \" * app-select/eselect-opengl\"")
		printf("%s%s\n", indent, "ewarn \" * media-libs/mesa\"")
		printf("%s%s\n", indent, "ewarn \" * x11-base/xorg-server\"")
		printf("%s%s\n", indent, "ewarn \"from the bobwya overlay.\"")
	}
	if ((array_phase_open["pkg_prerm"] == 1) || (array_phase_open["pkg_postrm"] == 1)) {
		if ($0 ~ "eselect opengl")
			sub("xorg\\-x11", "mesa")
	}
	
	# Print current line in ebuild
	if (!suppress_current_line)
		print $0

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=substr($0, RSTART, RLENGTH)

	
	# Ebuild phase based post-checks

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
