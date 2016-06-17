BEGIN{
	kde_use_flag="kde"
	ebuild_package_version=("www-client/" ebuild_file)
	gsub("\.ebuild$", "", ebuild_package_version)

	# Setup some regular expression constants - to hopefully make the script more readable!
	blank_line_regexp="^[[:blank:]]*$"
	leading_ws_regexp="^[[:blank:]]+"
	trailing_ws_regexp="^[[:blank:]]+"
	end_quote_regexp="[^=]\"[[:blank:]]*$"
	end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
	ebuild_inherit_regexp="^inherit "
	variables="BUILD_OBJ_DIR DESCRIPTION HOMEPAGE KEYWORDS IUSE MOZ_HTTP_URI MOZ_PV RDEPEND"
	split(variables, array_variables)
	for (i in array_variables)
		array_variables_regexp[array_variables[i]]="^" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)"
	ebuild_phases="pkg_setup pkg_pretend src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
	split(ebuild_phases, array_ebuild_phases)
	for (i in array_ebuild_phases) {
		array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
		array_phase_open[array_ebuild_phases[i]]=0
	}
	keyword_unsupported_regexp="[\~]{0,1}(alpha|arm64|arm|hppa|ppc|ppc64)"
	ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
	local_epatch_regexp="^[[:blank:]]+epatch.+\\\$\{FILESDIR\}.+\.patch.*"
}
{
	suppress_current_line=0
	# Alter current ebuild line before it is printed
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
	else if ($0 ~ ebuild_inherit_regexp) {
		$0=$0 " mercurial"
		mozconfig_version=gensub("^.+mozconfig\\-v([\\.[:digit:]]+).*$", "\\1", 1, $0)
	}
	else if ($0 ~ array_variables_regexp["DESCRIPTION"]) {
		sub(/\".+\"/, "\"Firefox Web Browser, with SUSE patchset, to provide better KDE integration\"")
	}
	else if (!moz_pn_defined && ($0 ~ array_variables_regexp["MOZ_PV"])) {
		print "MOZ_PN=\"firefox\""
		moz_pn_defined=1
	}

	# Ebuild phase process opening & closing stanzas for functions
	new_phase_active=""
	for (i in array_ebuild_phases) {
		if ($0 ~ array_ebuild_phases_regexp[array_ebuild_phases[i]]) {
			new_phase_active=i
			break
		}
	}
	if (new_phase_active != "") {
		for (i in array_ebuild_phases)
			array_phase_open[array_ebuild_phases[i]]=0
		array_phase_open[array_ebuild_phases[new_phase_active]]=1
	}
	else if ($0 ~ end_curly_bracket_regexp) {
		for (i in array_ebuild_phases)
			array_phase_open[array_ebuild_phases[i]]=0
	}

	# Ebuild phase based pre-checks
	if (array_phase_open["src_prepare"]) {
		gsub(/modifing/, "modifying", $0)
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
	# Convert internal references to "firefox-kde-opensuse" (PN) to "firefox" (MOZ_PN) - but not for user messages or local patches!
	if (($0 !~ ebuild_message_regexp) && ($0 !~ local_epatch_regexp))
		gsub(/\$\{PN\}/, "${MOZ_PN}")

	# Print current line in ebuild
	if (!suppress_current_line)
		print $0

	# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
	if (match($0, leading_ws_regexp))
		indent=substr($0, RSTART, RLENGTH)

	# Print extra stuff after the current ebuild line has been printed
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

	# Ebuild phase based post-checks
	if ((array_phase_open["src_unpack"] ==1) && ($0 ~ /mozlinguas\_src\_unpack/)) {
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
		array_phase_open["src_unpack"]=2
	}
	else if ((array_phase_open["pkg_pretend"] == 1) && shorten_build_object_path) {
		printf("%s%s\n",	indent, "if [[ ${#BUILD_OBJ_DIR} -gt ${MAX_OBJ_DIR_LEN} ]]; then")
		printf("%s%s%s\n",	indent, indent, "ewarn \"Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:\"")
		printf("%s%s%s\n",	indent, indent, "ewarn \" ... \\\"${BUILD_OBJ_DIR}\\\"\"")
		printf("%s%s\n", 	indent, "fi")
		array_phase_open["pkg_pretend"]=2
	}
	else if (array_phase_open["src_prepare"] == 1) {
		printf("%s%s\n", 	indent, "if use kde; then")
		printf("%s%s%s\n", 	indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset")
		printf("%s%s%s\n", 	indent, indent,	 "if [[ $(get_major_version) -lt 42 ]]; then")
		printf("%s%s%s%s\n", indent, indent, indent, "epatch \"${EHG_CHECKOUT_DIR}/toolkit-download-folder.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "fi")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-language.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "if [[ $(get_major_version) -lt 39 ]]; then")
		printf("%s%s%s%s\n", indent, indent, indent, "epatch \"${EHG_CHECKOUT_DIR}/mozilla-prefer_plugin_pref.patch\"")
		printf("%s%s%s\n",	indent, indent,  "fi")
		printf("%s%s%s\n",	indent, indent,	 "# Firefox OpenSUSE KDE integration patchset")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-branded-icons.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-kde.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-no-default-ualocale.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# Uncomment the next line to enable KDE support debugging (additional console output)...")
		printf("%s%s%s\n",  indent, indent,  "#epatch \"${FILESDIR}/firefox-kde-opensuse-kde-debug.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# Uncomment the following patch line to force KDE/Qt4 file dialog for Firefox...")
		printf("%s%s%s\n",  indent, indent,  "#epatch \"${FILESDIR}/firefox-kde-opensuse-force-qt-dialog.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# ... _OR_ install the patch file as a User patch (/etc/portage/patches/www-client/firefox-kde-opensuse/)")
		printf("%s%s%s\n",  indent, indent,  "# ... _OR_ add to your user .xinitrc: \"xprop -root -f KDE_FULL_SESSION 8s -set KDE_FULL_SESSION true\"")
		printf("%s%s\n", 	indent, "fi")
		array_phase_open["src_prepare"]=2
	}
	else if ((array_phase_open["pkg_postinst"] == 1) && ($0 ~ "gnome2_icon_cache_update")) {
		printf("%s%s\n", 	indent, "if [[ $(get_major_version) -ge 40 ]]; then")
		printf("%s%s%s\n", indent, indent, "# See https://forums.gentoo.org/viewtopic-t-1028874.html")
		printf("%s%s%s\n", indent, indent, "ewarn \"If you experience problems with your cursor theme - only when mousing over ${PN}...\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"1) create/alter the following file: \\\"\\${HOME}/.icons/default/index.theme\\\"\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   [icon theme]\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   Inherits= ...\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   ( replace \\\"...\\\" with your default icon theme name )\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"2) add/alter the following line in your \\\"\\${HOME}/.config/gtk-3.0/settings.ini\\\"\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   configuration file Settings section:\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   [Settings]\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"      ...\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"   gtk-cursor-theme-name=default\"")
		printf("%s%s%s\n", indent, indent, "ewarn \"      ...\"")
		printf("%s%s%s\n", indent, indent, "ewarn")
		printf("%s%s\n", 	indent, "fi")
		printf("%s%s\n", 	indent, "if [[ $(get_major_version) -eq 47 ]]; then")
		printf("%s%s%s\n",	indent, indent, "einfo \"To enable experimental Electrolysis (e10s) support for ${PN}...\"")
		printf("%s%s%s\n",	indent, indent, "einfo \"  browse to: \\\"about:config\\\" page\"")
		printf("%s%s%s\n",	indent, indent, "einfo \"  add entry: \\\"browser.tabs.remote.force-enable = true\\\"\"")
		printf("%s%s%s\n",	indent, indent, "einfo")
		printf("%s%s\n", 	indent, "fi")
		++array_phase_open["pkg_postinst"]
	}
	else if ($0 ~ array_variables_regexp["BUILD_OBJ_DIR"]) {
		printf("MAX_OBJ_DIR_LEN=\"80\"\n")
		shorten_build_object_path=1
	}
}
