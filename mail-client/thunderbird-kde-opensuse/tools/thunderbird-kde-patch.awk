BEGIN{
	kde_use_flag="kde"
	ebuild_package_version=("mail-client/" ebuild_file)
	sub("\.ebuild$", "", ebuild_package_version)
	PN="thunderbird-kde-opensuse"
	MOZ_PN="thunderbird"
	# Setup some regular expression constants - to hopefully make the script more readable(ish)!
	blank_line_regexp="^[[:blank:]]*$"
	leading_ws_regexp="^[[:blank:]]+"
	trailing_ws_regexp="^[[:blank:]]+"
	end_quote_regexp="\"[[:blank:]]*$"
	end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
	push_mozilla_regexp="^[[:blank:]]*pushd \"\$\{S\}\"\/mozilla \&\>\/dev\/null"
	popd_regexp="^[[:blank:]]*popd &>\/dev\/null"
	ebuild_inherit_regexp="^inherit "
	PN_regexp="thunderbird\-kde\-opensuse"
	variables="BUILD_OBJ_DIR DESCRIPTION KEYWORDS HOMEPAGE IUSE MOZ_HTTP_URI MOZ_PV PATCHFF RDEPEND"
	split(variables, array_variables)
	for (i in array_variables)
		array_variables_regexp[array_variables[i]]="^" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)"
	ebuild_phases="pkg_setup pkg_pretend src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
	split(ebuild_phases, array_ebuild_phases)
	for (i in array_ebuild_phases) {
		array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
		array_phase_open[array_ebuild_phases[i]]=0
	}
	keywork_unsupported_regexp="[\~]{0,1}(alpha|arm|ppc|ppc64)"
	ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
	mozlinguas_src_unpack_regexp="^[[:blank:]]*mozlinguas\_src\_unpack"
	local_epatch_regexp="^[[:blank:]]+epatch.+\\\$\\{FILESDIR\\}.+\.patch.*"
	pushd_mozilla_regexp="^[[:blank:]]*pushd[[:blank:]]+\\\"\\\$\\\{S\\\}\\\"\/mozilla[[:blank:]]*\&>\/dev\/null"
	set_build_obj_dir_regexp="^[[:blank:]]*echo[[:blank:]]+\\\"mk\_add\_options[[:blank:]]+MOZ\_OBJDIR\=\\\$\\\{BUILD\_OBJ\_DIR\\\}\\\"[[:blank:]]+>>[[:blank:]]+\\\"\\\$\\\{S\\\}\\\"\/\.mozconfig"
}
{
	suppress_current_line=0

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
	else if ($0 ~ ebuild_inherit_regexp) {
		$0=$0 " mercurial"
		mozconfig_version=gensub("^.+mozconfig\\-v([\\.[:digit:]]+).*$", "\\1", 1, $0)
	}
	else if ($0 ~ array_variables_regexp["DESCRIPTION"]) {
		sub(/\".+\"/, "\"Thunderbird Mail Client, with SUSE patchset, to provide better KDE integration\"")
	}
	else if (!moz_pn_defined && ($0 ~ array_variables_regexp["MOZ_PV"])) {
		print ("MOZ_PN=\"" MOZ_PN "\"")
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
		if (pushd_mozilla_open && ! popd_mozilla && ($0 ~ popd_regexp)) {
			printf("%s%s\n", indent, "# Patch for https://bugzilla.mozilla.org/show_bug.cgi?id=1143411")
			printf("%s%s\n", indent, "[[ $(get_major_version) -le 31 ]] && epatch \"${FILESDIR}/${PN}-31.8.0-buildfix-ft-master.patch\"")
			pushd_mozilla_open=0
			popd_mozilla=1
		}
		if (($0 ~ local_epatch_regexp) && ($0 !~ PN_regexp)) {
			gsub(MOZ_PN, "${PN}")
		}
	}
	else if (array_phase_open["src_configure"]) {
		if ($0 ~ "^[[:blank:]]*\#[[:blank:]]+Use an objdir to keep things organized\.") {
			gsub("\.[[:blank:]]*$", " and force build of Thunderbird mail application.")
		}
		else if ($0 ~ set_build_obj_dir_regexp) {
			printf("%s%s\n", 	indent, "sed -i -e \"\\\$amk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}\" \\")
			printf("%s%s%s\n", 	indent, indent, "-e '\''1i\\'\''\"mk_add_options MOZ_CO_PROJECT=mail\" \\")
			printf("%s%s%s\n", 	indent, indent, "-e '\''1i\\'\''\"ac_add_options --enable-application=mail\" \"${S}\"/.mozconfig")
			suppress_current_line=1
		}
	}

	# Process initial variables
	if ($0 ~ array_variables_regexp["RDEPEND"]) {
		rdepend_open=1
	}
	else if ($0 ~ array_variables_regexp["HOMEPAGE"]) {
		homepage_open=1
	}
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
	# Convert internal references to "thunderbird-kde-opensuse" (PN) to "thunderbird" (MOZ_PN) - but not for user messages or local patches!
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

	# Ebuild phase based post-checks
	if (array_phase_open["pkg_setup"] && (mozconfig_version+0.0 >= 6.45) && ($0 ~ (leading_ws_regexp "export MOZILLA_DIR=\".+\"$"))) {
		printf("%s%s\n",	indent, "export MOZILLA_FIVE_HOME=\"${MOZILLA_FIVE_HOME/${PN}/${MOZ_PN}}\"")
	}
	if (array_phase_open["src_unpack"] && ($0 ~ mozlinguas_src_unpack_regexp)) {
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
	else if (array_phase_open["pkg_pretend"] && shorten_build_object_path) {
		printf("%s%s\n",	indent, "if [[ ${#BUILD_OBJ_DIR} -gt ${MAX_OBJ_DIR_LEN} ]]; then")
		printf("%s%s%s\n",	indent, indent, "ewarn \"Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:\"")
		printf("%s%s%s\n",	indent, indent, "ewarn \" ... \\\"${BUILD_OBJ_DIR}\\\"\"")
		printf("%s%s\n", 	indent, "fi")
		shorten_build_object_path=0
	}
	else if (array_phase_open["src_prepare"] && ($0 ~ pushd_mozilla_regexp)) {
		if (patch_version < 42.0) {
			printf("%s%s\n",	indent, "# Patch for https://bugzilla.redhat.com/show_bug.cgi?id=966424")
			printf("%s%s\n",	indent, "epatch \"${FILESDIR}\"/${PN}-rhbz-966424.patch")
		}
		printf("%s%s\n", 	indent, "if use kde; then")
		printf("%s%s%s\n", 	indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\"")
		printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# Uncomment the next line to enable KDE support debugging (additional console output)...")
		printf("%s%s%s\n",  indent, indent,  "#epatch \"${FILESDIR}/${PN}-kde-debug.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# Uncomment the following patch line to force KDE/Qt4 file dialog for Thunderbird...")
		printf("%s%s%s\n",  indent, indent,  "#epatch \"${FILESDIR}/${PN}-force-qt-dialog.patch\"")
		printf("%s%s%s\n",  indent, indent,  "# ... _OR_ install the patch file as a User patch (/etc/portage/patches/mail-client/thunderbird-kde-opensuse/)")
		printf("%s%s\n", 	indent, "fi")
		pushd_mozilla_open=1
	}
	else if (array_phase_open["pkg_postinst"] == 1) {
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
		++array_phase_open["pkg_postinst"]
	}
	else if ($0 ~ array_variables_regexp["BUILD_OBJ_DIR"]) {
		printf("MAX_OBJ_DIR_LEN=\"80\"\n")
		shorten_build_object_path=1
	}
}
