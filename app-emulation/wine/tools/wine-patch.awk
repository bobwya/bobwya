#!/bin/awk

function print_wine_build_environment_pretests(indent)
{
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

function print_src_prepare_live_build_patch_support(indent, is_legacy_gstreamer_patch, is_updated_multilib_patch)
{
	printf("%s%s\n",		indent, "if [[ ${PV} != \"9999\" ]]; then")
	if (is_legacy_gstreamer_patch) {
		printf("%s%s%s\n",	indent, indent, "if use gstreamer; then")
		printf("%s%s%s%s\n",indent, indent, indent, "# version 1.9.1 already implements partial gstreamer:1.0 support")
		printf("%s%s%s%s\n",indent, indent, indent, "[[ \"${PV}\" == \"1.9.1\" ]] && { sed -i -e '1,71d' \"${WORKDIR}/${GST_P}.patch\" || die \"sed\"; }")
		printf("%s%s%s%s\n",indent, indent, indent, "PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
		printf("%s%s%s\n",	indent, indent, "fi")
	}
	if (is_updated_multilib_patch)
		printf("%s%s%s\n",	indent, indent, "PATCHES+=( \"${FILESDIR}\"/${PN}-1.9.5-multilib-portage.patch ) #395615")
	else
		printf("%s%s%s\n",	indent, indent, "PATCHES+=( \"${FILESDIR}\"/${PN}-1.4_rc2-multilib-portage.patch ) #395615")
	printf("%s%s\n",		indent, "else")
	if (is_legacy_gstreamer_patch) {
		printf("%s%s%s\n",	indent, indent, "# only apply gstreamer:1.0 patch to older versions of wine, using gstreamer:0.1 API/ABI")
		printf("%s%s%s\n",	indent, indent, "grep -q \"gstreamer-0.10\" \"${S}/configure\" &>/dev/null || unset GST_P")
		printf("%s%s%s\n",	indent, indent, "[[ ! -z \"${GST_P}\" ]] && use gstreamer && PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
	}
	printf("%s%s%s\n",		indent, indent, "#395615 - run bash/sed script, combining both versions of the multilib-portage.patch")
	printf("%s%s%s\n",		indent, indent, "ebegin \"(subshell) script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\" ...\"")
	printf("%s%s%s\n",		indent, indent, "(")
	printf("%s%s%s%s\n",	indent, indent, indent, "source \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" || die")
	printf("%s%s%s\n",		indent, indent, ")")
	printf("%s%s%s\n",		indent, indent, "eend $? || die \"(subshell) script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\".\"")

	printf("%s%s\n",		indent, "fi")
}

function print_src_unpack_live_ebuild_support(indent, is_staging_supported)
{
	if (!is_staging_supported) {
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
		printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"(subshell): you have specified a Wine-Staging git reference (building Wine git with USE +staging) ...\"")
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
		printf("%s%s%s%s\n", indent, indent, indent, "eend $? || die \"(subshell): ... failed to determine target Wine commit.\"")
		printf("%s%s%s\n",	 indent, indent, "else")
		printf("%s%s%s%s\n", indent, indent, indent, "# References are relative to Wine git tree (post-checkout Wine-Staging git tree)")
		printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"(subshell): You are using a Wine git reference (building Wine git with USE +staging) ...\"")
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
		printf("%s%s%s%s\n", indent, indent, indent, "eend $? || die \"(subshell): ... failed to determine target Wine-Staging commit.\"")
		printf("%s%s%s\n",	 indent, indent, "fi")
	}
}

function print_pkg_postinst_csmt_warning(indent)
{
	printf("%s%s\n",	indent, "if use staging; then")
	printf("%s%s%s\n",	indent, indent, "ewarn \"This version of Wine-Staging does not support the CMST patchset.\"")
	printf("%s%s\n",	indent, "fi")
}

function print_pkg_postinst_gstreamer_patch_warning(indent)
{
	printf("%s%s\n", 	indent, "if [[ ! -z \"${GST_P}\" ]] && use gstreamer; then")
	printf("%s%s%s\n",	indent, indent, "ewarn \"This package uses a Gentoo specific patchset to provide \"")
	printf("%s%s%s\n",	indent, indent, "ewarn \"gstreamer:1.0 API / ABI support.  Any bugs related to GStreamer\"")
	printf("%s%s%s\n",	indent, indent, "ewarn \"should be filed at Gentoo's bugzilla, not upstream's.\"")
	printf("%s%s\n",	indent, "fi")
}


BEGIN{
	setup_ebuild_phases("wine_build_environment_check pkg_pretend pkg_setup src_unpack src_prepare src_configure multilib_src_configure multilib_src_test multilib_src_install_all pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)

	# Setup some regular expression constants - to hopefully make the script more readable!
	ebuild_inherit_regexp="^inherit "
	variables="COMMON_DEPEND RDEPEND DEPEND IUSE GST_P GV KEYWORDS MV STAGING_P STAGING_DIR STAGING_EGIT_REPO_URI REQUIRED_USE SRC_URI"
	setup_global_regexps(variables)
	staging_use_flags_regexp="[\+]{0,1}(pipelight|s3tc|staging|vaapi)"
	gstreamer_patch_uri="https://dev.gentoo.org/~np-hardass/distfiles/${PN}/${GST_P}.patch.bz2"
	wine_mono_version_regexp="[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+"
	wine_gecko_version_regexp="[[:digit:]]+\\.[[:digit:]]+"

	# Check current wine version against version lists
	is_wine_version_legacy_gstreamer_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_legacy_gstreamer_patch_1_0))
	is_wine_version_staging_supported=(wine_version ~ convert_version_list_to_regexp(wine_versions_staging_supported))
	is_wine_version_no_csmt_staging=(wine_version ~ convert_version_list_to_regexp(wine_versions_no_csmt_staging))
    is_wine_version_updated_multilib_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_updated_multilib_patch))
	is_wine_version_no_sysmacros_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_no_sysmacros_patch))
	is_wine_version_gecko_version_2_44=(wine_version ~ convert_version_list_to_regexp(wine_versions_gecko_version_2_44))
	is_wine_version_mono_version_4_6_0=(wine_version ~ convert_version_list_to_regexp(wine_versions_mono_version_4_6_0))
	is_wine_version_mono_version_4_6_2=(wine_version ~ convert_version_list_to_regexp(wine_versions_mono_version_4_6_2))
	is_wine_version_mono_version_4_6_3=(wine_version ~ convert_version_list_to_regexp(wine_versions_mono_version_4_6_3))

	# Wine Gecko beta versions
	wine_gecko_beta_version="0001-mshtml-Wine-Gecko-2.47-beta1-release.patch"

	# My utility for parsing Wine & Wine-Staging Git trees (pull from Github)
	wine_staging_helper="wine-staging-git-helper-0.1.2"
}

