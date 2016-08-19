#!/bin/awk

function print_wine_version_handler_block(indent)
{
	printf("%s\n",	"MY_PV=\"${PV}\"")
	printf("%s\n",	"MY_P=\"${P}\"")
	if (is_wine_version_staging_supported && (wine_version !~ wine_staging_official_regexp))
		printf("%s\n", "STAGING_SUFFIX=\"\"")
	printf("%s\n",	"if [[ ${PV} == \"9999\" ]]; then")
	printf("%s%s\n",	indent, "EGIT_REPO_URI=\"git://source.winehq.org/git/wine.git http://source.winehq.org/git/wine.git\"")
	printf("%s%s\n",	indent, "inherit git-r3")
	printf("%s%s\n",	indent, "SRC_URI=\"\"")
	printf("%s%s\n",	indent, "#KEYWORDS=\"\"")
	printf("%s\n",	"else")
	printf("%s%s\n",	indent, "MAJOR_VERSION=$(get_version_component_range 1-2)")
	printf("%s%s\n",	indent, "if [[ \"$(get_version_component_range $(get_version_component_count))\" =~ ^rc ]]; then")
	printf("%s%s%s\n",	indent, indent, "MY_PV=$(replace_version_separator $(get_last_version_component_index) '''-''')")
	printf("%s%s%s\n",	indent, indent, "# Pull Wine stable revision control (RC) versions from alternate github repostiory...")
	printf("%s%s%s\n",	indent, indent, "STABLE_PREFIX=\"wine-stable\"")
	printf("%s%s%s\n",	indent, indent, "SRC_URI=\"https://github.com/mstefani/wine-stable/archive/${PN}-${MY_PV}.tar.gz -> ${STABLE_PREFIX}-${P}.tar.gz\"")
	printf("%s%s%s\n",	indent, indent, "MY_P=\"${STABLE_PREFIX}-${PN}-${MY_PV}\"")
	printf("%s%s\n",	indent, "else")
	printf("%s%s%s\n",	indent, indent, "KEYWORDS=\"-* ~amd64 ~x86 ~x86-fbsd\"")
	printf("%s%s%s\n",	indent, indent, "SRC_URI=\"https://dl.winehq.org/wine/source/${MAJOR_VERSION}/${MY_P}.tar.bz2 -> ${P}.tar.bz2\"")
	printf("%s%s\n",	indent, "fi")
	if (is_wine_version_staging_supported && (wine_version !~ wine_staging_official_regexp))
		printf("%s%s\n",indent, "[[ \"${MAJOR_VERSION}\" == \"1.8\" ]] && STAGING_SUFFIX=\"-unofficial\"")
	printf("%s\n\n","fi")
}

function print_gcc_specific_pretests(indent)
{
	printf("%s\n",		"wine_gcc_specific_pretests() {")
	printf("%s%s\n\n",	indent, "( [[ \"${MERGE_TYPE}\" = \"binary\" ]] || ! tc-is-gcc ) && return 0")
	printf("%s%s\n",	indent, "# bug #549768")
	printf("%s%s\n",	indent, "if use abi_x86_64 && [[ $(gcc-major-version) -eq 5 && $(gcc-minor-version) -le 2 ]]; then")
	printf("%s%s%s\n",	indent, indent, "ebegin \"(subshell): checking for gcc-5.1/gcc-5.2 MS X86_64 ABI compiler bug ...\"")
	printf("%s%s%s\n",	indent, indent, "( # Run in a subshell to prevent \"Aborted\" message")
	printf("%s%s%s%s\n",indent, indent, indent, "$(tc-getCC) -O2 \"${FILESDIR}/pr66838.c\" -o \"${T}/pr66838\" || die \"cc compilation failed: pr66838 test\"")
	printf("%s%s%s%s\n",indent, indent, indent, "\"${T}\"/pr66838 &>/dev/null || die \"pr66838 test failed\"")
	printf("%s%s%s\n",	indent, indent, ")")
	printf("%s%s%s\n",	indent, indent, "if ! eend $?; then")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"(subshell): gcc-5.1/5.2 MS X86_64 ABI compiler bug detected.\"")
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
	printf("%s%s%s\n",	indent, indent, "ebegin \"(subshell): checking for gcc-5.3.0 X86_64 misaligned stack compiler bug ...\"")
	printf("%s%s%s\n",	indent, indent, "( # Compile in a subshell to prevent \"Aborted\" message")
	printf("%s%s%s%s\n",indent, indent, indent, "$(tc-getCC) -O2 -mincoming-stack-boundary=3 \"${FILESDIR}\"/pr69140.c -o \"${T}\"/pr69140 &>/dev/null || die \"pr69140 test failed\"")
	printf("%s%s%s\n",	indent, indent, ")")
	printf("%s%s%s\n",	indent, indent, "if ! eend $?; then")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"(subshell): gcc-5.3.0 X86_64 misaligned stack compiler bug detected.\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Please re-emerge the latest gcc-5.3.0 ebuild, or use gcc-config to select a different compiler version.\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"See https://bugs.gentoo.org/574044\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror")
	printf("%s%s%s%s\n",indent, indent, indent, "return 1")
	printf("%s%s%s\n",	indent, indent, "fi")
	printf("%s%s\n",	indent, "fi")
	printf("}\n\n")
}

