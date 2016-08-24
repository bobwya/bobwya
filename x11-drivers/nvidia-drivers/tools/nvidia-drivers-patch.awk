# !/bin/awk

function print_nvidia_kernel_warning_message(indent)
{
	printf("%s%s%s\n",		indent,	indent,	"elif use kms && kernel_is le 4 1; then")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"NVIDIA does not fully support kernel modesetting on\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"on the following kernels:\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"<sys-kernel/gentoo-sources-4.2\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"<sys-kernel/vanilla-sources-4.2\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn")
	if (is_nvidia_supported_kms) {
		printf("%s%s%s\n",		indent,	indent,	"elif use kms; then")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "einfo \"USE +kms: checking kernel for KMS CONFIG recommended by NVIDIA.\"")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "einfo")
		printf("%s%s%s%s\n",	indent,	indent,	indent, "CONFIG_CHECK+=\" ~DRM_KMS_HELPER ~DRM_KMS_FB_HELPER\"")
	}
	printf("%s%s%s\n",		indent,	indent,	"fi")
}

function print_unofficial_linux_patch_warning_message(indent, array_supported_kernels,
		i_kernel)
{
	if (! (0 in array_supported_kernels))
		return 0
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"This version of ${CATEGORY}/${PN} has an unofficial patch\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "ewarn \"applied to enable support for the following kernels:\"")
	for (i_kernel=1; i_kernel<=array_supported_kernels[0]; ++i_kernel) {
		sub("^[<>=]+", "=", array_supported_kernels[i_kernel])
		printf("%s%s%s%s\n",	indent,	indent,	indent, ("ewarn \"" array_supported_kernels[i_kernel] "\""))
	}
	return 1
}

function print_nvidia_kms_kernel_modules(indent)
{
	printf("%s%s%s\n",		indent,	indent,	"if use kms; then")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "MODULE_NAMES+=\" nvidia-modeset(video:${S}/kernel)\"")
	printf("%s%s%s%s\n",	indent,	indent,	indent, "MODULE_NAMES+=\" nvidia-drm(video:${S}/kernel)\"")
	printf("%s%s%s\n",		indent,	indent,	"fi")
}

function print_experimental_warning_message(indent)
{
	printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix\"")
	printf("%s%s\n", indent, "ewarn \"issues when switching GL providers.\"")
	printf("%s%s\n", indent, "ewarn \"This package should only be used in conjuction with patched versions of:\"")
	printf("%s%s\n", indent, "ewarn \" * app-select/eselect-opengl\"")
	printf("%s%s\n", indent, "ewarn \" * media-libs/mesa\"")
	printf("%s%s\n", indent, "ewarn \" * x11-base/xorg-server\"")
	printf("%s%s\n", indent, "ewarn \"from the bobwya overlay.\"")
	printf("%s%s\n", indent, "ewarn")
}

