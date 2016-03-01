# !/bin/awk

function convert_version_list_to_regexp(version_list,
	version_regexp)
{
	version_regexp=version_list
	gsub("\\.", "\\.", version_regexp)
	gsub("\\*", ".*", version_regexp)
	gsub("[[:blank:]]+", "|", version_regexp)
	sub("^", "^(", version_regexp)
	sub("$", ")$", version_regexp)
	
	return (version_regexp)
}

BEGIN{
	setup_ebuild_phases("pkg_pretend pkg_setup src_unpack src_prepare src_configure multilib_src_configure multilib_src_test multilib_src_install_all pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	
	# Setup some regular expression constants - to hopefully make the script more readable!
	ebuild_inherit_regexp="^inherit "
	variables="COMMON_DEPEND RDEPEND DEPEND IUSE GST_P KEYWORDS STAGING_P STAGING_DIR REQUIRED_USE SRC_URI"
	setup_global_regexps(variables)
	emake_target_regexp="emake install DESTDIR=\"\\$\\{D\\}\""
	eselect_check_regexp="^[[:blank:]]+[\\>\\=\\>]+app\\-eselect\\\/eselect\\-opengl"
	source_wine_staging_patcher_regexp="^[[:blank:]]*source[[:blank:]]+\".*patchinstall\\.sh.*\"$"
	check_for_pv9999_regexp="\\[\\[ \\$\\{PV\\} == \"9999\" \\]\\]"
	test_gstreamer_or_staging_regexp="\\?\\?[[:blank:]]+\\([[:blank:]]+gstreamer[[:blank:]]+staging[[:blank:]]+\\)"
	gstreamer_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gstreamer:[\.[:digit:]]+"
	gst_plugins_base_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gst-plugins-base:[\.[:digit:]]+"
	patchset_regexp="local[[:blank:]]+PATCHES=\\("
	use_custom_cflags_regexp="use[[:blank:]]+custom\\-cflags"
	staging_use_enabled_regexp="staging\\?[[:blank:]]+"
	staging_use_test_regexp="use[[:blank:]]+staging"
	gstreamer_use_enabled_regexp="gstreamer\\?[[:blank:]]+"
	gstreamer_use_test_regexp="use gstreamer"
	configure_use_with_regexp="\\$\\(use_with[[:blank:]].+\\)"
	package_regexp="\\$\\{P\\}"
	package_version_variable_regexp="\\$\\{PV\\}"
	staging_use_flags_regexp="[\+]{0,1}(pipelight|s3tc|staging|vaapi)"
	add_gst_patch_regexp="PATCHES\\+\\=\\( \"\\$\\{WORKDIR\\}\\/\\$\\{GST\\_\\P}\\.patch\" \\)"
	
	legacy_gstreamer_wine_version_regexp=convert_version_list_to_regexp(legacy_gstreamer_wine_versions)
	suppress_staging_wine_version_regexp=convert_version_list_to_regexp(wine_staging_unsupported_versions)
	gcc_stack_alignment_forced_version_regexp=convert_version_list_to_regexp("1.9.3 1.9.4")
}

{
	suppress_current_line=0	

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	if (($0 ~ if_open_regexp) && ($0 ~ check_for_pv9999_regexp) && (if_check_pv9999_open == 0)) {
		if_check_pv9999_open=if_stack
		if_check_pv9999_count+=1
	}
	else if ((if_check_pv9999_open > 0) && (if_check_pv9999_open == if_stack) && ($0 ~ else_regexp))
		else_check_pv9999_open=1
				
	if (preamble_over == 0) {
		if ((if_check_pv9999_open == 1) && ($0 ~ "EGIT_BRANCH=\"master\"")) {
			printf("%s%s\n", indent, "GSTREAMER_COMMIT=\"e8311270ab7e01b8c58ec615f039335bd166882a\"")
			suppress_current_line=1
		}
			
		if ($0 ~ array_variables_regexp["SRC_URI"])
			src_uri_open=1
		
		if (src_uri_open == 1) {
			if ($0 ~ "\"https\:.+\"")
				sub("\\$\\{P\\}.tar.bz2\"$", "${MY_P}.tar.bz2 -> ${P}.tar.bz2\"")
			
			if ($0 ~ staging_use_enabled_regexp)
				sub(package_version_variable_regexp, "${MY_PV}")
			
			if ($0 ~ gstreamer_use_enabled_regexp) {
				if (wine_version ~ legacy_gstreamer_wine_version_regexp) {
					sub("gstreamer", "gstreamer010")
				}
				else {
					sub((gstreamer_use_enabled_regexp bracketed_expression_regexp), "")
					if ($0 ~ blank_line_regexp)
						suppress_current_line=1
				}
			}
		}
		
		if (($0 ~ array_variables_regexp["IUSE"]) && (wine_version ~ legacy_gstreamer_wine_version_regexp))
			sub("gstreamer", "gstreamer010")

		if (($0 ~ array_variables_regexp["COMMON_DEPEND"]) || ($0 ~ array_variables_regexp["RDEPEND"]) || ($0 ~ array_variables_regexp["DEPEND"]))
			depend_assignment_open=1

		# Process gstreamer dependencies in *DEPEND="" variables
		if ((depend_assignment_open == 1) && ($0 ~ (gstreamer_use_enabled_regexp bracketed_expression_open_regexp)))
			gstreamer_expression_open=1
		if (gstreamer_expression_open == 1) {
			if (wine_version ~ legacy_gstreamer_wine_version_regexp)
				sub(gstreamer_use_enabled_regexp, "gstreamer010? ")
			else {
				sub(gstreamer_full_atom_match, "media-libs\/gstreamer:1.0")
				sub(gst_plugins_base_full_atom_match, "media-libs\/gst-plugins-base:1.0")
			}
			if ($0 ~ bracketed_expression_close_regexp)
				gstreamer_expression_open=0
		}

		if ($0 ~ test_gstreamer_or_staging_regexp)
			suppress_current_line=1
		if ($0 ~ array_variables_regexp["KEYWORDS"])
			suppress_current_line=1
		if (($0 ~ array_variables_regexp["GST_P"]) && (wine_version !~ legacy_gstreamer_wine_version_regexp))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["STAGING_P"])
			sub(package_version_variable_regexp, "${MY_PV}")

		if ((src_uri_open == 1) && ($0 ~ end_quote_regexp))
			src_uri_open=0
		if (wine_version ~ suppress_staging_wine_version_regexp) {
			if (($0 ~ array_variables_regexp["STAGING_P"]) || ($0 ~ array_variables_regexp["STAGING_DIR"]))
				suppress_current_line=1
			if ((if_check_pv9999_open == 1) && (if_check_pv9999_count == 2))
				suppress_current_line=1
			if ($0 ~ array_variables_regexp["IUSE"])
				gsub((quote_or_ws_seperator_regexp staging_use_flags_regexp quote_or_ws_seperator_regexp), " ")
				
			if ($0 ~ array_variables_regexp["REQUIRED_USE"])
				required_use_assignment_open=1
			if (((required_use_assignment_open == 1) || (depend_assignment_open == 1)) && ($0 ~ (quote_or_ws_seperator_regexp staging_use_flags_regexp "\\?"))) {
				gsub(staging_use_flags_regexp "\\?[[:blank:]]" bracketed_expression_regexp, "")
				if ($0 ~ blank_line_regexp)
					suppress_current_line=1
			}
			if ($0 ~ end_quote_regexp)
				required_use_assignment_open=0
		}
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp) == 1) {
		preamble_over=1
		if_stack=0
		target_block_open=0
	}


	# Ebuild phase based pre-checks
	if (($0 ~ if_regexp) && ($0 ~ "wine_build_environment_check\\(\\)"))
		printf("%s\n\n", "S=\"${WORKDIR}/${MY_P}\"")
	else if (array_phase_open["src_unpack"] == 1) {
		if ((if_check_pv9999_open > 0) && (else_check_pv9999_open == 0) && ($0 !~ check_for_pv9999_regexp))
			suppress_current_line=1
		if ((wine_version ~ suppress_staging_wine_version_regexp) && ($0 ~ (leading_ws_regexp staging_use_test_regexp)))
			suppress_current_line=1
		if ($0 ~ gstreamer_use_test_regexp) {
			if (wine_version ~ legacy_gstreamer_wine_version_regexp)
				sub("gstreamer", "gstreamer010")
			else
				suppress_current_line=1
		}
	}
	else if (array_phase_open["src_prepare"] == 1) {
		if (($0 ~ if_open_regexp) && ($0 ~ gstreamer_use_test_regexp)) {
			gstreamer_check_open=if_stack
			sub("gstreamer", "gstreamer010")
		}
		if ((gstreamer_check_open > 0) && (wine_version !~ legacy_gstreamer_wine_version_regexp))
			suppress_current_line=1
		if (($0 ~ if_open_regexp) && ($0 ~ staging_use_test_regexp))
			wine_staging_check_open=if_stack
		if ((wine_staging_check_open == 1) && ($0 ~ source_wine_staging_patcher_regexp))
			sub("$", " || die \"Failed to apply Wine-Staging patches.\"")
		if (wine_version ~ suppress_staging_wine_version_regexp) {
			if ($0 ~ add_gst_patch_regexp)
				sub(("^" leading_ws_regexp), indent)
			else
				suppress_current_line=wine_staging_check_open
			if ($0 ~ comment_regexp)
				suppress_current_line=1
		}
		if ($0 ~ if_close_regexp) {
			gstreamer_check_open=(gstreamer_check_open == if_stack+1) ? 0 : gstreamer_check_open
			wine_staging_check_open=(wine_staging_check_open == if_stack+1) ? 0 : wine_staging_check_open
		}
	}
	else if (array_phase_open["multilib_src_configure"] == 1) {
		if ((wine_version ~ legacy_gstreamer_wine_version_regexp) && ($0 ~ configure_use_with_regexp))
			sub("gstreamer", "gstreamer010 gstreamer")
		if ($0 ~ (leading_ws_regexp staging_use_test_regexp)) {
			wine_staging_check_open=1
			open_bracketed_expression=($0 ~ bracketed_expression_open_regexp "$") ? 1 : 0
		}
		if ((wine_version ~ suppress_staging_wine_version_regexp) && (wine_staging_check_open == 1))
			suppress_current_line=1
		if ((open_bracketed_expression == 1) && ($0 ~ leading_ws_regexp bracketed_expression_close_regexp))
			open_bracketed_expression=0
		wine_staging_check_open=(open_bracketed_expression == 0) ? 0 : wine_staging_check_open
	}
	
	
	# Print current line in ebuild
	if (suppress_current_line == 0) {
		# Eat more than 1 empty line
		blank_lines=($0 ~ blank_line_regexp) ? blank_lines+1 : 0
		if (blank_lines <= 1)
			print $0
	}

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=substr($0, RSTART, RLENGTH)

	if (preamble_over == 0) {
		if (if_check_pv9999_open == 1) {
			if ($0 ~ "inherit git-r3") {
				printf("%s%s\n", indent, "MY_PV=\"${PV}\"")
				printf("%s%s\n", indent, "MY_P=\"${P}\"")
			}
			
			if ($0 ~ "[[:blank:]]*MAJOR_V\=") {
				printf("%s%s\n", indent, "MINOR_V=$(get_version_component_range 2)")
				printf("%s%s\n", indent, "STABLE_RELEASE=$((1-MINOR_V%2))")
				printf("%s%s\n", indent, "MY_PV=\"${PV}\"")
				printf("%s%s\n", indent, "if [[ \"$(get_version_component_range 3)\" =~ ^rc ]]; then")
				printf("%s%s%s\n", indent, indent, "MY_PV=$(replace_version_separator 2 '\''-'\'')")
				printf("%s%s\n", indent, "elif [[ ${STABLE_RELEASE} == 1 ]]; then")
				printf("%s%s%s\n", indent, indent, "KEYWORDS=\"-* amd64 x86 x86-fbsd\"")
				printf("%s%s\n", indent, "else")
				printf("%s%s%s\n", indent, indent, "KEYWORDS=\"-* ~amd64 ~x86 ~x86-fbsd\"")
				printf("%s%s\n", indent, "fi")
				printf("%s%s\n", indent, "MY_P=\"${PN}-${MY_PV}\"")
			}
		}
		depend_assignment_open=((depend_assignment_open == 1) && ($0 ~ end_quote_regexp)) ? 0 : depend_assignment_open
	}
	
	# Ebuild phase based post-checks
	if ((wine_version !~ suppress_staging_wine_version_regexp) && (array_phase_open["pkg_pretend"] == 1) && ($0 ~ "wine_build_environment_check")) {
		printf("%s%s\n",	indent, "if [[ ${PV} == \"9999\" ]] && use staging; then")
		printf("%s%s%s\n",	indent, indent, "ewarn \"You have enabled a live ebuild of Wine with USE +staging.\"")
		printf("%s%s%s\n",	indent, indent, "ewarn \"All git branch and commit references will link to the Wine-Staging git tree.\"")
		printf("%s%s%s\n",	indent, indent, "ewarn \"By default the Wine-Staging git tree branch master will be used.\"")
		printf("%s%s\n",	indent, "fi")
		array_phase_open["pkg_pretend"]=2
	}
	if (array_phase_open["src_unpack"] == 1) {
		if ((if_check_pv9999_open > 0) && (do_git_unpack_replaced == 0)) {
			if (wine_version !~ suppress_staging_wine_version_regexp)
				printf("%s%s%s\n",	 indent, indent, "# Reference either Wine or Wine Staging git branch (depending on +staging use flag)")
			printf("%s%s%s\n",	 indent, indent, "EGIT_BRANCH=${EGIT_BRANCH:-master}")
			if (wine_version !~ suppress_staging_wine_version_regexp) {
				printf("%s%s%s\n",	 indent, indent, "if use staging; then")
				printf("%s%s%s%s\n", indent, indent, indent, "EGIT_REPO_URI=${STAGING_EGIT_REPO_URI} EGIT_CHECKOUT_DIR=${STAGING_DIR} git-r3_src_unpack")
				printf("%s%s%s%s\n", indent, indent, indent, "local WINE_COMMIT=$(\"${STAGING_DIR}/patches/patchinstall.sh\" --upstream-commit)")
				printf("%s%s%s%s\n", indent, indent, indent, "[[ ! ${WINE_COMMIT} =~ [[:xdigit:]]{40} ]] && die \"Failed to get Wine git commit corresponding to Wine-Staging git commit ${EGIT_VERSION}.\"")
				printf("%s%s%s%s\n", indent, indent, indent, "einfo \"Building Wine commit ${WINE_COMMIT} referenced by Wine-Staging commit ${EGIT_VERSION} ...\"")
				printf("%s%s%s%s\n", indent, indent, indent, "EGIT_COMMIT=\"${WINE_COMMIT}\"")
				printf("%s%s%s\n",	 indent, indent, "fi")
			}
			printf("%s%s%s\n",	 indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
			if (wine_version !~ legacy_gstreamer_wine_version_regexp) {
				printf("%s%s%s\n",	 indent, indent, "if use gstreamer && grep -q \"gstreamer-0.10\" \"${S}\"/configure ; then")
				printf("%s%s%s%s\n", indent, indent, indent, "ewarn \"Wine commit ${GSTREAMER_COMMIT} first introduced support for the gstreamer:1.0 API / ABI.\"")
				printf("%s%s%s%s\n", indent, indent, indent, "ewarn \"Specify a newer Wine commit or emerge with USE -gstreamer.\"")
				printf("%s%s%s%s\n", indent, indent, indent, "die \"This live ebuild does not support Wine builds using the older gstreamer:0.1 API / ABI.\"")
				printf("%s%s%s\n",	 indent, indent, "fi")
			}
			++do_git_unpack_replaced
		}
	}
	if ((array_phase_open["src_prepare"] == 1) && (wine_version ~ gcc_stack_alignment_forced_version_regexp)) {
		if ((patch_set_open == 0) && $0 ~ (leading_ws_regexp patchset_regexp))
			++patch_set_open
		if ((patch_set_open == 1) && ($0 ~ (bracketed_expression_close_regexp "$"))) {
			# Hack - disable forced alignment for all gcc >=5.3.x versions - needs a gcc test function for Upstream (in-tree) patch
			printf("%s%s\n",	indent, "if [[ $(gcc-major-version) = 5 && $(gcc-minor-version) -ge 3 ]]; then")
			printf("%s%s%s\n",	indent, indent, "local PATCHES+=( \"${FILESDIR}\"/${PN}-1.9.3-gcc-5_3_0-disable-force-alignment.patch ) #574044")
			printf("%s%s\n",	indent, "fi")
			++patch_set_open
		}
	}
	if ((array_phase_open["src_configure"] == 1) && (wine_version ~ "^9999$") && ($0 ~ (leading_ws_regexp use_custom_cflags_regexp))) {
		# Hack - disable forced alignment for all gcc >=5.3.x versions - needs a gcc test function for Upstream (in-tree) patch
		printf("%s%s\n",	indent, "if [[ ${PV} == \"9999\" ]] && [[ $(gcc-major-version) = 5 && $(gcc-minor-version) -ge 3 ]]; then")
		printf("%s%s%s\n",	indent, indent, "local CFLAGS=\"${CFLAGS} -fno-omit-frame-pointer\" # bug 574044")
		printf("%s%s\n",	indent, "fi")
		array_ebuild_phases["src_configure"]=2
	}

	if ((if_check_pv9999_open > 0) && (if_check_pv9999_open == if_stack+1) && ($0 ~ if_close_regexp))
			if_check_pv9999_open=else_check_pv9999_open=0

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
