# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )


# Rename all the local patch files
cd "${script_folder%/tools}/files"
for patch_file in *.patch; do
	if [[ "${patch_file##*/}" =~ firefox\-kde\-opensuse ]]; then
		continue
	fi

	new_patch_file="${patch_file/firefox/firefox-kde-opensuse}"
	echo "moving patch file: \"${patch_file}\" -> \"${new_patch_file}\""
	mv "${patch_file}" "${new_patch_file}"
done

# Rename and patch all the stock firefox ebuild files
cd "${script_folder%/tools}"
for old_ebuild_file in *.ebuild; do
	# Don't process the ebuild files twice!
	if [[ "${old_ebuild_file##*/}" =~ firefox\-kde\-opensuse ]]; then
		continue
	fi

	ebuild_file="${old_ebuild_file/firefox/firefox-kde-opensuse}"
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' \
		'BEGIN{
			kde_use_flag="kde"
			# Setup some regular expression constants - to hopefully make the script more readable!
			leading_ws_regexp="^[[:blank:]]+"
			trailing_ws_regexp="^[[:blank:]]+"
			end_quote_regexp="\"[[:blank:]]*$"
			ebuild_inherit_regexp="^inherit "
			variables="BUILD_OBJ_DIR DESCRIPTION IUSE MOZ_HTTP_URI MOZ_PV RDEPEND"
			split(variables, array_variables)
			for (i in array_variables)
				array_variables_regexp[array_variables[i]]="^" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)"
			ebuild_phases="pkg_setup pkg_pretend src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm"
			split(ebuild_phases, array_ebuild_phases)
			for (i in array_ebuild_phases)
				array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
			ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
		}
		{
			# spelling fix!
			gsub(/modifing/, "modifying", $0)

			# Alter current ebuild line before it is printed
			if ($0 ~ array_variables_regexp["IUSE"]) {
				for (ifield=2; ifield<=NF; ++ifield) {
					field=gensub(/^[\"\+\-]+/, "", "g", $ifield)
					if (field > kde_use_flag)
						break
				}
				if (ifield == NF+1)
					sub(/$/, (" " kde_use_flag), $NF)q
				else
					sub(/^/, (kde_use_flag " "), $ifield)
			}
			else if ($0 ~ ebuild_inherit_regexp) {
				$0=$0 " mercurial"
			}
			else if ($0 ~ array_variables_regexp["DESCRIPTION"]) {
				sub(/\".+\"/, "\"Firefox Web Browser with OpenSUSE patchset, to provide better integration with KDE Desktop\"")
			}
			else if (rdepend_open && ($0 ~ end_quote_regexp)) {
				gsub(end_quote_regexp, "", $0)
				rdepend_open=0
				rdepend_close=1
			}
			else if (!moz_pn_defined && ($0 ~ array_variables_regexp["MOZ_PV"])) {
				print "MOZ_PN=\"firefox\""
				moz_pn_defined=1
			}
			# Convert internal references to "firefox-kde-opensuse" (PN) to "firefox" (MOZ_PN) - but not for user messages!
			if ($0 !~ ebuild_message_regexp)
				gsub(/\$\{PN\}/, "${MOZ_PN}")

			# Print current line in ebuild
			print $0

			# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
			if (match($0, leading_ws_regexp))
				indent=substr($0, RSTART, RLENGTH)

			# Print extra stuff after the current ebuild line has been printed
			if (rdepend_close) {
				printf("%skde? ( kde-misc/kmozillahelper )\n%s!!www-client/firefox\"\n",
						indent, indent)
				rdepend_close=0
			}
			else if ($0 ~ array_variables_regexp["MOZ_HTTP_URI"]) {
				printf("\n%s\n%s\n",
						"# Mercurial repository for Mozilla Firefox patches to provide better KDE Integration (developed by Wolfgang Rosenauer for OpenSUSE)",
						"EHG_REPO_URI=\"http://www.rosenauer.org/hg/mozilla\"")
			}
			else if ($0 ~ array_variables_regexp["RDEPEND"]) {
				rdepend_open=1
			}
			else if ($0 ~ /mozlinguas\_src\_unpack/) {
				printf("%s%s\n",	indent, "if use kde; then")
				printf("%s%s%s\n",	indent, indent, "if [[ ${MOZ_PV} =~ ^\(10|17|24\)\..*esr$ ]]; then")
				printf("%s%s%s%s\n",indent, indent, indent, "EHG_REVISION=\"esr${MOZ_PV%%.*}\"")
				printf("%s%s%s\n",	indent, indent, "else")
				printf("%s%s%s%s\n",indent, indent, indent, "EHG_REVISION=\"firefox${MOZ_PV%%.*}\"")
				printf("%s%s%s\n",	indent, indent, "fi")
				printf("%s%s%s\n",	indent, indent, "KDE_PATCHSET=\"firefox-kde-patchset\"")
				printf("%s%s%s\n",	indent, indent, "EHG_CHECKOUT_DIR=\"${WORKDIR}/${KDE_PATCHSET}\"")
				printf("%s%s%s\n",	indent, indent, "mercurial_fetch \"${EHG_REPO_URI}\" \"${KDE_PATCHSET}\"")
				printf("%s%s\n",	indent, "fi")
			}
			else if (shorten_build_object_path && ($0 ~ array_ebuild_phases_regexp["pkg_pretend"])) {
			    printf("%s%s\n",	indent, "if [[ \"${#BUILD_OBJ_DIR}\" -gt \"${MAX_OBJ_DIR_LEN}\" ]]; then")
			    printf("%s%s%s\n",	indent, indent, "ewarn \"Building ${PN} with a build object directory path >${MAX_OBJ_DIR_LEN} characters long may cause the build to fail:\"")
				printf("%s%s%s\n",	indent, indent, "ewarn \" ... \\\"${BUILD_OBJ_DIR}\\\"\"")
				printf("%s%s\n", 	indent, "fi")
			}
			else if ($0 ~ array_ebuild_phases_regexp["src_prepare"]) {
				printf("%s%s\n", 	indent, "if use kde; then")
				printf("%s%s%s\n",	indent, indent,	 "# Firefox OpenSUSE KDE integration patchset")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-branded-icons.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-kde.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-kde-114.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-no-default-ualocale.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-language.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-prefer_plugin_pref.patch\"")
				printf("%s%s%s\n", 	indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/toolkit-download-folder.patch\"")
                printf("%s%s%s\n",  indent, indent,  "# Uncomment the next line to enable debugging, for KDE Support, via console output...")
				printf("%s%s%s\n",  indent, indent,  "#epatch \"${FILESDIR}/mozilla-kde-debug.patch\"")
				printf("%s%s\n", 	indent, "fi")
			}
			else if ($0 ~ array_variables_regexp["BUILD_OBJ_DIR"]) {
				printf("MAX_OBJ_DIR_LEN=\"80\"\n")
				shorten_build_object_path=1
			}
		}' "${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
done

# Rebuild the master package Manifest file
[ -f "${ebuild_file}" ] && ebuild "${ebuild_file}" manifest
