function print_pkg_pretend_build_path_warning(indent)
{
	printf("%s%s\n",	indent, "if [[ ${#BUILD_OBJ_DIR} -gt ${MAX_OBJ_DIR_LEN} ]]; then")
	printf("%s%s%s\n",	indent, indent, "ewarn \"Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:\"")
	printf("%s%s%s\n",	indent, indent, "ewarn \" ... \\\"${BUILD_OBJ_DIR}\\\"\"")
	printf("%s%s\n", 	indent, "fi")
}


function print_kde_patchset_src_fetch(indent)
{
	printf("%s%s\n",	indent, "if use kde; then")
	printf("%s%s%s\n",	indent, indent, "if [[ ${MOZ_PV} =~ ^\(10|17|24\)\\..*esr$ ]]; then")
	printf("%s%s%s%s\n",indent, indent, indent, "EHG_REVISION=\"esr${MOZ_PV%%.*}\"")
	printf("%s%s%s\n",	indent, indent, "else")
	printf("%s%s%s%s\n",indent, indent, indent, "EHG_REVISION=\"firefox${MOZ_PV%%.*}\"")
	printf("%s%s%s\n",	indent, indent, "fi")
	printf("%s%s%s\n",	indent, indent, "KDE_PATCHSET=\"firefox-kde-patchset\"")
	printf("%s%s%s\n",	indent, indent, "EHG_CHECKOUT_DIR=\"${WORKDIR}/${KDE_PATCHSET}\"")
	printf("%s%s%s\n",	indent, indent, "mercurial_fetch \"${EHG_REPO_URI}\" \"${KDE_PATCHSET}\"")
	printf("%s%s\n",	indent, "fi")
}