function print_builtin_ms_va_list_pretest(indent)
{
	printf("\n%s%s\n",	indent, "if use abi_x86_64; then")
	printf("%s%s%s\n",	indent, indent, "ebegin \"(subshell): checking compiler support for (64-bit) builtin_ms_va_list ...\"")
	printf("%s%s%s\n",	indent, indent, "( # Compile in a subshell to prevent \"Aborted\" message")
	printf("%s%s%s%s\n",indent, indent, indent, "$(tc-getCC) -O2 \"${FILESDIR}\"/builtin_ms_va_list.c -o \"${T}\"/builtin_ms_va_list &>/dev/null || die \"test for builtin_ms_va_list support failed\"")
	printf("%s%s%s\n",	indent, indent, ")")
	printf("%s%s%s\n",	indent, indent, "if ! eend $?; then")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"(subshell): $(tc-getCC) does not support builtin_ms_va_list.\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Please re-emerge using a compiler (version) that supports building 64-bit Wine.\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror \"Use >=sys-devel/gcc-4.4 or >=sys-devel/clang-3.8 to build ${CATEGORY}/${PN}.\"")
	printf("%s%s%s%s\n",indent, indent, indent, "eerror")
	printf("%s%s%s%s\n",indent, indent, indent, "return 1")
	printf("%s%s%s\n",	indent, indent, "fi")
	printf("%s%s\n",	indent, "fi")
}

function print_pkg_pretend_oss_check(indent)
{
	printf("%s%s\n",	indent, "if use oss && ! use kernel_FreeBSD && ! has_version '>=media-sound/oss-4'; then")
	printf("%s%s%s\n",	indent, indent, "eerror \"You cannot build wine with USE=+oss without having support from a FreeBSD kernel\"")
	printf("%s%s%s\n",	indent, indent, "eerror \"or >=media-sound/oss-4 (only available through an Overlay).\"")
	printf("%s%s%s\n",	indent, indent, "die \"USE=+oss currently unsupported on this system.\"")
	printf("%s%s\n",	indent, "fi")
}

