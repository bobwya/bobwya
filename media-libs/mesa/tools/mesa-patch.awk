# !/bin/awk

BEGIN{
	setup_ebuild_phases("pkg_setup src_prepare multilib_src_configure multilib_src_install multilib_src_install_all multilib_src_test pkg_postinst pkg_prerm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	
	# Setup some regular expression constants - to hopefully make the script more readable!
	blank_line_regexp="^[[:blank:]]*$"
	leading_ws_regexp="^[[:blank:]]+"
	trailing_ws_regexp="^[[:blank:]]+"
	end_quote_regexp="[^=]\"[[:blank:]]*$"
	end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
	variables="OPENGL_DIR"
	split(variables, array_variables)
	for (i in array_variables)
		array_variables_regexp[array_variables[i]]="^" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)"
	if_open_regexp="^[[:blank:]]+if"
	if_close_regexp="^[[:blank:]]+fi"
	emake_target_regexp="emake install DESTDIR=\"\\$\\{D\\}\""
	ebuild_version_comparision_regexp="[\\<\\=\\>\\!]+"
	eselect_opengl_check_regexp=(leading_ws_regexp ebuild_version_comparision_regexp "app\\-eselect\\\/eselect\\-opengl")
	x11_base_xorg_server_regexp=(leading_ws_regexp ebuild_version_comparision_regexp "x11\\-base\\\/xorg\\-server")
	package_version_regexp="\\-[\\.[:digit:]]+(\\-r[[:digit:]]+|)$"
	keywords_regexp="^[[:blank:]]+KEYWORDS=\".+\""
	keyword_regexp="\\~{0,1}(alpha|amd64|arm|arm64|hppa|ia64|mips|ppc|ppc64|s390|sh|sparc|x86|amd64\\-fbsd|x86\\-fbsd|x86\\-freebsd|amd64\\-linux|arm\\-linux|ia64\\-linux|x86\\-linux|sparc\\-solaris|x64\\-solaris|x86\\-solaris)"
}
{
	suppress_current_line=0	

	if (preamble_over == 0) {
		if ($0 ~ gentoo_copyright_header_regexp)
			sub("[[:digit:]]{4}\\-[[:digit:]]{4}", "1999-2016")

		# Change dependency on app-eselect/eselect_opengl to an out-of-tree, patched version
		if ($0 ~ eselect_opengl_check_regexp) {
			sub(package_version_regexp, ("-" eselect_opengl_supported_version))
			sub(/>=/, "=")
		}
		if ($0 ~ x11_base_xorg_server_regexp)
			sub(package_version_regexp, ("-" xorg_server_supported_version))
		
		# Mark all converted ebuilds as unstable
		if ($0 ~ keywords_regexp)
			$0=gensub(keyword_regexp, "~\\1", "g")
			
		# Use mesa (PN) as GL provider
		if ($0 ~ array_variables_regexp["OPENGL_DIR"])
			sub(/xorg\-x11/, "\$\{PN\}")
	}
	
	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp) == 1) {
		preamble_over=1
		target_block_open=0
	}
	
	# Ebuild phase based pre-checks
	if ((array_phase_open["pkg_postinst"] ==1) &&  ($0 ~ end_curly_bracket_regexp)) {
		printf("\n")
		printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues\"")
		printf("%s%s\n", indent, "ewarn \"when switching GL providers.\"")
		printf("%s%s\n", indent, "ewarn \"This package can only be used in conjuction with patched versions of:\"")
		printf("%s%s\n", indent, "ewarn \" * app-select/eselect-opengl\"")
		printf("%s%s\n", indent, "ewarn \" * x11-base/xorg-server\"")
		printf("%s%s\n", indent, "ewarn \" * x11-drivers/nvidia-drivers\"")
		printf("%s%s\n", indent, "ewarn \"from the bobwya overlay.\"")
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
	if (array_phase_open["multilib_src_install"] == 1) {
		if ($0 ~ emake_target_regexp)
			target_block_open=1
		if (target_block_open == 1) {
			printf("\n")
			printf("%s%s\n", indent, "# Move lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} files from /usr/lib to /usr/lib/opengl/mesa/lib")
			printf("%s%s\n", indent, "ebegin \"Moving lib{EGL*,GL*,OpenGL}.{la,a,so*} in order to implement dynamic GL switching support\"")
			printf("%s%s\n", indent, "local gl_dir=\"/usr/$(get_libdir)/opengl/${OPENGL_DIR}\"")
			printf("%s%s\n", indent, "dodir ${gl_dir}/lib")
			printf("%s%s\n", indent, "for x in \"${ED}\"/usr/$(get_libdir)/lib{EGL*,GL*,OpenGL}.{la,a,so*} ; do")
			printf("%s%s%s\n", indent, indent, "if [ -f ${x} -o -L ${x} ]; then")
			printf("%s%s%s%s\n", indent, indent, indent, "mv -f \"${x}\" \"${ED}${gl_dir}\"/lib \\")
			printf("%s%s%s%s%s\n", indent, indent, indent, indent, "|| die \"Failed to move ${x}\"")
			printf("%s%s%s\n", indent, indent, "fi")
			printf("%s%s\n", indent, "done")
			printf("%s%s\n", indent, "eend $?")
			array_phase_open["multilib_src_install"]=2
			target_block_open=0
		}
	}

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}