{
	suppress_current_line=0

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	if (!if_check_pv9999_open && ($0 ~ text2regexp("if [[ ${PV} == \"9999\" ]]*; then"))) {
		if_check_pv9999_open=if_stack
		++if_check_pv9999_count
	}
	else if (if_check_pv9999_open && (if_check_pv9999_open == if_stack) && ($0 ~ else_regexp)) {
		else_check_pv9999_open=1
	}

	if (!preamble_over) {
		if ((if_check_pv9999_open == 1) && ($0 ~ "EGIT_BRANCH=\"master\""))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["SRC_URI"])
			src_uri_open=1

		if (src_uri_open) {
			if ($0 ~ "\"https\:.+\"")
				sub((text2regexp("${P}.tar.bz2\"") "$"), "${MY_P}.tar.bz2 -> ${P}.tar.bz2\"")

			if ($0 ~ text2regexp("staging? "))
				sub(text2regexp("${PV}"), "${MY_PV}${STAGING_SUFFIX}")

			if (!gstreamer_patch_uri_found) {
				if (is_wine_version_legacy_gstreamer_patch) {
					gstreamer_patch_uri_found+=sub(text2regexp(gstreamer_patch_uri), "gstreamer? ( & )")
				}
				else {
					gstreamer_patch_uri_found+=sub(text2regexp(gstreamer_patch_uri), "")
					suppress_current_line=suppress_current_line || ($0 ~ blank_line_regexp)
				}
			}
		}

		if (is_wine_version_gecko_version_2_44 && ($0 ~ array_variables_regexp["GV"]))
			sub(wine_gecko_version_regexp, "2.44")
		if ($0 ~ array_variables_regexp["MV"]) {
			if (is_wine_version_mono_version_4_6_0)
				sub(wine_mono_version_regexp, "4.6.0")
			else if (is_wine_version_mono_version_4_6_2)
				sub(wine_mono_version_regexp, "4.6.2")
			else if (is_wine_version_mono_version_4_6_3)
				sub(wine_mono_version_regexp, "4.6.3")
		}
		if (($0 ~ array_variables_regexp["COMMON_DEPEND"]) || ($0 ~ array_variables_regexp["RDEPEND"]) || ($0 ~ array_variables_regexp["DEPEND"]))
			depend_assignment_open=1

		if (depend_assignment_open && sub(text2regexp("^ capi? ( net-dialup/capi4k-utils )"), "") && ($0 ~ blank_line_regexp))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["KEYWORDS"])
			suppress_current_line=1
		if (!is_wine_version_legacy_gstreamer_patch && ($0 ~ array_variables_regexp["GST_P"]))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["STAGING_P"])
			sub(text2regexp("${PV}"), "${MY_PV}")
		if ($0 ~ array_variables_regexp["STAGING_DIR"])
			sub("\".+\"$", "\"${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}\"")
		if (src_uri_open && ($0 ~ end_quote_regexp))
			src_uri_open=0

		if ($0 ~ array_variables_regexp["REQUIRED_USE"])
			required_use_assignment_open=1
		if (!is_wine_version_staging_supported) {
			if (($0 ~ array_variables_regexp["STAGING_P"]) || ($0 ~ array_variables_regexp["STAGING_DIR"]))
				suppress_current_line=1
			if (if_check_pv9999_open && (if_check_pv9999_count == 2))
				suppress_current_line=1
			if ($0 ~ array_variables_regexp["IUSE"])
				gsub((quote_or_ws_seperator_regexp staging_use_flags_regexp quote_or_ws_seperator_regexp), " ")
			if (required_use_assignment_open || depend_assignment_open) {
				if (($0 ~ (quote_or_ws_seperator_regexp staging_use_flags_regexp "\\?")) && (gsub((staging_use_flags_regexp "\\?[[:blank:]]" bracketed_expression_regexp), "") > 0) && ($0 ~ blank_line_regexp))
					suppress_current_line=1
			}
		}
		else if (else_check_pv9999_open && (if_check_pv9999_count == 2) && !staging_git_helper) {
			printf("%s%s\n", indent, "SRC_URI=\"${SRC_URI}")
			printf("%s%s\n", indent, "staging? ( https://github.com/bobwya/${STAGING_HELPER%-*}/archive/${STAGING_HELPER##*-}.tar.gz -> ${STAGING_HELPER}.tar.gz )\"")
			++staging_git_helper
		}
		if ($0 ~ array_variables_regexp["IUSE"])
			sub((quote_or_ws_seperator_regexp "capi" quote_or_ws_seperator_regexp), " ")

		if (required_use_assignment_open && (is_wine_version_mono_version_4_6_0 || is_wine_version_mono_version_4_6_2)) {
			if (sub(text2regexp("mono? ( * )"), "") && ($0 ~ blank_line_regexp))
				suppress_current_line=1
		}
		required_use_assignment_open=required_use_assignment_open && ($0 !~ end_quote_regexp)
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)) {
		preamble_over=1
		if_stack=0
		target_block_open=0
	}


	# Ebuild phase based pre-checks
	if (array_phase_open["wine_build_environment_check"]) {
		sub("wine_build_environment_check", "wine_build_environment_prechecks")
		if (!change_source_path) {
			printf("%s\n\n", "S=\"${WORKDIR}/${MY_P}\"")
			change_source_path=1
		}
		suppress_current_line=suppress_current_line || (($0 ~ text2regexp("^ # bug #549768")) || ($0 ~ text2regexp("^ # bug #574044")))
		if ((if_stack == 1) && ($0 ~ if_open_regexp) && ($0 ~ text2regexp(" use abi_x86_64 * $(gcc-major-version) = 5 ")))
			suppress_bug_check_open=1
		suppress_current_line=suppress_current_line || suppress_bug_check_open
		if (($0 ~ if_close_regexp) && (if_stack == 0) && suppress_bug_check_open)
			suppress_bug_check_open=0
	}
	else if (array_phase_open["pkg_pretend"]) {
		if (!wine_build_environment_pretests) {
			wine_build_environment_pretests=1
			print_wine_build_environment_pretests(indent)
		}

		if ($0 ~ text2regexp("^ wine_build_environment_check")) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
	}
	else if (array_phase_open["pkg_setup"]) {
		if ($0 ~ text2regexp("^ wine_build_environment_check")) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
	}
	else if (array_phase_open["src_unpack"]) {
		if (if_check_pv9999_open && !else_check_pv9999_open)
			suppress_current_line=1
		if (if_check_pv9999_open && !do_git_unpack_replaced) {
			print_src_unpack_live_ebuild_support(indent, is_wine_version_staging_supported)
			++do_git_unpack_replaced
		}
		if (if_check_pv9999_open && else_check_pv9999_open && ($0 ~ text2regexp("^ use staging"))) {
			if (is_wine_version_legacy_gstreamer_patch)
				printf("%s%s%s\n",	indent, indent, "use gstreamer && unpack \"${GST_P}.patch.bz2\"")
			if (!is_wine_version_staging_supported)
				suppress_current_line=1
		}
		if (($0 ~ text2regexp("use gstreamer")) || ($0 ~ text2regexp("^ unpack \"${GST_P}.patch.bz2\"")))
			suppress_current_line=1
	}
	else if (array_phase_open["src_prepare"]) {
		if ($0 ~ text2regexp("^ local PATCHES=("))
			patch_set_define_open=1
		if (patch_set_define_open) {
			if (($0 ~ text2regexp("multilib-portage.patch")) || ($0 ~ text2regexp("${WORKDIR}/${GST_P}.patch")))
				suppress_current_line=1
			if (is_wine_version_no_sysmacros_patch && ($0 ~ text2regexp("sysmacros.patch")))
				suppress_current_line=1
		}
		if (($0 ~ if_open_regexp) && ($0 ~ text2regexp("use staging")))
			wine_staging_check_open=if_stack
		if ((wine_staging_check_open == 1) && ($0 ~ text2regexp("eend $?")))
			sub("$", " || die \"(subshell) script: failed to apply Wine-Staging patches.\"")
		if (is_wine_version_staging_supported) {
			if ((wine_staging_check_open == 1) && ($0 ~ if_close_regexp)) {
				printf("\n%s%s%s\n", indent, indent, "if [[ ! -z \"${STAGING_SUFFIX}\" ]]; then")
				printf("%s%s%s%s\n", indent, indent, indent, "sed -i -e 's/(Staging)/(Staging'\"${STAGING_SUFFIX}\"')/' libs/wine/Makefile.in || die \"sed\"")
				printf("%s%s%s\n", indent, indent, "fi")
			}
		}
		else {
			if ($0 ~ text2regexp("PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )"))
				sub(text2regexp("^ "), (indent indent))
			else
				suppress_current_line+=wine_staging_check_open
			if ($0 ~ comment_regexp)
				suppress_current_line=1
		}
		if ($0 ~ if_close_regexp)
			wine_staging_check_open=(wine_staging_check_open == if_stack+1) ? 0 : wine_staging_check_open
	}
	else if (array_phase_open["multilib_src_configure"]) {
		sub(text2regexp("$(use_with capi)"), "--without-capi")
		if ($0 ~ text2regexp("^ use staging")) {
			wine_staging_check_open=1
			open_bracketed_expression=($0 ~ bracketed_expression_open_regexp "$")
		}
		if (!is_wine_version_staging_supported && wine_staging_check_open)
			suppress_current_line=1
		if (open_bracketed_expression && ($0 ~ leading_ws_regexp bracketed_expression_close_regexp))
			open_bracketed_expression=0
		wine_staging_check_open=wine_staging_check_open && open_bracketed_expression
	}
	else if (array_phase_open["pkg_postinst"]) {
		sub("like via winetricks\"$", "via winetricks.\"")
		if (($0 ~ if_open_regexp) && ($0 ~ text2regexp("use gstreamer")))
			gstreamer_check_open=if_stack
		suppress_current_line=suppress_current_line || gstreamer_check_open
		if ($0 ~ if_close_regexp)
			gstreamer_check_open=(gstreamer_check_open == if_stack+1) ? 0 : gstreamer_check_open

		if ($0 ~ blank_line_regexp) {
			++blank_line_count
			suppress_current_line=suppress_current_line || (blank_line_count >= 2)
		}
		if ($0 ~ end_curly_bracket_regexp) {
			if (is_wine_version_staging_supported && is_wine_version_no_csmt_staging)
				print_pkg_postinst_csmt_warning(indent)
			if (is_wine_version_legacy_gstreamer_patch)
				print_pkg_postinst_gstreamer_patch_warning(indent)
		}
	}

	# Print current line in ebuild
	if (!suppress_current_line) {
		# Eat more than 1 empty line
		blank_lines=($0 ~ blank_line_regexp) ? blank_lines+1 : 0
		if (blank_lines <= 1)
			print $0
	}

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=(indent == 0) ? substr($0, RSTART, RLENGTH) : indent

	if (!preamble_over) {
		if (if_check_pv9999_open) {
			if ($0 ~ "inherit git-r3") {
				printf("%s%s\n", indent, "MY_PV=\"${PV}\"")
				if (is_wine_version_staging_supported)
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
				if (is_wine_version_staging_supported)
					printf("%s%s\n", indent, "[[ \"${MY_PV}\" =~ ^1\\.8\\.[[:digit:]]+$ ]] && STAGING_SUFFIX=\"-unofficial\"")
				printf("%s%s\n", indent, "MY_P=\"${PN}-${MY_PV}\"")
			}
		}
		if (($0 ~ array_variables_regexp["STAGING_DIR"]) && is_wine_version_staging_supported) {
			printf("%s\n", ("STAGING_HELPER=\"" wine_staging_helper "\""))
			printf("%s\n", ("GV_BETA_PATCH=\"" wine_gecko_beta_version "\""))
		}
		depend_assignment_open=depend_assignment_open && ($0 !~ end_quote_regexp)
	}

	# Ebuild phase based post-checks
	if ((array_phase_open["pkg_pretend"] || array_phase_open["pkg_setup"]) && wine_build_environment_prechecks) {
		printf("%s%s\n", indent, "wine_build_environment_prechecks || die")
		printf("%s%s\n", indent, "wine_build_environment_pretests || die")
		wine_build_environment_prechecks=0
	}
	else if (array_phase_open["src_prepare"]) {
		if (patch_set_define_open && ($0 ~ (bracketed_expression_close_regexp "$"))) {
			print_src_prepare_live_build_patch_support(indent, is_wine_version_legacy_gstreamer_patch, is_wine_version_updated_multilib_patch)
			patch_set_define_open=0
		}
		if (is_wine_version_staging_supported) {
			if ((wine_version == "1.9.5-r1") && ($0 ~ text2regexp("^ use pipelight")))  {
				printf("%s%s%s\n",		indent, indent, ("#577198 only affects " wine_version))
				printf("%s%s%s\n",		indent, indent, "use nls || STAGING_EXCLUDE=\"${STAGING_EXCLUDE} -W makefiles-Disabled_Rules\"")
			}
			if ($0 ~ text2regexp("^ local STAGING_EXCLUDE=\"")) {
				printf("%s%s%s\n",		indent, indent, "if grep -q \"${GV_BETA_PATCH}\" \"${STAGING_DIR}/patches/patchinstall.sh\"; then")
				printf("%s%s%s%s\n",	indent, indent, indent, "local GV_BETA=$( \"${FILESDIR}/beta_patch_conv.sh\" \"${GV_BETA_PATCH}\" )")
				printf("%s%s%s%s\n",	indent, indent, indent, "STAGING_EXCLUDE=\"${STAGING_EXCLUDE} -W ${GV_BETA}\"")
				printf("%s%s%s\n",		indent, indent, "fi")
			}
		}
	}


	if (if_check_pv9999_open && (if_check_pv9999_open == if_stack+1) && ($0 ~ if_close_regexp))
		if_check_pv9999_open=else_check_pv9999_open=0

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
