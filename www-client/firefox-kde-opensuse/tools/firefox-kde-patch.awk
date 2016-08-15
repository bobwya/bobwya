function print_pkg_pretend_build_path_warning(indent)
{
	printf("%s%s\n",	indent, "if [[ ${#BUILD_OBJ_DIR} -gt ${MAX_OBJ_DIR_LEN} ]]; then")
	printf("%s%s%s\n",	indent, indent, "ewarn \"Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:\"")
	printf("%s%s%s\n",	indent, indent, "ewarn \" ... \\\"${BUILD_OBJ_DIR}\\\"\"")
	printf("%s%s\n", 	indent, "fi")
}

function print_kde_patchset_src_fetch(indent, mozconfig_version)
{
	if (mozconfig_version+0.0 >= 6.45)
		printf("%s%s\n",	indent, "export MOZILLA_FIVE_HOME=\"${MOZILLA_FIVE_HOME/${PN}/${MOZ_PN}}\"")
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
	if (firefox_version == "38.8.0") {
		printf("%s%s\n", 	indent, "ebegin \"(subshell): correct EAPI 6 firefox patchset compliance (hack)\"")
		printf("%s%s\n", 	indent, "(")
		printf("%s%s%s\n", 	indent, indent,	 "source \"${FILESDIR}/${PN}-fix-patch-eapi6-support.sh\" \"${PV}\" \"${WORKDIR}/firefox\" || die")
		printf("%s%s\n", 	indent, ")")
		printf("%s%s\n", 	indent, "eend $? || die \"(subshell): failed to correct EAPI 6 firefox patchset compliance\"")
	}
	printf("%s%s\n", 	indent, "# Default to our patchset")
	printf("%s%s\n", 	indent, "local PATCHES=( \"${WORKDIR}/firefox\" )")
	printf("%s%s\n", 	indent, "if use kde; then")
	printf("%s%s%s\n", 	indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset")
	printf("%s%s%s\n", 	indent, indent,	 "if [[ $(get_major_version) -lt 42 ]]; then")
	printf("%s%s%s%s\n", indent, indent, indent, "PATCHES+=( \"${EHG_CHECKOUT_DIR}/toolkit-download-folder.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "fi")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/mozilla-language.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "if [[ $(get_major_version) -lt 39 ]]; then")
	printf("%s%s%s%s\n", indent, indent, indent, "PATCHES+=( \"${EHG_CHECKOUT_DIR}/mozilla-prefer_plugin_pref.patch\" )")
	printf("%s%s%s\n",	indent, indent,  "fi")
	printf("%s%s%s\n",	indent, indent,	 "# Firefox OpenSUSE KDE integration patchset")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/firefox-branded-icons.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/firefox-kde.patch\" )")
	printf("%s%s%s\n", 	indent, indent,	 "PATCHES+=( \"${EHG_CHECKOUT_DIR}/firefox-no-default-ualocale.patch\" )")
	printf("%s%s%s\n",  indent, indent,  "# Uncomment the next line to enable KDE support debugging (additional console output)...")
	printf("%s%s%s\n",  indent, indent,  "#PATCHES+=( \"${FILESDIR}/firefox-kde-opensuse-kde-debug.patch\" )")
	printf("%s%s%s\n",  indent, indent,  "# Uncomment the following patch line to force Plasma/Qt file dialog for Firefox...")
	printf("%s%s%s\n",  indent, indent,  "#PATCHES+=( \"${FILESDIR}/firefox-kde-opensuse-force-qt-dialog.patch\" )")
	printf("%s%s%s\n",  indent, indent,  "# ... _OR_ install the patch file as a User patch (/etc/portage/patches/www-client/firefox-kde-opensuse/)")
	printf("%s%s%s\n",  indent, indent,  "# ... _OR_ add to your user .xinitrc: \"xprop -root -f KDE_FULL_SESSION 8s -set KDE_FULL_SESSION true\"")
	printf("%s%s\n", 	indent, "fi")
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

function print_pkg_postinst_electrolysis_info(indent)
{
	printf("%s%s\n",        indent, "if [[ $(get_major_version) -ge 47 ]]; then")
	printf("%s%s%s\n",      indent, indent, "einfo \"To enable experimental Electrolysis (e10s) support for ${PN}...\"")
	printf("%s%s%s\n",      indent, indent, "einfo \"  browse to: \\\"about:config\\\" page\"")
	printf("%s%s%s\n",      indent, indent, "einfo \"  add entry: \\\"browser.tabs.remote.force-enable = true\\\"\"")
	printf("%s%s%s\n",      indent, indent, "einfo")
	printf("%s%s\n",        indent, "fi")
}

BEGIN{
	kde_use_flag="kde"
	ebuild_package_version=("www-client/" ebuild_file)
	gsub("\.ebuild$", "", ebuild_package_version)

	# Setup some regular expression constants - to hopefully make the script more readable!
	variables="BUILD_OBJ_DIR DESCRIPTION EAPI EPATCH_EXCLUDE EPATCH_FORCE EPATCH_SUFFIX HOMEPAGE KEYWORDS IUSE MOZ_HTTP_URI MOZ_PV QA_PRESTRIPPED RDEPEND"
	setup_global_regexps(variables)
	ebuild_phases="pkg_setup pkg_pretend src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
	setup_ebuild_phases(ebuild_phases, array_ebuild_phases, array_phase_open, array_ebuild_phases_regexp)
	keyword_unsupported_regexp="[\~]{0,1}(alpha|arm64|arm|hppa|ppc|ppc64)"
	mozconfig_version_regexp="^.+mozconfig\\-v([\\.[:digit:]]+).*$"
}
{
	suppress_current_line=0

	if_stack+=($0 ~ if_open_regexp) ? 1 : 0
	if_stack+=($0 ~ if_close_regexp) ? -1 : 0

	# Make ebuild's use consistent spacing/layout throughout...
	if ($0 ~ text2regexp("^( |)if",1)) {
		sub(text2regexp(" ; then$"), "; then")
		if ($0 ~ text2regexp(" ; then #*$"))
			sub(text2regexp(" ; then"), "; then ")
	}

	# Comment trailing die commands...
	if ($0 ~ text2regexp(" die(| #*)$",1)) {
		# Add current line to array of lines - so get_associated_command() function can access it!!
		array_ebuild_file[ebuild_line+1]=$0
		command=get_associated_command(array_ebuild_file, ebuild_line+1)
		if (command != "")
			sub(text2regexp(" die$"), (" die \"" command " failed\"")) || sub(text2regexp(" die #"), (" die \"" command " failed\"  #"))
	}

	# Alter current ebuild line before it is printed
	if (!preamble_over) {
		if ($0 ~ array_variables_regexp["EAPI"])
			sub("[\"]5[\"]", 6)

		if ($0 ~ array_variables_regexp["IUSE"]) {
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
			for (ifield=1; ifield<=NF; ++ifield)
				gsub(keyword_unsupported_regexp, "", $ifield)
			gsub(/(\"[[:blank:]]+|[[:blank:]]+\")/, "\"")
			gsub(/[[:blank:]]{2,}/, " ")
		}
		else if ($0 ~ array_variables_regexp["DESCRIPTION"]) {
			sub(/\".+\"/, "\"Firefox Web Browser, with SUSE patchset, to provide better KDE integration\"")
		}
		else if (!moz_pn_defined && ($0 ~ array_variables_regexp["MOZ_PV"])) {
			printf("MOZ_PN=\"firefox\"\n")
			moz_pn_defined=1
		}
		else if ($0 ~ array_variables_regexp["QA_PRESTRIPPED"]) {
			sub(text2regexp("$(get_libdir)"), "lib*")
		}

		if ($0 ~ text2regexp("^inherit ")) {
			$0=($0 " mercurial")
			mozconfig_version=gensub(mozconfig_version_regexp, "\\1", 1, $0)
			gsub("(\"| )moz(config|coreconf|linguas)", "&-kde")
		}

		# Process initial variables
		if ($0 ~ array_variables_regexp["HOMEPAGE"]) {
			homepage_open=1
		}
		else if ($0 ~ array_variables_regexp["RDEPEND"]) {
			rdepend_open=1
		}
		if (($0 ~ end_quote_regexp) && (rdepend_open || homepage_open)) {
			if (rdepend_open) {
				rdepend_open=0
				rdepend_close=1
			}
			else {
				homepage_open=0
				homepage_close=1
			}
			sub("\"[[:blank:]]*$", "", $0)
			suppress_current_line=($0 ~ blank_line_regexp) ? 1 : 0
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
		if (($0 ~ array_variables_regexp["EPATCH_EXCLUDE"]) ||
			($0 ~ array_variables_regexp["EPATCH_FORCE"])   ||
			($0 ~ array_variables_regexp["EPATCH_SUFFIX"]))
			epatch_variable_open=1
		if (epatch_variable_open) {
			suppress_current_line=1
			epatch_variable_open=($0 !~ end_quote_regexp)
		}
		if ($0 ~ text2regexp("^( |)(epatch|eapply) \"${WORKDIR}/firefox\"",2))
			suppress_current_line=1
		if ($0 ~ text2regexp("^ # (Apply our patches|Allow user to apply any additional patches without modifing ebuild)$",2))
			suppress_current_line=1
		gsub(/modifing/, "modifying", $0)
		if ($0 ~ text2regexp("${PN}-45-qt-widget-fix.patch"))
			suppress_current_line=1
		sub(text2regexp("eapply \"${FILESDIR}\"/xpcom-components-binutils-26.patch"), "PATCHES+=( \"${FILESDIR}/xpcom-components-binutils-26.patch\" )")
		sub(text2regexp("(eapply_user|epatch_user)",1), "default")
	}
	else if (array_phase_open["src_unpack"]) {
		sub(text2regexp("unpack ${A}",1), "default")
	}

	# Convert internal references to "firefox-kde-opensuse" (PN) to "firefox" (MOZ_PN) - but not for user messages or local patches!
	if (($0 !~ ebuild_message_regexp) && ($0 !~ text2regexp("^ epatch*${FILESDIR}*.patch")))
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
			printf("%s%s\n", indent, "kde? ( kde-misc/kmozillahelper:*  )")
			printf("%s%s\n", indent, "!!www-client/firefox\"")
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
	if (array_phase_open["src_unpack"] && ($0 ~ text2regexp("mozlinguas_src_unpack"))) {
		print_kde_patchset_src_fetch(indent, mozconfig_version)
		array_phase_open["src_unpack"]=0
	}
	else if (array_phase_open["pkg_pretend"] && shorten_build_object_path) {
		print_pkg_pretend_build_path_warning(indent)
		array_phase_open["pkg_pretend"]=0
	}
	else if (array_phase_open["src_prepare"] == 1) {
		print_kde_patchset_src_prepare(indent)
		++array_phase_open["src_prepare"]
	}
	else if (array_phase_open["pkg_postinst"] && ($0 ~ "gnome2_icon_cache_update")) {
		print_pkg_postinst_cursor_warning(indent)
		print_pkg_postinst_electrolysis_info(indent)
		array_phase_open["pkg_postinst"]=0
	}


	# Ebuild phase process closing stanzas for functions
	process_ebuild_phase_close($0, array_ebuild_phases, array_phase_open)
}