function print_kde_patchset_src_prepare(indent)
{
	printf("%s%s\n", 	indent, "if use kde; then")
	printf("%s%s%s\n", 	indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset")
	printf("%s%s%s\n", 	indent, indent,	 "eapply \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\"")
	printf("%s%s%s\n", 	indent, indent,	 "eapply \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\"")
	printf("%s%s%s\n",  indent, indent,  "# Uncomment the next line to enable KDE support debugging (additional console output)...")
	printf("%s%s%s\n",  indent, indent,  "#PATCHES+=( \"${FILESDIR}/${PN}-kde-debug.patch\" )")
	printf("%s%s%s\n",  indent, indent,  "# Uncomment the following patch line to force Plasma/Qt file dialog for Thunderbird...")
	printf("%s%s%s\n",  indent, indent,  "#PATCHES+=( \"${FILESDIR}/${PN}-force-qt-dialog.patch\" )")
	printf("%s%s%s\n",  indent, indent,  "# ... _OR_ install the patch file as a User patch (/etc/portage/patches/mail-client/thunderbird-kde-opensuse/)")
	printf("%s%s\n", 	indent, "fi")
	printf("%s%s\n",	indent, "# Apply our patchset from firefox to thunderbird as well")
	if ((thunderbird_version == "24.8.0") || (thunderbird_version == "31.8.0") || (thunderbird_version == "38.7.0") || (thunderbird_version == "38.8.0")) {
		printf("%s%s\n", 	indent, "ebegin \"(subshell): correct EAPI 6 firefox patchset compliance (hack)\"")
		printf("%s%s\n", 	indent, "(")
		printf("%s%s%s\n", 	indent, indent,	 "source \"${FILESDIR}/${PN}-fix-patch-eapi6-support.sh\" \"${PV}\" \"${WORKDIR}/firefox\" || die")
		printf("%s%s\n", 	indent, ")")
		printf("%s%s\n", 	indent, "eend $? || die \"(subshell): failed to correct EAPI 6 firefox patchset compliance\"")
	}
	printf("%s%s\n",	indent, "eapply \"${WORKDIR}/firefox\"")
}


function print_pkg_postinst_cursor_warning(indent)
{
	printf("%s%s\n", 	indent, "if [[ $(get_major_version) -ge 40 ]]; then")
	printf("%s%s%s\n", indent, indent, "# See https://forums.gentoo.org/viewtopic-t-1028874.html")
	printf("%s%s%s\n", indent, indent, "ewarn \"If you experience problems with your cursor theme - only when mousing over ${PN}.\"")
	printf("%s%s%s\n", indent, indent, "ewarn \"See:\"")
	printf("%s%s%s\n", indent, indent, "ewarn \"  https://forums.gentoo.org/viewtopic-t-1028874.html\"")
	printf("%s%s%s\n", indent, indent, "ewarn \"  https://wiki.gentoo.org/wiki/Cursor_themes\"")
	printf("%s%s%s\n", indent, indent, "ewarn \"  https://wiki.archlinux.org/index.php/Cursor_themes\"")
	printf("%s%s%s\n", indent, indent, "ewarn")
	printf("%s%s\n", 	indent, "fi")
}



BEGIN{
	kde_use_flag="kde"
	ebuild_package_version=("mail-client/" ebuild_file)
	sub("\.ebuild$", "", ebuild_package_version)
	PN="thunderbird-kde-opensuse"
	MOZ_PN="thunderbird"
	thunderbird_major_version=thunderbird_version
	gsub(text2regexp(".*$"), "", thunderbird_major_version)
	# Setup some regular expression constants - to hopefully make the script more readable(ish)!
	variables="BUILD_OBJ_DIR DESCRIPTION EAPI EPATCH_EXCLUDE EPATCH_FORCE EPATCH_SUFFIX KEYWORDS HOMEPAGE IUSE MOZ_HTTP_URI MOZ_PV PATCHFF RDEPEND"
	setup_global_regexps(variables)
	ebuild_phases="pkg_setup pkg_pretend src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
	setup_ebuild_phases(ebuild_phases, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	keywork_unsupported_regexp="[\~]{0,1}(alpha|arm|ppc|ppc64)"
	mozconfig_version_regexp="^.+mozconfig\\-v([\\.[:digit:]]+).*$"
}
{
	suppress_current_line=0

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	# Make ebuild's use consistent spacing/layout throughout...
	if (($0 ~ text2regexp("^if")) || ($0 ~ text2regexp("^ if"))) {
		sub(text2regexp(" ; then$"), "; then")
		if ($0 ~ text2regexp(" ; then #*$"))
			sub(text2regexp(" ; then"), "; then ")
	}

	# Comment trailing die commands...
	sub(text2regexp("||die"), "|| die")
	if (($0 ~ text2regexp(" die$")) || ($0 ~ text2regexp(" die #*$"))) {
		# Add current line to array of lines - so get_associated_command() function can access it!!
		array_ebuild_file[ebuild_line+1]=$0
		command=get_associated_command(array_ebuild_file, ebuild_line+1)
		if ((command != "") && !sub(text2regexp(" die$"), (" die \"" command " failed\"")))
			sub(text2regexp(" die #"), (" die \"" command " failed\"  #"))
	}

	# Alter current ebuild line before it is printed
	if (!preamble_over) {
		if ($0 ~ text2regexp("^# "))
			sub("Copyright 1999\-[[:digit:]]{4} Gentoo Foundation", "Copyright 1999-2016 Gentoo Foundation")

		if ($0 ~ text2regexp("^EAPI="))
			sub("(\"){0,1}5(\"){0,1}", 6)

		# Alter current ebuild line before it is printed
		if ($0 ~ array_variables_regexp["PATCHFF"]) {
			patch_version=gensub("^.+\"firefox\-([\.[:digit:]]+)\-patches.+\"$", "\\1", 1, $1)
		}
		else if ($0 ~ array_variables_regexp["IUSE"]) {
			for (ifield=2; ifield<=NF; ++ifield) {
				field=gensub(/^[\"\+\-]+/, "", "g", $ifield)
				if (field > kde_use_flag)
					break
			}
			if (ifield == NF+1)
				sub(/$/, (" " kde_use_flag), $NF)
			else
				sub(/^/, (kde_use_flag " "), $ifield)
		}
		else if ($0 ~ array_variables_regexp["KEYWORDS"]) {
			for (ifield=1; ifield<=NF; ++ifield) {
				gsub(keywork_unsupported_regexp, "", $ifield)
			}
			gsub(/(\"[ ]+|[ ]+\")/, "\"")
			gsub(/[ ]+/, " ")
		}
		else if ($0 ~ text2regexp("^inherit ")) {
			$0=$0 " mercurial"
			mozconfig_version=gensub(mozconfig_version_regexp, "\\1", 1, $0)
			gsub("(\"| )moz(config|coreconf|linguas)", "&-kde")
		}
		else if ($0 ~ array_variables_regexp["DESCRIPTION"]) {
			sub(/\".+\"/, "\"Thunderbird Mail Client, with SUSE patchset, to provide better KDE integration\"")
		}
		else if (!moz_pn_defined && ($0 ~ array_variables_regexp["MOZ_PV"])) {
			print ("MOZ_PN=\"" MOZ_PN "\"")
			moz_pn_defined=1
		}

		# Process initial variables
		if ($0 ~ array_variables_regexp["RDEPEND"])
			rdepend_open=1
		else if ($0 ~ array_variables_regexp["HOMEPAGE"])
			homepage_open=1
		if ($0 ~ end_quote_regexp) {
			if (rdepend_open) {
				sub(end_quote_regexp, "", $0)
				rdepend_open=0
				rdepend_close=1
				suppress_current_line=($0 ~ blank_line_regexp) ? 1 : 0
			}
			else if (homepage_open) {
				sub(end_quote_regexp, "", $0)
				homepage_open=0
				homepage_close=1
				suppress_current_line=($0 ~ blank_line_regexp) ? 1 : 0
			}
		}
	}

	# Ebuild phase process opening stanzas for functions
	if (process_ebuild_phase_open($0, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)) {
		preamble_over=1
		if_stack=0
		target_block_open=0
	}

	# Ebuild phase based pre-checks
	if (array_phase_open["src_prepare"]) {
		gsub(/modifing/, "modifying", $0)
		if (($0 ~ array_variables_regexp["EPATCH_EXCLUDE"]) ||
			($0 ~ array_variables_regexp["EPATCH_FORCE"])   ||
			($0 ~ array_variables_regexp["EPATCH_SUFFIX"]))
			epatch_variable_open=1
		if (epatch_variable_open) {
			suppress_current_line=1
			epatch_variable_open=($0 !~ end_quote_regexp)
		}
		if ($0 ~ text2regexp("^ (epatch|eapply) \"${WORKDIR}/firefox\"",1))
			suppress_current_line=1
		if ($0 ~ text2regexp("^ (epatch|eapply) \"${WORKDIR}/thunderbird\"",1)) {
			printf("%s%s\n", indent, "# Default to our patchset")
			sub(text2regexp("(epatch|eapply) \"${WORKDIR}/thunderbird\"",1), "local PATCHES=( \"${WORKDIR}/thunderbird\" )")
			local_patches_open=1
		}
		if (($0 ~ text2regexp("^( |)# Apply our (patchset from firefox to thunderbird as well|Thunderbird patchset)",2)) ||
			($0 ~ text2regexp("^( |)# Allow user to apply any additional patches without modifying ebuild",2)))
			suppress_current_line=1
		if (pushd_mozilla_open && ! popd_mozilla) {
			if ((if_stack == 1) && ($0 ~ text2regexp("if [[ $(gcc-major-version) -ge 5 ]]; then")))
				gcc_check_open=1
			if (gcc_check_open) {
				suppress_current_line=1
				gcc_check_open=((if_stack == 0) && ($0 ~ if_close_regexp)) ? 0 : 1
			}
			if ($0 ~ text2regexp("^ popd &>/dev/null")) {
				pushd_mozilla_open=0
				popd_mozilla=1
			}
		}
		if (($0 ~ text2regexp("^ (eapply|epatch)*${FILESDIR}*.patch",1)) && ($0 !~ text2regexp(PN))) {
			gsub(MOZ_PN, "${PN}")
			if (pushd_mozilla_open)
				sub(text2regexp("epatch "), "eapply ")
			else
				sub(text2regexp("epatch "), "PATCHES+=( ") && sub("$", " )")
		}
		if ((if_stack == 1) && ($0 ~ text2regexp("^ if use crypt")))
			crypt_test_open=1
		if (crypt_test_open) {
			if ($0 ~ text2regexp("^ (pushd|popd)",1))
				suppress_current_line=1
			sub(text2regexp("(eapply|epatch) \"${FILESDIR}\"/enigmail-1.6.0-parallel-fix.patch",1), "PATCHES+=( \"${FILESDIR}/${PN}-enigmail-1.6.0-parallel-fix.patch\" )")
			crypt_test_open=((if_stack == 0) && ($0 ~ if_close_regexp)) ? 0 : 1
		}
		sub(text2regexp("(eapply_user|epatch_user)",1), "default")
	}
	else if (array_phase_open["src_unpack"]) {
		sub(text2regexp("unpack ${A}"), "default")
	}
	else if (array_phase_open["src_configure"]) {
		if ($0 ~ text2regexp("^# Use an objdir to keep things organized.")) {
			gsub("\.[[:blank:]]*$", " and force build of Thunderbird mail application.")
		}
		else if ($0 ~ text2regexp("^ echo \"mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/tbird\"")) {
			printf("%s%s\n", 	indent, "sed -i -e \"\\\$amk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}\" \\")
			printf("%s%s%s\n", 	indent, indent, "-e '\''1i\\'\''\"mk_add_options MOZ_CO_PROJECT=mail\" \\")
			printf("%s%s%s\n", 	indent, indent, "-e '\''1i\\'\''\"ac_add_options --enable-application=mail\" \"${S}\"/.mozconfig")
			suppress_current_line=1
		}
	}

	# Convert internal references to "thunderbird-kde-opensuse" (PN) to "thunderbird" (MOZ_PN) - but not for user messages or local patches!
	if (($0 !~ ebuild_message_regexp) && ($0 !~ text2regexp("^ (PATCHES+=|eapply|epatch)*${FILESDIR}*.patch",1)))
		gsub(/\$\{PN\}/, "${MOZ_PN}")

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
		if (rdepend_close) {
			printf("%s%s\n", indent, "kde? ( kde-misc/kmozillahelper )")
			printf("%s%s\n", indent, "!!mail-client/thunderbird\"")
			rdepend_close=0
		}
		else if ($0 ~ array_variables_regexp["MOZ_HTTP_URI"]) {
			printf("\n%s\n%s\n",
					"# Mercurial repository for Mozilla Firefox patches to provide better KDE Integration (developed by Wolfgang Rosenauer for OpenSUSE)",
					"EHG_REPO_URI=\"http://www.rosenauer.org/hg/mozilla\"")
		}
		else if (homepage_close) {
			printf("%s${EHG_REPO_URI}\"\n", indent)
			homepage_close=0
		}
		if ($0 ~ array_variables_regexp["BUILD_OBJ_DIR"]) {
			printf("MAX_OBJ_DIR_LEN=\"80\"\n")
			shorten_build_object_path=1
		}
	}

	# Ebuild phase based post-checks
	if (array_phase_open["pkg_setup"] && (mozconfig_version+0.0 >= 6.45) && ($0 ~ text2regexp("^ export MOZILLA_DIR=\"*\"$"))) {
		printf("%s%s\n",	indent, "export MOZILLA_FIVE_HOME=\"${MOZILLA_FIVE_HOME/${PN}/${MOZ_PN}}\"")
	}
	if (array_phase_open["src_unpack"] && ($0 ~ text2regexp("^ mozlinguas_src_unpack"))) {
		print_kde_patchset_src_fetch(indent)
	}
	else if (array_phase_open["pkg_pretend"] && shorten_build_object_path) {
		print_pkg_pretend_build_path_warning(indent)
		shorten_build_object_path=0
	}
	else if (array_phase_open["src_prepare"]) {
		if (local_patches_open) {
			if (patch_version < 42.0) {
				printf("%s%s\n", indent, "# Add patch for https://bugzilla.redhat.com/show_bug.cgi?id=966424")
				printf("%s%s\n", indent, "PATCHES+=( \"${FILESDIR}/${PN}-rhbz-966424.patch\" )")
			}
			if (thunderbird_major_version == 31) {
				printf("%s%s\n", indent, "[[ $(gcc-major-version) -ge 5 ]] && PATCHES+=( \"${FILESDIR}/${PN}-31.7.0-gcc5.1.patch\" )")
			}
			if (thunderbird_major_version <= 31) {
				printf("%s%s\n", indent, "# Add patch for https://bugzilla.mozilla.org/show_bug.cgi?id=1143411")
				printf("%s%s\n", indent, "PATCHES+=( \"${FILESDIR}/${PN}-31.8.0-buildfix-ft-master.patch\" )")
			}
			local_patches_open=0
		}
		pushd_mozilla_open=pushd_mozilla_open || ($0 ~ text2regexp("^ pushd \"${S}\"/mozilla"))
		if (!kde_patchset_done && (pushd_mozilla_open == 1)) {
			print_kde_patchset_src_prepare(indent)
			kde_patchset_done=1
		}
	}
	else if (array_phase_open["pkg_postinst"] == 1) {
		print_pkg_postinst_cursor_warning(indent)
		++array_phase_open["pkg_postinst"]
	}


	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}
