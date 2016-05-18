# !/bin/awk

BEGIN{
	setup_ebuild_phases("wine_build_environment_check pkg_pretend pkg_setup src_unpack src_prepare src_configure multilib_src_configure multilib_src_test multilib_src_install_all pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)

	# Setup some regular expression constants - to hopefully make the script more readable!
	ebuild_inherit_regexp="^inherit "
	variables="COMMON_DEPEND RDEPEND DEPEND IUSE GST_P GV KEYWORDS MV STAGING_P STAGING_DIR STAGING_EGIT_REPO_URI REQUIRED_USE SRC_URI"
	setup_global_regexps(variables)
	emake_target_regexp="emake install DESTDIR=\"\\$\\{D\\}\""
	eselect_check_regexp="^[[:blank:]]+[\\>\\=\\>]+app\\-eselect\\\/eselect\\-opengl"
	source_wine_staging_patcher_regexp="^[[:blank:]]*source[[:blank:]]+\".*patchinstall\\.sh.*\"$"
	check_for_pv9999_regexp="\\[\\[ \\$\\{PV\\} == \"9999\" \\]\\]"
	test_gstreamer_or_staging_regexp="\\?\\?[[:blank:]]+\\([[:blank:]]+gstreamer[[:blank:]]+staging[[:blank:]]+\\)"
	gstreamer_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gstreamer:[\.[:digit:]]+"
	gst_plugins_base_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gst-plugins-base:[\.[:digit:]]+"
	patchset_regexp="local[[:blank:]]+PATCHES=\\("
	mono_use_enabled_regexp="mono\\?[[:blank:]]+"
	staging_use_enabled_regexp="staging\\?[[:blank:]]+"
	staging_use_test_regexp="use[[:blank:]]+staging"
	gstreamer_use_enabled_regexp="gstreamer\\?[[:blank:]]+"
	gstreamer_use_test_regexp="use[[:blank:]]+gstreamer"
	pipelight_use_test_regexp="use[[:blank:]]+pipelight"
	abi_x86_64_use_test_regexp="use[[:blank:]]+abi\\_x86\\_64"
	abi_eq_amd64_regexp="\\$\\{ABI\\}[[:blank:]]+==[[:blank:]]+amd64"
	unpack_regexp=(leading_ws_regexp "unpack[[:blank:]]+")
	configure_use_with_regexp="\\$\\(use_with[[:blank:]].+\\)"
	package_regexp="\\$\\{P\\}"
	package_version_variable_regexp="\\$\\{PV\\}"
	staging_use_flags_regexp="[\+]{0,1}(pipelight|s3tc|staging|vaapi)"
	add_gst_patch_regexp="PATCHES\\+\\=\\( \"\\$\\{WORKDIR\\}\\/\\$\\{GST\\_\\P}\\.patch\" \\)"
	gstreamer_patch_bzip_regexp="\\$\\{GST_P\\}\\.patch\\.bz2"
	gstreamer_patch_regexp="\\$\\{WORKDIR\\}\\/\\$\\{GST\\_\\P\\}\\.patch"
	gstreamer_1_0_patch="wine-1.8-gstreamer-1.0"
	gstreamer_patch_uri_regexp="https\\:\\/\\/\\dev\\.gentoo\\.org\\/\\~np\\-hardass\\/distfiles\\/\\$\\{PN\\}\\/\\$\\{GST\\_P\\}\\.patch\\.bz2$"
	new_multilib_patch_version="\"${FILESDIR}\"/${PN}-1.9.5"
    multilib_patch_regexp="multilib\\-portage\\.patch"
	sysmacros_patch_regexp="sysmacros\\.patch"
	autotools_utils_src_prepare_regexp=(leading_ws_regexp "autotools\\-utils\\_src\\_prepare")
	wine_mono_version_regexp="[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+"
	wine_gecko_version_regexp="[[:digit:]]+\\.[[:digit:]]+"
	gentoo_excluded_bugs_regexp="bug[[:blank:]]+\\#(549768|574044)"
	gcc5_tests_regexp="[[:blank:]]+\\$\\(gcc\\-major\\-version\\)[[:blank:]]+=[[:blank:]]+5[[:blank:]]+"
	local_staging_exclude_define_regexp="local[[:blank:]]+STAGING_EXCLUDE=\"\""

	legacy_gstreamer_patch_1_0_version_regexp=convert_version_list_to_regexp(legacy_gstreamer_patch_1_0_versions)
	suppress_staging_wine_version_regexp=convert_version_list_to_regexp(wine_staging_unsupported_versions)
	wine_staging_no_csmt_version_regexp=convert_version_list_to_regexp(wine_staging_no_csmt_versions)
    updated_multilib_patch_version_regexp=convert_version_list_to_regexp(updated_multilib_patch_wine_versions)
	no_sysmacros_patch_wine_version_regexp=convert_version_list_to_regexp(no_sysmacros_patch_wine_versions)
	wine_gecko_version2_44_regexp=convert_version_list_to_regexp(wine_gecko_version2_44_wine_versions)
	wine_mono_version4_6_0_regexp=convert_version_list_to_regexp(wine_mono_version4_6_0_wine_versions)
	wine_mono_version4_6_2_regexp=convert_version_list_to_regexp(wine_mono_version4_6_2_wine_versions)
	wine_staging_helper="wine-staging-git-helper-0.1.2"
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
		if ((if_check_pv9999_open == 1) && ($0 ~ "EGIT_BRANCH=\"master\""))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["SRC_URI"])
			src_uri_open=1

		if (src_uri_open == 1) {
			if ($0 ~ "\"https\:.+\"")
				sub("\\$\\{P\\}.tar.bz2\"$", "${MY_P}.tar.bz2 -> ${P}.tar.bz2\"")

			if ($0 ~ staging_use_enabled_regexp)
				sub(package_version_variable_regexp, "${MY_PV}${STAGING_SUFFIX}")

			if (gstreamer_patch_uri_found == 0) {
				if (wine_version ~ legacy_gstreamer_patch_1_0_version_regexp) {
					gstreamer_patch_uri_found+=sub(gstreamer_patch_uri_regexp, "gstreamer? ( & )")
				}
				else {
					gstreamer_patch_uri_found+=sub(gstreamer_patch_uri_regexp, "")
					if ($0 ~ blank_line_regexp)
						suppress_current_line=1
				}
			}
		}

		if ((wine_version ~ wine_gecko_version2_44_regexp) && ($0 ~ array_variables_regexp["GV"]))
			sub(wine_gecko_version_regexp, "2.44")
		if ((wine_version ~ wine_mono_version4_6_0_regexp) && ($0 ~ array_variables_regexp["MV"]))
			sub(wine_mono_version_regexp, "4.6.0")
		if ((wine_version ~ wine_mono_version4_6_2_regexp) && ($0 ~ array_variables_regexp["MV"]))
			sub(wine_mono_version_regexp, "4.6.2")

		if (($0 ~ array_variables_regexp["COMMON_DEPEND"]) || ($0 ~ array_variables_regexp["RDEPEND"]) || ($0 ~ array_variables_regexp["DEPEND"]))
			depend_assignment_open=1

		if ($0 ~ test_gstreamer_or_staging_regexp)
			suppress_current_line=1
		if ($0 ~ array_variables_regexp["KEYWORDS"])
			suppress_current_line=1
		if (($0 ~ array_variables_regexp["GST_P"]) && (wine_version !~ legacy_gstreamer_patch_1_0_version_regexp))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["STAGING_P"])
			sub(package_version_variable_regexp, "${MY_PV}")
		if ($0 ~ array_variables_regexp["STAGING_DIR"])
			sub("\".+\"$", "\"${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}\"")
		if ((src_uri_open == 1) && ($0 ~ end_quote_regexp))
			src_uri_open=0

		if ($0 ~ array_variables_regexp["REQUIRED_USE"])
			required_use_assignment_open=1
		if (wine_version ~ suppress_staging_wine_version_regexp) {
			if (($0 ~ array_variables_regexp["STAGING_P"]) || ($0 ~ array_variables_regexp["STAGING_DIR"]))
				suppress_current_line=1
			if ((if_check_pv9999_open == 1) && (if_check_pv9999_count == 2))
				suppress_current_line=1
			if ($0 ~ array_variables_regexp["IUSE"])
				gsub((quote_or_ws_seperator_regexp staging_use_flags_regexp quote_or_ws_seperator_regexp), " ")

			if ((required_use_assignment_open == 1) || (depend_assignment_open == 1)) {
				if (($0 ~ (quote_or_ws_seperator_regexp staging_use_flags_regexp "\\?")) && (gsub((staging_use_flags_regexp "\\?[[:blank:]]" bracketed_expression_regexp), "") > 0) && ($0 ~ blank_line_regexp))
					suppress_current_line=1
			}
		}
		else if ((else_check_pv9999_open == 1) && (if_check_pv9999_count == 2) && (staging_git_helper == 0)) {
			printf("%s%s\n", indent, "SRC_URI=\"${SRC_URI}")
			printf("%s%s\n", indent, "staging? ( https://github.com/bobwya/${STAGING_HELPER%-*}/archive/${STAGING_HELPER##*-}.tar.gz -> ${STAGING_HELPER}.tar.gz )\"")
			++staging_git_helper
		}

		if ((required_use_assignment_open == 1) && ((wine_version ~ wine_mono_version4_6_0_regexp) || (wine_version ~ wine_mono_version4_6_2_regexp))) {
			if (sub((mono_use_enabled_regexp bracketed_expression_regexp), "") && ($0 ~ blank_line_regexp))
				suppress_current_line=1
		}
		if ((required_use_assignment_open == 1) && ($0 ~ end_quote_regexp))
			required_use_assignment_open=0
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp) == 1) {
		preamble_over=1
		if_stack=0
		target_block_open=0
	}


	# Ebuild phase based pre-checks
	if (array_phase_open["wine_build_environment_check"] == 1) {
		sub("wine_build_environment_check", "wine_build_environment_prechecks")
		if (change_source_path != 1) {
			printf("%s\n\n", "S=\"${WORKDIR}/${MY_P}\"")
			change_source_path=1
		}
		if (($0 ~ comment_regexp) && ($0 ~ gentoo_excluded_bugs_regexp))
			suppress_current_line=1
		if (($0 ~ if_open_regexp) && (if_stack == 1) && ($0 ~ abi_x86_64_use_test_regexp) && ($0 ~ gcc5_tests_regexp))
			suppress_bug_check_open=1
		suppress_current_line=(suppress_bug_check_open == 1) ? 1 : suppress_current_line
		if (($0 ~ if_close_regexp) && (if_stack == 0) && (suppress_bug_check_open == 1))
			suppress_bug_check_open=0
	}
	else if (array_phase_open["pkg_pretend"] == 1) {
		if (wine_build_environment_pretests == 0) {
			wine_build_environment_pretests=1

			printf("%s\n",		"wine_build_environment_pretests() {")
			printf("%s%s\n\n",	indent, "[[ \"${MERGE_TYPE}\" == \"binary\" ]] && return 0")
			printf("%s%s\n",	indent, "# bug #549768")
			printf("%s%s\n",	indent, "if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -le 2 ]]; then")
			printf("%s%s%s\n",	indent, indent, "einfo \"Checking for gcc-5.1/gcc-5.2 MS X86_64 ABI compiler bug ...\"")
			printf("%s%s%s\n",	indent, indent, "$(tc-getCC) -O2 \"${FILESDIR}/pr66838.c\" -o \"${T}/pr66838\" || die \"cc compilation failed: pr66838 test\"")
			printf("%s%s%s\n",	indent, indent, "# Run in subshell to prevent \"Aborted\" message")
			printf("%s%s%s\n",	indent, indent, "if ! ( \"${T}/pr66838\" || false )&>/dev/null; then")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"gcc-5.1/5.2 MS X86_64 ABI compiler bug detected.\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"64-bit wine cannot be built with affected versions of gcc.\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Please re-emerge wine using an unaffected version of gcc or apply\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Upstream (backport) patch to your current version of gcc-5.1/5.2.\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"See https://bugs.gentoo.org/549768\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror")
			printf("%s%s%s%s\n",indent, indent, indent, "return 1")
			printf("%s%s%s\n",	indent, indent, "fi")
			printf("%s%s\n\n",	indent, "fi")
			printf("%s%s\n",	indent, "# bug #574044")
			printf("%s%s\n",	indent, "if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -eq 3 ]]; then")
			printf("%s%s%s\n",	indent, indent, "einfo \"Checking for gcc-5.3.0 X86_64 misaligned stack compiler bug ...\"")
			printf("%s%s%s\n",	indent, indent, "# Compile in subshell to prevent \"Aborted\" message")
			printf("%s%s%s\n",	indent, indent, "if ! ( $(tc-getCC) -O2 -mincoming-stack-boundary=3 \"${FILESDIR}\"/pr69140.c -o \"${T}\"/pr69140 || false )&>/dev/null; then")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"gcc-5.3.0 X86_64 misaligned stack compiler bug detected.\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Please re-emerge the latest gcc-5.3.0 ebuild, or use gcc-config to select a different compiler version.\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror \"See https://bugs.gentoo.org/574044\"")
			printf("%s%s%s%s\n",indent, indent, indent, "eerror")
			printf("%s%s%s%s\n",indent, indent, indent, "return 1")
			printf("%s%s%s\n",	indent, indent, "fi")
			printf("%s%s\n",	indent, "fi")

			printf("}\n\n")
		}

		if ($0 ~ (leading_ws_regexp wine_build_environment_check)) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
	}
	else if (array_phase_open["pkg_setup"] == 1) {
		if ($0 ~ (leading_ws_regexp wine_build_environment_check)) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
	}
	else if (array_phase_open["src_unpack"] == 1) {
		if ((if_check_pv9999_open > 0) && (else_check_pv9999_open == 0))
			suppress_current_line=1
		if ((if_check_pv9999_open > 0) && (do_git_unpack_replaced == 0)) {
			if (wine_version ~ suppress_staging_wine_version_regexp) {
				printf("%s%s\n", 	indent, "if [[ ${PV} == \"9999\" ]]; then")
				printf("%s%s%s\n",	indent, indent, "# Fully Mirror git tree, Wine, so we can access commits in all branches")
				printf("%s%s%s\n",	indent, indent, "EGIT_MIN_CLONE_TYPE=\"mirror\"")
				printf("%s%s%s\n",	indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
			}
			else {
				printf("%s%s\n",	indent, "# Fully Mirror both git trees, Wine & Wine-Staging, so we can access commits in all branches")
				printf("%s%s\n",	indent, "[[ ${PV} == \"9999\" ]] && EGIT_MIN_CLONE_TYPE=\"mirror\"")
				printf("%s%s\n",	indent, "if [[ ${PV} == \"9999\" ]] && ! use staging; then")
				printf("%s%s%s\n",	indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
				printf("%s%s\n",	indent, "elif [[ ${PV} == \"9999\" ]] && use staging; then")
				printf("%s%s%s\n",	indent, indent, "unpack \"${STAGING_HELPER}.tar.gz\"")
				printf("%s%s%s\n", indent, indent, "if [[ ! -z \"${EGIT_STAGING_COMMIT}\" || ! -z \"${EGIT_STAGING_BRANCH}\" ]]; then")
				printf("%s%s%s%s\n", indent, indent, indent, "# References are relative to Wine-Staging git tree (pre-checkout Wine-Staging git tree)")
				printf("%s%s%s%s\n", indent, indent, indent, "# Use env variables \"EGIT_STAGING_COMMIT\" or \"EGIT_STAGING_BRANCH\" to reference Wine-Staging git tree")
				printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"Building Wine git with USE +staging. You have specified a Wine-Staging git reference...\"")
				printf("%s%s%s%s\n", indent, indent, indent, "(")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "source \"${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh\" || die")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "[[ ! -z \"${EGIT_STAGING_COMMIT}\" ]] && WINE_STAGING_REF=\"commit EGIT_STAGING_COMMIT\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "[[   -z \"${EGIT_STAGING_COMMIT}\" ]] && WINE_STAGING_REF=\"branch EGIT_STAGING_BRANCH\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "ewarn \"Building Wine against Wine-Staging git ${WINE_STAGING_REF}=\\\"${EGIT_STAGING_COMMIT:-${EGIT_STAGING_BRANCH}}\\\" .\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_BRANCH=\"${EGIT_STAGING_BRANCH:-master}\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_COMMIT=\"${EGIT_STAGING_COMMIT:-}\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "unset ${PN}_LIVE_{REPO,BRANCH,COMMIT};")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_REPO_URI=\"${STAGING_EGIT_REPO_URI}\" EGIT_CHECKOUT_DIR=\"${STAGING_DIR}\" git-r3_src_unpack")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "WINE_STAGING_COMMIT=\"${EGIT_VERSION}\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "get_upstream_wine_commit  \"${STAGING_DIR}\" \"${WINE_STAGING_COMMIT}\" \"WINE_COMMIT\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_COMMIT=\"${WINE_COMMIT}\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "einfo \"Building Wine commit \\\"${WINE_COMMIT}\\\" referenced by Wine-Staging commit \\\"${WINE_STAGING_COMMIT}\\\" ...\"")
				printf("%s%s%s%s\n", indent, indent, indent, ")")
				printf("%s%s%s%s\n", indent, indent, indent, "eend $?")
				printf("%s%s%s\n",	 indent, indent, "else")
				printf("%s%s%s%s\n", indent, indent, indent, "# References are relative to Wine git tree (post-checkout Wine-Staging git tree)")
				printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"Building Wine git with USE +staging. You are using a Wine git reference...\"")
				printf("%s%s%s%s\n", indent, indent, indent, "(")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "source \"${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh\" || die")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "WINE_COMMIT=\"${EGIT_VERSION}\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "unset ${PN}_LIVE_{REPO,BRANCH,COMMIT} EGIT_COMMIT;")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_REPO_URI=\"${STAGING_EGIT_REPO_URI}\" EGIT_CHECKOUT_DIR=\"${STAGING_DIR}\" git-r3_src_unpack")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "if ! walk_wine_staging_git_tree \"${STAGING_DIR}\" \"${S}\" \"${WINE_COMMIT}\" \"WINE_STAGING_COMMIT\" ; then")
				printf("%s%s%s%s%s%s\n", indent, indent, indent, indent, indent, "find_closest_wine_commit \"${STAGING_DIR}\" \"${S}\" \"WINE_COMMIT\" \"WINE_STAGING_COMMIT\" \"WINE_COMMIT_OFFSET\"")
				printf("%s%s%s%s%s%s\n", indent, indent, indent, indent, indent, "(($? == 0)) && display_closest_wine_commit_message \"${WINE_COMMIT}\" \"${WINE_STAGING_COMMIT}\" \"${WINE_COMMIT_OFFSET}\"")
				printf("%s%s%s%s%s%s\n", indent, indent, indent, indent, indent, "die \"Failed to find Wine-Staging git commit corresponding to supplied Wine git commit \\\"${WINE_COMMIT}\\\" .\"")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "fi")
				printf("%s%s%s%s%s\n", indent, indent, indent, indent, "einfo \"Building Wine-Staging commit \\\"${WINE_STAGING_COMMIT}\\\" corresponding to Wine commit \\\"${WINE_COMMIT}\\\" ...\"")
				printf("%s%s%s%s\n", indent, indent, indent, ")")
				printf("%s%s%s%s\n", indent, indent, indent, "eend $?")
				printf("%s%s%s\n",	 indent, indent, "fi")
			}
			++do_git_unpack_replaced
		}
		if ((if_check_pv9999_open > 0) && (else_check_pv9999_open == 1) && ($0 ~ (leading_ws_regexp staging_use_test_regexp))) {
			if (wine_version ~ legacy_gstreamer_patch_1_0_version_regexp)
				printf("%s%s%s\n",	indent, indent, "use gstreamer && unpack \"${GST_P}.patch.bz2\"")
			if (wine_version ~ suppress_staging_wine_version_regexp)
				suppress_current_line=1
		}
		if (($0 ~ gstreamer_use_test_regexp) || ($0 ~ (unpack_regexp "\"" gstreamer_patch_bzip_regexp "\"")))
			suppress_current_line=1
	}
	else if (array_phase_open["src_prepare"] == 1) {
		patch_set_define_open=($0 ~ (leading_ws_regexp patchset_regexp)) ? 1 : patch_set_define_open
		if (patch_set_define_open == 1) {
			if (($0 ~ multilib_patch_regexp) || ($0 ~ gstreamer_patch_regexp))
				suppress_current_line=1
			if ((wine_version ~ no_sysmacros_patch_wine_version_regexp) && ($0 ~ sysmacros_patch_regexp))
				suppress_current_line=1
		}
		if (($0 ~ if_open_regexp) && ($0 ~ staging_use_test_regexp))
			wine_staging_check_open=if_stack
		if ((wine_staging_check_open == 1) && ($0 ~ source_wine_staging_patcher_regexp))
			sub("$", " || die \"Failed to apply Wine-Staging patches.\"")
		if ((wine_version !~ suppress_staging_wine_version_regexp) && (wine_staging_check_open == 1) && ($0 ~ if_close_regexp)) {
			printf("\n%s%s%s\n", indent, indent, "if [[ ! -z \"${STAGING_SUFFIX}\" ]]; then")
			printf("%s%s%s%s\n", indent, indent, indent, "sed -i -e 's/(Staging)/(Staging'\"${STAGING_SUFFIX}\"')/' libs/wine/Makefile.in || die \"sed\"")
			printf("%s%s%s\n", indent, indent, "fi")
		}
		if (wine_version ~ suppress_staging_wine_version_regexp) {
			if ($0 ~ add_gst_patch_regexp)
				sub(("^" leading_ws_regexp), (indent indent))
			else
				suppress_current_line+=wine_staging_check_open
			if ($0 ~ "^" comment_regexp)
				suppress_current_line=1
		}
		if ($0 ~ if_close_regexp)
			wine_staging_check_open=(wine_staging_check_open == if_stack+1) ? 0 : wine_staging_check_open
	}
	else if (array_phase_open["multilib_src_configure"] == 1) {
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
	else if (array_phase_open["pkg_postinst"] == 1) {
		sub("like via winetricks\"$", "via winetricks.\"")
		if (($0 ~ if_open_regexp) && ($0 ~ gstreamer_use_test_regexp))
			gstreamer_check_open=if_stack
		if (gstreamer_check_open > 0)
			suppress_current_line=1
		if ($0 ~ if_close_regexp)
			gstreamer_check_open=(gstreamer_check_open == if_stack+1) ? 0 : gstreamer_check_open

		if ($0 ~ blank_line_regexp) {
			++blank_line_count
			suppress_current_line+=(blank_line_count >= 2) ? 1 : 0
		}
		if ($0 ~ end_curly_bracket_regexp) {
			if ((wine_version !~ suppress_staging_wine_version_regexp) && (wine_version ~ wine_staging_no_csmt_version_regexp)) {
				printf("%s%s\n",	indent, "if use staging; then")
				printf("%s%s%s\n",	indent, indent, "ewarn \"This version of Wine-Staging does not support the CMST patchset.\"")
				printf("%s%s\n",	indent, "fi")
			}
			if (wine_version ~ legacy_gstreamer_patch_1_0_version_regexp) {
				printf("%s%s\n", 	indent, "if [[ ! -z \"${GST_P}\" ]] && use gstreamer; then")
				printf("%s%s%s\n",	indent, indent, "ewarn \"This package uses a Gentoo specific patchset to provide \"")
				printf("%s%s%s\n",	indent, indent, "ewarn \"gstreamer:1.0 API / ABI support.  Any bugs related to GStreamer\"")
				printf("%s%s%s\n",	indent, indent, "ewarn \"should be filed at Gentoo's bugzilla, not upstream's.\"")
				printf("%s%s\n",	indent, "fi")
			}
		}
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
		indent=(indent == 0) ? substr($0, RSTART, RLENGTH) : indent

	if (preamble_over == 0) {
		if (if_check_pv9999_open == 1) {
			if ($0 ~ "inherit git-r3") {
				printf("%s%s\n", indent, "MY_PV=\"${PV}\"")
				if (wine_version !~ suppress_staging_wine_version_regexp)
					printf("%s%s\n", indent, "STAGING_PV=\"${MY_PV}\"")
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
				if (wine_version !~ suppress_staging_wine_version_regexp)
					printf("%s%s\n", indent, "[[ \"${MY_PV}\" =~ ^1\\.8\\.[[:digit:]]+$ ]] && STAGING_SUFFIX=\"-unofficial\"")
				printf("%s%s\n", indent, "MY_P=\"${PN}-${MY_PV}\"")
			}
		}
		if (($0 ~ array_variables_regexp["STAGING_DIR"]) && (wine_version !~ suppress_staging_wine_version_regexp))
			printf("%s\n", ("STAGING_HELPER=\"" wine_staging_helper "\""))
		depend_assignment_open=((depend_assignment_open == 1) && ($0 ~ end_quote_regexp)) ? 0 : depend_assignment_open
	}

	# Ebuild phase based post-checks
	if (((array_phase_open["pkg_pretend"] == 1) || (array_phase_open["pkg_setup"] == 1)) && (wine_build_environment_prechecks == 1)) {
		printf("%s%s\n", indent, "wine_build_environment_prechecks || die")
		printf("%s%s\n", indent, "wine_build_environment_pretests || die")
		wine_build_environment_prechecks=0
	}
	else if (array_phase_open["src_prepare"] == 1) {
		if ((patch_set_define_open == 1) && ($0 ~ (bracketed_expression_close_regexp "$"))) {
			printf("%s%s\n",		indent, "if [[ ${PV} != \"9999\" ]]; then")
			if (wine_version ~ legacy_gstreamer_patch_1_0_version_regexp) {
				printf("%s%s%s\n",	indent, indent, "if use gstreamer; then")
				printf("%s%s%s%s\n",indent, indent, indent, "# version 1.9.1 already implements partial gstreamer:1.0 support")
				printf("%s%s%s%s\n",indent, indent, indent, "[[ \"${PV}\" == \"1.9.1\" ]] && { sed -i -e '1,71d' \"${WORKDIR}/${GST_P}.patch\" || die \"sed\"; }")
				printf("%s%s%s%s\n",indent, indent, indent, "PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
				printf("%s%s%s\n",	indent, indent, "fi")
			}
			if (wine_version ~ updated_multilib_patch_version_regexp)
				printf("%s%s%s\n",	indent, indent, "PATCHES+=( \"${FILESDIR}\"/${PN}-1.9.5-multilib-portage.patch ) #395615")
			else
				printf("%s%s%s\n",	indent, indent, "PATCHES+=( \"${FILESDIR}\"/${PN}-1.4_rc2-multilib-portage.patch ) #395615")
			printf("%s%s\n",		indent, "else")
			if (wine_version ~ legacy_gstreamer_patch_1_0_version_regexp) {
				printf("%s%s%s\n",	indent, indent, "# only apply gstreamer:1.0 patch to older versions of wine, using gstreamer:0.1 API/ABI")
				printf("%s%s%s\n",	indent, indent, "grep -q \"gstreamer-0.10\" \"${S}/configure\" &>/dev/null || unset GST_P")
				printf("%s%s%s\n",	indent, indent, "[[ ! -z \"${GST_P}\" ]] && use gstreamer && PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
			}
			printf("%s%s%s\n",		indent, indent, "#395615 - run bash/sed script, combining both versions of the multilib-portage.patch")
			printf("%s%s%s\n",		indent, indent, "ebegin \"sh running script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\" ...\"")
			printf("%s%s%s\n",		indent, indent, "(")
			printf("%s%s%s%s\n",	indent, indent, indent, "source \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" ||")
			printf("%s%s%s%s%s\n",	indent, indent, indent, indent, "die \"sh failed script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\" .\"")
			printf("%s%s%s\n",		indent, indent, ")")
			printf("%s%s%s\n",		indent, indent, "eend $?")

			printf("%s%s\n",		indent, "fi")
			++patch_set_define_open
		}
		if (wine_version !~ suppress_staging_wine_version_regexp) {
			if ((wine_version == "1.9.5-r1") && ($0 ~ (leading_ws_regexp pipelight_use_test_regexp)))  {
				printf("%s%s%s\n",		indent, indent, ("#577198 only affects " wine_version))
				printf("%s%s%s\n",		indent, indent, "use nls || STAGING_EXCLUDE=\"${STAGING_EXCLUDE} -W makefiles-Disabled_Rules\"")
			}
			if ($0 ~ (leading_ws_regexp local_staging_exclude_define_regexp)) {
				printf("%s%s%s\n",		indent, indent, "if grep -q \"0001-mshtml-Wine-Gecko-2.47-beta1-release.patch\" \"${STAGING_DIR}/patches/patchinstall.sh\"; then")
				printf("%s%s%s%s\n",	indent, indent, indent, "STAGING_EXCLUDE=\"${STAGING_EXCLUDE} -W mshtml_Wine_Gecko_2_47\"")
				printf("%s%s%s\n",		indent, indent, "fi")
			}
		}
	}


	if ((if_check_pv9999_open > 0) && (if_check_pv9999_open == if_stack+1) && ($0 ~ if_close_regexp))
			if_check_pv9999_open=else_check_pv9999_open=0

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