function print_src_prepare_live_build_patch_support(indent, is_legacy_gstreamer_patch)
{
	if (is_legacy_gstreamer_patch) {
		printf("%s%s\n",		indent, "if [[ ${PV} != \"9999\" ]]; then")
		if (wine_version == "1.9.1") {
			printf("%s%s%s\n",	indent, indent, "if use gstreamer; then")
			printf("%s%s%s%s\n",indent, indent, indent, "# version 1.9.1 already implements partial gstreamer:1.0 support")
			printf("%s%s%s%s\n",indent, indent, indent, "[[ \"${PV}\" == \"1.9.1\" ]] && { sed -i -e '1,71d' \"${WORKDIR}/${GST_P}.patch\" || die \"sed\"; }")
			printf("%s%s%s%s\n",indent, indent, indent, "PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
			printf("%s%s%s\n",	indent, indent, "fi")
		}
		else {
			printf("%s%s%s\n",	indent, indent, "use gstreamer && PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
		}
		printf("%s%s\n",		indent, "else")
		printf("%s%s%s\n",	indent, indent, "# only apply gstreamer:1.0 patch to older versions of wine, using gstreamer:0.1 API/ABI")
		printf("%s%s%s\n",	indent, indent, "grep -q \"gstreamer-0.10\" \"${S}/configure\" &>/dev/null || unset GST_P")
		printf("%s%s%s\n",	indent, indent, "[[ ! -z \"${GST_P}\" ]] && use gstreamer && PATCHES+=( \"${WORKDIR}/${GST_P}.patch\" )")
		printf("%s%s\n",		indent, "fi")
	}
	printf("%s%s\n",	indent, "#395615 - run bash/sed script, combining both versions of the multilib-portage.patch")
	printf("%s%s\n",	indent, "ebegin \"(subshell) script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\" ...\"")
	printf("%s%s\n",	indent, "(")
	printf("%s%s%s\n",	indent, indent, "source \"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\" || die")
	printf("%s%s\n",	indent, ")")
	printf("%s%s\n",	indent, "eend $? || die \"(subshell) script: \\\"${FILESDIR}/${PN}-9999-multilib-portage-sed.sh\\\".\"")

}

function print_src_unpack_live_ebuild_support(indent, is_staging_supported)
{
	printf("%s%s\n", 	indent, "default")
	printf("%s%s\n", 	indent, "if [[ ${PV} == \"9999\" ]]; then")
	printf("%s%s%s\n",	indent, indent, "# Fully Mirror git tree, Wine, so we can access commits in all branches")
	printf("%s%s%s\n",	indent, indent, "EGIT_MIN_CLONE_TYPE=\"mirror\"")
	printf("%s%s%s\n",	indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\"")
	if (is_staging_supported) {
		printf("%s%s%s\n",	 indent, indent, "if ! use staging; then")
		printf("%s%s%s%s\n", indent, indent, indent, "git-r3_src_unpack")
		printf("%s%s%s\n", indent, indent, "elif [[ ! -z \"${EGIT_STAGING_COMMIT:-${EGIT_STAGING_BRANCH}}\" ]]; then")
		printf("%s%s%s%s\n", indent, indent, indent, "# References are relative to Wine-Staging git tree (checkout Wine-Staging git tree first)")
		printf("%s%s%s%s\n", indent, indent, indent, "# Use env variables \"EGIT_STAGING_COMMIT\" or \"EGIT_STAGING_BRANCH\" to reference Wine-Staging git tree")
		printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"(subshell): you have specified a Wine-Staging git reference (building Wine git with USE +staging) ...\"")
		printf("%s%s%s%s\n", indent, indent, indent, "(")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "source \"${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh\" || die")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "if [[ ! -z \"${EGIT_STAGING_COMMIT}\" ]]; then")
		printf("%s%s%s%s%s%s\n",indent, indent, indent, indent, indent, "local staging_remote_ref=\"${EGIT_STAGING_COMMIT}\"")
		printf("%s%s%s%s%s%s\n",indent, indent, indent, indent, indent, "ewarn \"Building Wine against Wine-Staging git commit EGIT_STAGING_COMMIT=\\\"${EGIT_STAGING_COMMIT}\\\" .\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "else")
		printf("%s%s%s%s%s%s\n",indent, indent, indent, indent, indent, "local staging_remote_ref=\"refs/heads/${EGIT_STAGING_BRANCH}\"")
		printf("%s%s%s%s%s%s\n",indent, indent, indent, indent, indent, "ewarn \"Building Wine against Wine-Staging git commit EGIT_STAGING_BRANCH=\\\"${EGIT_STAGING_BRANCH}\\\" .\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "fi")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "# Use git-r3 internal functions for secondary Wine-Staging repostiory. See #588604")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "git-r3_fetch \"${STAGING_EGIT_REPO_URI}\" \"${staging_remote_ref}\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "git-r3_checkout \"${STAGING_EGIT_REPO_URI}\" \"${STAGING_DIR}\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "WINE_STAGING_COMMIT=\"${EGIT_VERSION}\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "get_upstream_wine_commit  \"${STAGING_DIR}\" \"${WINE_STAGING_COMMIT}\" \"WINE_COMMIT\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "EGIT_COMMIT=\"${WINE_COMMIT}\" git-r3_src_unpack")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "einfo \"Building Wine commit \\\"${WINE_COMMIT}\\\" referenced by Wine-Staging commit \\\"${WINE_STAGING_COMMIT}\\\" ...\"")
		printf("%s%s%s%s\n", indent, indent, indent, ")")
		printf("%s%s%s%s\n", indent, indent, indent, "eend $? || die \"(subshell): ... failed to determine target Wine commit.\"")
		printf("%s%s%s\n",	 indent, indent, "else")
		printf("%s%s%s%s\n", indent, indent, indent, "# References are relative to Wine git tree (post-checkout Wine-Staging git tree)")
		printf("%s%s%s%s\n", indent, indent, indent, "ebegin \"(subshell): You are using a Wine git reference (building Wine git with USE +staging) ...\"")
		printf("%s%s%s%s\n", indent, indent, indent, "(")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "source \"${WORKDIR}/${STAGING_HELPER}/${STAGING_HELPER%-*}.sh\" || die")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "git-r3_src_unpack")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "WINE_COMMIT=\"${EGIT_VERSION}\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "# Use git-r3 internal functions for secondary Wine-Staging repostiory. See #588604")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "git-r3_fetch \"${STAGING_EGIT_REPO_URI}\" \"HEAD\"")
		printf("%s%s%s%s%s\n", indent, indent, indent, indent, "git-r3_checkout \"${STAGING_EGIT_REPO_URI}\" \"${STAGING_DIR}\"")
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
	else {
		printf("%s%s%s\n", indent, indent, "git-r3_src_unpack")
	}
	printf("%s%s\n",	 indent, "fi")
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
	setup_ebuild_phases("wine_compiler_check wine_build_environment_check pkg_pretend pkg_setup src_unpack src_prepare src_configure multilib_src_configure multilib_src_test multilib_src_install_all pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)

	# Setup some regular expression constants - to hopefully make the script more readable!
	ebuild_inherit_regexp="^inherit "
	variables="COMMON_DEPEND RDEPEND DEPEND IUSE GST_P KEYWORDS STAGING_P STAGING_DIR STAGING_EGIT_REPO_URI REQUIRED_USE SRC_URI STAGING_GV STAGING_MV VANILLA_GV VANILLA_MV"
	setup_global_regexps(variables)
	staging_use_flags_regexp="(pipelight|s3tc|staging|themes|vaapi)"
	gstreamer_patch_uri="https://dev.gentoo.org/~np-hardass/distfiles/${PN}/${GST_P}.patch.bz2"
	wine_mono_version_regexp="[[:digit:]]+\\.[[:digit:]]+\\.[[:digit:]]+"
	wine_gecko_version_regexp="[[:digit:]]+\\.[[:digit:]]+"
	wine_staging_official_regexp="^1\\.8(|_rc[[:digit:]]+)$"

	# Check current wine version against version lists
	is_wine_version_legacy_gstreamer_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_legacy_gstreamer_patch_1_0))
	is_wine_version_staging_supported=(wine_version ~ convert_version_list_to_regexp(wine_versions_staging_supported))
	is_wine_version_no_csmt_staging=(wine_version ~ convert_version_list_to_regexp(wine_versions_no_csmt_staging))
	is_wine_version_no_sysmacros_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_no_sysmacros_patch))
	is_wine_version_no_gnutls_patch=(wine_version ~ convert_version_list_to_regexp(wine_versions_no_gnutls_patch))
	is_wine_version_staging_eapply_supported=(wine_version ~ convert_version_list_to_regexp(wine_versions_staging_eapply_supported))

	print "Wine version=" wine_version >"/dev/stderr"
	print "Wine versions with Staging support: " convert_version_list_to_regexp(wine_versions_staging_supported) >"/dev/stderr"
	print "Wine is Wine-Staging supported=" is_wine_version_staging_supported >"/dev/stderr"
	# My utility for parsing Wine & Wine-Staging Git trees (pull from Github)
	wine_staging_helper="wine-staging-git-helper-0.1.2"

	bracket_depth=depend_bracket_depth=uri_bracket_depth=-1
}