BEGIN{
	setup_ebuild_phases("pkg_pretend pkg_setup src_prepare src_compile src_install src_install-libs pkg_preinst pkg_postinst pkg_prerm pkg_postrm",
						array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)

	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="CONFIG_CHECK KEYWORDS QA_TEXTRELS_x86 QA_TEXTRELS_x86_fbsd QA_TEXTRELS_amd64 QA_EXECSTACK_x86 QA_EXECSTACK_amd64 QA_WX_LOAD_x86 QA_WX_LOAD_amd64 QA_FLAGS_IGNORED_amd64 QA_FLAGS_IGNORED_x86"
	setup_global_regexps(variables)
	nvidia_specific_lib_regexp="lib[\\-\\_[:alnum:]]*nvidia[\\-\\_[:alpha:]]*\\.so"
	syskernel_regexp="sys\\-kernel\\/[\\-[:alpha:]]+[\\.[:digit:]]+(|\\-r[[:digit:]]+)"
	is_nvidia_supported_kms=(nvidia_version ~ convert_version_list_to_regexp(nvidia_supported_kms_versions))
	is_nvidia_unofficial_linux_kernel_patch=(nvidia_version ~ convert_version_list_to_regexp(nvidia_unofficial_linux_kernel_patch_versions))
}
{
	suppress_current_line=0
	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	# Comment trailing die commands...
	sub(text2regexp("||die"), "|| die")
	# Add current line to array of lines - so get_associated_command() function can access it!!
	array_ebuild_file[ebuild_line+1]=$0
	if (($0 ~ text2regexp(" die( #*|)$",1)) && ((command=get_associated_command(array_ebuild_file, ebuild_line+1)) != ""))
		sub(text2regexp(" die$"), (" die \"" command "\"")) || sub(text2regexp(" die #"), (" die \"" command "\" #"))

	if (!preamble_over) {
		if ($0 ~ gentoo_copyright_header_regexp)
			sub("[[:digit:]]{4}\\-[[:digit:]]{4}", "1999-2016")
		if ($0 ~ array_variables_regexp["EAPI"])
			sub("5", "6") || sub("\"5\"", "6")

		sub(text2regexp("/usr/$(get_libdir)/opengl/nvidia/extensions"), "/usr/$(get_libdir)/xorg/nvidia/extensions")

		# Change dependency on app-eselect/eselect_opengl to an out-of-tree, patched version
		if ($0 ~ text2regexp("^ (<|<=|=|>=|>)app-eselect/eselect-opengl",1)) {
			sub(package_version_regexp, ("-" eselect_opengl_supported_version))
			sub(/>=/, "=")
		}

		# Mark all converted ebuilds as unstable
		if ($0 ~ array_variables_regexp["KEYWORDS"])
			gsub(keyword_regexp, "~&") && gsub(text2regexp("~~"), "~")
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)) {
		preamble_over=1
		target_block_open=0
	}

	# Ebuild phase based pre-checks
	if (array_phase_open["pkg_pretend"]) {
		sub(text2regexp("[ \"${DEFAULT_ABI}\" != \"amd64\" ]"), "[&]")
		if (!kernel_linux_block_open && ($0 ~ if_open_regexp) && ($0 ~ text2regexp("use kernel_linux")) && (if_stack == 1)) {
			kernel_linux_block_open=1
			if (is_nvidia_supported_kms)
				printf("%s%s\n", indent, "CONFIG_CHECK=\"\"")
			printf("%s%s\n", indent, "if use kernel_linux; then")
			sub(text2regexp("use kernel_linux && "), "")
			sub(("^" indent), (indent indent))
		}
		else if (kernel_linux_block_open == 1) {
			if ($0 ~ text2regexp("^ ewarn \"\""))
				++kernel_linux_block_open
			else {
				sub(("^" indent), (indent indent))
				match($0, ("<" syskernel_regexp))
				if (RSTART)
					array_supported_kernels[++array_supported_kernels[0]]=substr($0, RSTART, RLENGTH)
			}
		}
		if (kernel_linux_block_open == 2) {
			if ($0 !~ text2regexp("^ ewarn")) {
				if (is_nvidia_unofficial_linux_kernel_patch)
					print_unofficial_linux_patch_warning_message(indent, array_supported_kernels)
				++kernel_linux_block_open
			}
			else
				suppress_current_line=1
		}
		if (kernel_linux_block_open == 3) {
			print_nvidia_kernel_warning_message(indent)
			++kernel_linux_block_open
		}
		if (is_nvidia_supported_kms && (kernel_linux_block_open == 4) && ($0 ~ array_variables_regexp["CONFIG_CHECK"])) {
			sub("=\"", "+=\" ")
			#++kernel_linux_block_open
		}
	}
	else if (is_nvidia_supported_kms && (array_phase_open["pkg_setup"] == 1) && ($0 ~ text2regexp("^ use kms"))) {
		# keep repoman happy!
		print_nvidia_kms_kernel_modules(indent)
		suppress_current_line=1
		++array_phase_open["pkg_setup"]
	}
	else if (array_phase_open["src_prepare"]) {
		if (local_patches_declared) {
			if ($0 ~ text2regexp("^ (epatch|eapply) *.patch",1)) {
				patch=$0
				gsub(text2regexp("(^ (epatch|eapply) |.patch*)",1), "", patch) && sub(text2regexp("(epatch|eapply) (*.patch)",1), ("PATCHES+=( " patch ".patch )"))
			}
		}
		else if ($0 ~ if_open_regexp) {
			printf("%s%s\n", indent,	"local PATCHES")
			local_patches_declared=1
		}
		else if ($0 ~ text2regexp("^ (epatch|eapply) *.patch",1)) {
			patch=$0
			gsub(text2regexp("(^ (epatch|eapply) |.patch*)",1), "", patch) && sub(text2regexp("(epatch|eapply) (*.patch)",1), ("local PATCHES=( " patch ".patch )"))
			local_patches_declared=1
		}
		sub(text2regexp("(eapply_user|epatch_user)",1), "default")
	}
	else if (array_phase_open["src_install"]) {
		sub(text2regexp("/usr/$(get_libdir)/opengl/nvidia/extensions"), "/usr/$(get_libdir)/xorg/nvidia/extensions")
		if (($0 ~ if_open_regexp) && ($0 ~ text2regexp("has_version *x11-base/xorg-server")) && (if_stack == 2)) {
			has_version_xorg_server_open=1
			suppress_current_line=1
		}
		if (has_version_xorg_server_open) {
			sub("\\t", "")
			if ($0 ~ if_close_regexp) {
				suppress_current_line=1
				has_version_xorg_server_open=0
			}
		}
	}
	else if (array_phase_open["src_install-libs"]) {
		if_use_X_open=if_use_X_open || (($0 ~ (if_open_regexp text2regexp("use X"))) && (if_stack == 1))
		if (if_use_X_open) {
			if ($0 ~ text2regexp("^ NV_GLX_LIBRARIES(+|)=",1))
				nvidia_glx_libraries_variable_open=1
			donvidia_call_open=donvidia_call_open || ($0 ~ text2regexp("^ donvidia"))
		}
		if (($0 ~ nvidia_specific_lib_regexp) && (nvidia_glx_libraries_variable_open || donvidia_call_open)) {
			sub(gl_root_regexp, "")
		}
		if ($0 ~ end_quote_regexp)
			donvidia_call_open=0
		if ($0 ~ closing_bracket_regexp)
			nvidia_glx_libraries_variable_open=0
		if (($0 ~ if_close_regexp) && (if_stack == 1))
			if_use_X_open=0
	}
	else if (array_phase_open["pkg_postinst"] &&  ($0 ~ end_curly_bracket_regexp)) {
		print_experimental_warning_message(indent)
	}
	if (array_phase_open["pkg_prerm"] || array_phase_open["pkg_postrm"]) {
		if ($0 ~ text2regexp("eselect opengl"))
			sub(text2regexp("xorg-x11"), "mesa")
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
		indent=(indent == 0) ? substr($0, RSTART, RLENGTH) : indent


	# Ebuild phase based post-checks
	if (array_phase_open["src_prepare"] && !nvidia_kernel_patch && is_nvidia_unofficial_linux_kernel_patch) {
		if (nvidia_version ~ text2regexp("367.*")) {
			printf("%s%s\n", indent,	"local PATCHES=( \"${FILESDIR}/${PN}-367.18-kernel-4.7.0.patch\" )")
			nvidia_kernel_patch=1
			local_patches_declared=1
		}
	}

	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
