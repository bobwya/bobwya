# !/bin/awk

BEGIN{
	setup_ebuild_phases("pkg_pretend src_configure src_install pkg_postinst pkg_preinst pkg_postinst pkg_prerm pkg_postrm dynamic_libgl_install",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	
	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="CDEPEND"
	setup_global_regexps(variables)
	invalid_pkg_postrm_comment_regexp="# Get rid of module dir to ensure opengl\\-update works properly"
	media_libs_mesa_check_regexp="media\\-libs\\\/mesa"
	eselect_opengl_check_regexp="app\\-eselect\\\/eselect\\-opengl"
	media_libs_mesa="media-libs/mesa"
	eselect_opengl="app-eselect/eselect-opengl"
}
{
	suppress_current_line=0

	if (preamble_over == 0) {
		if ($0 ~ gentoo_copyright_header_regexp)
			sub("[[:digit:]]{4}\\-[[:digit:]]{4}", "1999-2016")
			
		if ($0 ~ array_variables_regexp["CDEPEND"])
			cdepend_open=1
		# Change dependency on app-eselect/eselect_opengl to an out-of-tree, patched version
		if (cdepend_open == 1) {
			if ($0 ~ (ebuild_version_comparision_regexp eselect_opengl_check_regexp)) {
				sub(ebuild_version_comparision_regexp eselect_opengl_check_regexp, ("=" eselect_opengl))
				sub(package_version_regexp, ("-" eselect_opengl_supported_version))
				suppress_current_line=eselect_opengl_found
				eselect_opengl_found=1
			}
			if ($0 ~ (ebuild_version_comparision_regexp media_libs_mesa_check_regexp)) {
				sub(ebuild_version_comparision_regexp media_libs_mesa_check_regexp, (">=" media_libs_mesa))
				sub(package_version_regexp, ("-" mesa_supported_version))
			}
		}
		if ($0 ~ end_quote_regexp)
			cdepend_open=0

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
		if ($0 ~ (leading_ws_regexp "dynamic\\_libgl\\_install$"))
			dynamic_libgl_install_call=1
		else if ($0 !~ blank_line_regexp)
			dynamic_libgl_install_call=0
		suppress_current_line=dynamic_libgl_install_call
	}
	else if (array_phase_open["pkg_postinst"] == 1) {
		if ($0 ~ (leading_ws_regexp "eselect opengl set"))
			sub("xorg\\-x11", "mesa")

		if ($0 ~ end_curly_bracket_regexp) {
			printf("\n")
			printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues\"")
			printf("%s%s\n", indent, "ewarn \"when switching GL providers.\"")
			printf("%s%s\n", indent, "ewarn \"This package can only be used in conjuction with patched versions of:\"")
			printf("%s%s\n", indent, "ewarn \" * app-select/eselect-opengl\"")
			printf("%s%s\n", indent, "ewarn \" * media-libs/mesa\"")
			printf("%s%s\n", indent, "ewarn \" * x11-drivers/nvidia-drivers\"")
			printf("%s%s\n", indent, "ewarn \"from the bobwya overlay.\"")
		}
	}
	else if (array_phase_open["dynamic_libgl_install"] == 1) {
		suppress_current_line=1
	}

	if ((suppress_current_line == 0) && (blank_previous_line == 1) && ($0 ~ blank_line_regexp))
		suppress_current_line=1

	# Print current line in ebuild
	if (!suppress_current_line) {
		print $0
		blank_previous_line=($0 ~ blank_line_regexp) ? 1 : 0
	}
	
	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=substr($0, RSTART, RLENGTH)

	
	# Ebuild phase based post-checks
	
	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}