{
	# Make ebuild's use consistent spacing/layout throughout...
	if (($0 ~ text2regexp("^if")) || ($0 ~ text2regexp("^ if"))) {
		sub(text2regexp(" ; then$"), "; then")
		if ($0 ~ text2regexp(" ; then #*$"))
			sub(text2regexp(" ; then"), "; then ")
	}

	# Comment trailing die commands...
	if (($0 ~ text2regexp(" die$")) || ($0 ~ text2regexp(" die #*$"))) {
		i=NF-1
		if ($0 !~ text2regexp(" die$")) {
			while (--i) {
				if (($(i+1) == "die") && ($(i+2) ~ "^\\#"))
					break
			}
		}
		while (--i) {
			if (($i == "||") || ($i == "&&"))
				break
		}
		while ($(++i) == "")
			;
		if (($i ~ "[[:alpha:]]+") && !sub(text2regexp(" die$"), (" die \"" $i "\""))) sub(text2regexp(" die #"), (" die \"" $i "\"  #"))
	}

	suppress_current_line=0

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	if (!if_check_pv9999_open && ($0 ~ text2regexp("if [[ ${PV} == \"9999\" ]]; then"))) {
		if_check_pv9999_open=if_stack
		++if_check_pv9999_count
	}
	else if (if_check_pv9999_open && (if_check_pv9999_open == if_stack) && ($0 ~ else_regexp)) {
		else_check_pv9999_open=1
	}

	if (!preamble_over) {
		if ((if_check_pv9999_open == 1) && (if_check_pv9999_count == 1)) {
			if (match($0, leading_ws_regexp))
				indent=(indent == 0) ? substr($0, RSTART, RLENGTH) : indent
			if ((indent != 0) && !display_version_handler_block) {
				print_wine_version_handler_block(indent)
				display_version_handler_block=1
			}
			suppress_current_line=1
		}

		if ($0 ~ array_variables_regexp["SRC_URI"])
			src_uri_assignment_open=1
		else if ($0 ~ array_variables_regexp["REQUIRED_USE"])
			required_use_assignment_open=1
		else if (($0 ~ array_variables_regexp["COMMON_DEPEND"]) || ($0 ~ array_variables_regexp["RDEPEND"]) || ($0 ~ array_variables_regexp["DEPEND"]))
			depend_assignment_open=1

		if (src_uri_assignment_open || required_use_assignment_open || depend_assignment_open) {
			bracket_depth=(bracket_depth == -1) ? 0 : bracket_depth
			bracket_depth += $0 ~ "(^|[[:blank:]]+)\\(([[:blank:]]+|$)"
		}

		if (src_uri_assignment_open) {
			if ($0 ~ text2regexp("^ staging? (")) {
				uri_staging_test_open=1
				#printf("staging?  uri_staging_test_open=%s\n", (uri_staging_test_open ? "true" : "false"))
				uri_bracket_depth=bracket_depth
			}
			else if ($0 ~ text2regexp("^ !staging? (")) {
				uri_nonstaging_test_open=1
				#printf("nonstaging?  uri_nonstaging_test_open=%s\n", (uri_nonstaging_test_open ? "true" : "false"))
				uri_bracket_depth=bracket_depth
				if (!is_wine_version_staging_supported)
					suppress_current_line=1
			}
			#printf("uri_staging_test_open=%s (bracket_depth=%d / uri_bracket_depth=%d)\n", (uri_staging_test_open ? "true" : "false"), bracket_depth, uri_bracket_depth)
			if (uri_staging_test_open) {
				if (is_wine_version_staging_supported) {
					gsub(text2regexp("${STAGING_GV}"), "${STAGING_GV:-${VANILLA_GV}}")
					gsub(text2regexp("${STAGING_MV}"), "${STAGING_MV:-${VANILLA_MV}}")
				}
				else
					suppress_current_line=1
			}
			else if (uri_nonstaging_test_open && !is_wine_version_staging_supported) {
				sub(indent, "")
			}

			if ($0 ~ text2regexp("staging? ")) {
				if (wine_version ~ wine_staging_official_regexp)
					sub(text2regexp("${PV}"), "${MY_PV}")
				else
					sub(text2regexp("${PV}"), "${MY_PV}${STAGING_SUFFIX}")
			}

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

		if ($0 ~ array_variables_regexp["VANILLA_GV"])
			sub(wine_gecko_version_regexp, wine_gecko_version)
		else if ($0 ~ array_variables_regexp["STAGING_GV"]) {
			if ((wine_gecko_version == wine_staging_gecko_version) || !is_wine_version_staging_supported)
				suppress_current_line=1
			else
				sub(wine_gecko_version_regexp, wine_staging_gecko_version)
		}
		if ($0 ~ array_variables_regexp["VANILLA_MV"])
			sub(wine_mono_version_regexp, wine_mono_version)
		else if ($0 ~ array_variables_regexp["STAGING_MV"]) {
			if ((wine_mono_version == wine_staging_mono_version) || !is_wine_version_staging_supported)
				suppress_current_line=1
			else
				sub(wine_mono_version_regexp, wine_staging_mono_version)
		}

		if ($0 ~ array_variables_regexp["KEYWORDS"])
			suppress_current_line=1
		if (!is_wine_version_legacy_gstreamer_patch && ($0 ~ array_variables_regexp["GST_P"]))
			suppress_current_line=1

		if ($0 ~ array_variables_regexp["STAGING_P"])
			sub(text2regexp("${PV}"), "${MY_PV}")
		if (($0 ~ array_variables_regexp["STAGING_DIR"]) && (wine_version !~ wine_staging_official_regexp))
			sub("\".+\"$", "\"${WORKDIR}/${STAGING_P}${STAGING_SUFFIX}\"")

		if (!is_wine_version_staging_supported) {
			if (($0 ~ array_variables_regexp["STAGING_P"]) || ($0 ~ array_variables_regexp["STAGING_DIR"]))
				suppress_current_line=1
			if (if_check_pv9999_open && (if_check_pv9999_count == 2))
				suppress_current_line=1
			if ($0 ~ array_variables_regexp["IUSE"]) {
				print text2regexp(("( |\")" staging_use_flags_regexp "( |\")"),1) >"/dev/stderr"
				gsub(text2regexp(("( |\")" staging_use_flags_regexp "( |\")"),1), " ")
			}

			if (required_use_assignment_open || depend_assignment_open) {
				if ($0 ~ text2regexp((" (+|)" staging_use_flags_regexp "?"),1))
					depend_bracket_depth=(depend_bracket_depth == -1) ? bracket_depth : depend_bracket_depth
				if ((depend_bracket_depth != -1) && (bracket_depth >= depend_bracket_depth)) {
					#printf("suppress current line (%d):\n", depend_bracket_depth)
					if ($0 ~ end_quote_regexp)
						sub("[^[:blank:]].+$","\"")
					else
						suppress_current_line=1
				}
			}

			if (required_use_assignment_open && ($0 ~ text2regexp("^ \" #*$")))
				sub(text2regexp(" #*$"), "")
		}
		else {
			if (depend_assignment_open) {
				if (sub(text2regexp("themes? ($"), "themes? ( x11-libs/gtk+:3[X?,${MULTILIB_USEDEP}] )"))
					depend_bracket_depth=(depend_bracket_depth == -1) ? bracket_depth-1 : depend_bracket_depth
				else if ((depend_bracket_depth != -1) && (bracket_depth >= depend_bracket_depth))
					suppress_current_line=1
			}
			if (else_check_pv9999_open && (if_check_pv9999_count == 2) && !staging_git_helper) {
				printf("%s%s\n", indent, "SRC_URI=\"${SRC_URI}")
				printf("%s%s\n", indent, "staging? ( https://github.com/bobwya/${STAGING_HELPER%-*}/archive/${STAGING_HELPER##*-}.tar.gz -> ${STAGING_HELPER}.tar.gz )\"")
				++staging_git_helper
			}
		}
		if (src_uri_assignment_open || required_use_assignment_open || depend_assignment_open)
			bracket_depth -= $0 ~ "(^|[[:blank:]]+)\\)([[:blank:]]+|$)"

		if (src_uri_assignment_open && (bracket_depth < uri_bracket_depth)) {
			if (uri_nonstaging_test_open && !is_wine_version_staging_supported)
				suppress_current_line=1
			uri_nonstaging_test_open=uri_staging_test_open=0
		}
		if (required_use_assignment_open && (wine_mono_version != "4.5.6") && (sub(text2regexp("mono? ( * )"), "") && ($0 ~ blank_line_regexp)))
			suppress_current_line=1

		if ($0 ~ end_quote_regexp) {
			required_use_assignment_open=src_uri_assignment_open=depend_assignment_open=0
			bracket_depth=-1
		}
		depend_bracket_depth=(bracket_depth < depend_bracket_depth) ? -1 : depend_bracket_depth
		uri_bracket_depth=(bracket_depth < uri_bracket_depth) ? -1 : uri_bracket_depth
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)) {
		if (!preamble_over && !change_source_path) {
			printf("%s\n\n", "S=\"${WORKDIR}/${MY_P}\"")
			change_source_path=1
		}
		preamble_over=1
		if_stack=0
		target_block_open=0
	}


	# Ebuild phase based pre-checks
	if (array_phase_open["wine_build_environment_check"]) {
		sub("wine_build_environment_check", "wine_build_environment_prechecks")
		suppress_current_line=suppress_current_line || (($0 ~ text2regexp("^ # bug #549768")) || ($0 ~ text2regexp("^ # bug #574044")))
		if ((if_stack == 1) && ($0 ~ if_open_regexp) && ($0 ~ text2regexp(" use abi_x86_64 * $(gcc-major-version) = 5 ")))
			suppress_bug_check_open=1
		suppress_current_line=suppress_current_line || suppress_bug_check_open
		if (($0 ~ if_close_regexp) && (if_stack == 0) && suppress_bug_check_open)
			suppress_bug_check_open=0
		if ((if_stack == 1) && ($0 ~ if_open_regexp) && ($0 ~ text2regexp("use abi_x86_32"))) {
			sub(" x", " ")
			sub("\"x", "\"")
			sub(text2regexp(" /dev/null"), "/dev/null")
		}
		if (if_stack == 1) {
			if ($0 ~ text2regexp("^ eerror*\"*https://bugs.gentoo.org*\""))
				sub(text2regexp(" for more details."), "")
			sub(text2regexp("USE=opencl"), "USE=+opencl")
		}
	}
	else if (array_phase_open["wine_compiler_check"]) {
		if (!gcc_specific_pretests) {
			gcc_specific_pretests=1
			print_gcc_specific_pretests(indent)
			sub(text2regexp("^wine_compiler_check"), "wine_generic_compiler_pretests")
		}
		wine_compiler_check_tests_open=wine_compiler_check_tests_open && ($0 !~ text2regexp("^}"))
		if (wine_compiler_check_tests_open)
			suppress_current_line=1
	}
	else if (array_phase_open["pkg_pretend"]) {
		if ($0 ~ text2regexp("^ wine_build_environment_check")) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
		else if ($0 ~ text2regexp("^ wine_compiler_check")) {
			suppress_current_line=1
		}
		if ((if_stack == 1) && ($0 ~ if_open_regexp) && ($0 ~ text2regexp(" use oss * kernel_FreeBSD"))) {
			print_pkg_pretend_oss_check(indent)
			oss_support_check_open=1
		}
		if (oss_support_check_open) {
			suppress_current_line=1
			oss_support_check_open=((if_stack == 0) && ($0 ~ if_close_regexp)) ? 0 : 1
		}
	}
	else if (array_phase_open["pkg_setup"]) {
		if ($0 ~ text2regexp("^ wine_build_environment_check")) {
			wine_build_environment_prechecks=1
			suppress_current_line=1
		}
		if (is_wine_version_staging_supported) {
			sub(text2regexp("${STAGING_GV}"), "${STAGING_GV:-${VANILLA_GV}}")
			sub(text2regexp("${STAGING_MV}"), "${STAGING_MV:-${VANILLA_MV}}")
		}
		else {
			if (!staging_if_open && ($0 ~ if_open_regexp) && ($0 ~ staging_use_flags_regexp)) {
				suppress_current_line=1
				staging_if_open=1
			}
			else if (staging_if_open) {
				if ($0 ~ else_regexp)
					staging_else_open=1
				if (staging_else_open)
					suppress_current_line=1
				else
					sub(indent, "")
				if ($0 ~ if_close_regexp)
					staging_if_open=staging_else_open=0
			}
		}
		sub(text2regexp("${*}"), "\"&\"")
	}
	else if (array_phase_open["src_unpack"]) {
		if (if_check_pv9999_open) {
			suppress_current_line=1
			if (!do_git_unpack_replaced) {
				print_src_unpack_live_ebuild_support(indent, is_wine_version_staging_supported)
				do_git_unpack_replaced=1
			}
		}
		if (!if_check_pv9999_open && (($0 ~ text2regexp("^ unpack ")) || ($0 ~ text2regexp("^ use * && unpack "))))
			suppress_current_line=1
	}
	else if (array_phase_open["src_prepare"]) {
		if ($0 ~ text2regexp("md5sum*server/protocol.def")) {
			suppress_current_line=1
			if (!md5sum_count)
				printf("%s%s\n", indent, "local md5hash=\"$(md5sum server/protocol.def || die \"md5sum\")\"")
			else
				printf("%s%s\n", indent, "if ! $(md5sum -c - <<<\"${md5hash}\" &>/dev/null); then")
			++md5sum_count
		}

		if ($0 ~ text2regexp("^ local PATCHES=("))
			patch_set_define_open=1
		if (patch_set_define_open) {
			if (($0 ~ text2regexp("multilib-portage.patch")) || ($0 ~ text2regexp("${WORKDIR}/${GST_P}.patch")))
				suppress_current_line=1
			if (is_wine_version_no_sysmacros_patch && ($0 ~ text2regexp("sysmacros.patch")))
				suppress_current_line=1
			if (is_wine_version_no_gnutls_patch && ($0 ~ text2regexp("gnutls-3.5-compat.patch")))
				suppress_current_line=1
		}
		if (($0 ~ if_open_regexp) && ($0 ~ text2regexp("use staging")))
			wine_staging_check_open=if_stack
		if (wine_staging_check_open == 1) {
			if ($0 ~ text2regexp("eend $?"))
				sub(text2regexp("die \"*\"$"), "die \"(subshell) script: failed to apply Wine-Staging patches.\"")
			if (is_wine_version_staging_eapply_supported)
				gsub("epatch", "eapply")
		}
		if (is_wine_version_staging_supported) {
			if ((wine_staging_check_open == 1) && ($0 ~ if_close_regexp) && (wine_version !~ wine_staging_official_regexp)) {
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
	else if (array_phase_open["multilib_src_install_all"]) {
		if (($0 ~ if_open_regexp) && (($0 ~ text2regexp("use gecko") || ($0 ~ text2regexp("use mono")))))
			gv_or_mv_if_open=1
		if (gv_or_mv_if_open) {
			sub(text2regexp("\"${DISTDIR}\""), "${DISTDIR}")
			sub(text2regexp("${DISTDIR}*$"), "\"&\"")
			if ($0 ~ if_close_regexp)
				gv_or_mv_if_open=0
		}
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
		if (($0 ~ array_variables_regexp["STAGING_DIR"]) && is_wine_version_staging_supported)
			printf("%s\n", ("STAGING_HELPER=\"" wine_staging_helper "\""))

		depend_assignment_open=depend_assignment_open && ($0 !~ end_quote_regexp)
	}

	# Ebuild phase based post-checks
	if (array_phase_open["wine_compiler_check"] && ($0 ~ text2regexp("^ [[ ${MERGE_TYPE} = \"binary\" ]]"))) {
		wine_compiler_check_tests_open=1
		if (!builtin_ms_va_list_pretest) {
			builtin_ms_va_list_pretest=1
			print_builtin_ms_va_list_pretest(indent)
		}
	}
	else if (array_phase_open["pkg_pretend"] && wine_build_environment_prechecks) {
		printf("%s%s\n", indent, "wine_gcc_specific_pretests || die")
		printf("%s%s\n", indent, "wine_generic_compiler_pretests || die")
		printf("%s%s\n", indent, "wine_build_environment_prechecks || die")
		wine_build_environment_prechecks=0
	}
	else if (array_phase_open["pkg_setup"] && wine_build_environment_prechecks) {
		printf("%s%s\n\n", indent, "wine_build_environment_prechecks || die")
		wine_build_environment_prechecks=0
	}
	else if (array_phase_open["src_prepare"]) {
		if (patch_set_define_open && ($0 ~ (bracketed_expression_close_regexp "$"))) {
			print_src_prepare_live_build_patch_support(indent, is_wine_version_legacy_gstreamer_patch)
			patch_set_define_open=0
		}
		if (is_wine_version_staging_supported && ((wine_version == "1.9.5") && ($0 ~ text2regexp("^ use pipelight"))))  {
			printf("%s%s%s\n",		indent, indent, ("#577198 only affects " wine_version))
			printf("%s%s%s\n",		indent, indent, "use nls || STAGING_EXCLUDE=\"${STAGING_EXCLUDE} -W makefiles-Disabled_Rules\"")
		}
	}


	if (if_check_pv9999_open && (if_check_pv9999_open == if_stack+1) && ($0 ~ if_close_regexp))
		if_check_pv9999_open=else_check_pv9999_open=0

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
