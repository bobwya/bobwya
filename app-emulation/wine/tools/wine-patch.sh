# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global variables
new_wine_versions="1.8_rc1 1.8_rc2 1.8_rc3 1.8_rc4 1.9.0 1.9.1 1.9.2 1.9.3 1.9.4"

# Rename and patch all the stock mesa ebuild files
cd "${script_folder%/tools}"

# Remove unneeded patch files...
rm "files/wine-1.1.15-winegcc.patch" 2>/dev/null
rm "files/wine-1.5.17-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.0-freetype-header-location.patch" 2>/dev/null
rm "files/wine-1.7.19-makefile-race-cond.patch" 2>/dev/null
rm "files/wine-1.7.2-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.2-osmesa-check.patch" 2>/dev/null
rm "files/wine-1.7.38-gstreamer-v5-staging-post.patch" 2>/dev/null
rm "files/wine-1.7.38-gstreamer-v5-staging-pre.patch" 2>/dev/null
rm "files/wine-1.7.39-gstreamer-v5-staging-post.patch" 2>/dev/null
rm "files/wine-1.7.39-gstreamer-v5-staging-pre.patch" 2>/dev/null
rm "files/wine-1.7.45-libunwind-osx-only.patch" 2>/dev/null
rm "files/wine-1.7.47-critical-security-cookie-fix.patch" 2>/dev/null

# Remove obsolete ebuild files...
rm wine-1.{6,7}*.ebuild 2>/dev/null

# Remove ChangeLog files...
rm ChangeLog* 2>/dev/null


# Patch metadata.xml file
metadata_file="metadata.xml"
mv "${metadata_file}" "${metadata_file}.bak"
gawk 'BEGIN{
        flag_regexp="^[[:blank:]]+\<flag name\=\"([\-[:alnum:]]+)\"\>.+$"
        use_close_regexp="\<\/use\>"
        gstreamer_use_flag="gstreamer"
        gstreamer_legacy_use_flag="gstreamer010"
        gstreamer_pkg_regexp="media-libs\/gstreamer"
    }
    {
        flag_name=($0 ~ flag_regexp) ? gensub(flag_regexp, "\\1", "g") : ""
        if ((flag_name == "gstreamer") && (gstreamer_match == 0)) {
			sub(gstreamer_use_flag, gstreamer_legacy_use_flag)
			gsub(gstreamer_pkg_regexp, gstreamer_pkg_regexp ":0.1")
			flag_name=gstreamer_legacy_use_flag
			gstreamer_match=1
        }
        gstreamer_use=(flag_name == gstreamer_use_flag) ? 1 : gstreamer_use
        if (((flag_name > gstreamer_use_flag) || ($0 ~ use_close_regexp)) && ! gstreamer_use) {
            printf("\t\t<flag name=\"%s\">%s</flag>\n",
                    gstreamer_use_flag,
                    "Use <pkg>media-libs/gstreamer:1.0</pkg> to provide DirectShow functionality")
            gstreamer_use=1
        }
        printf("%s\n", $0)
    }' "${metadata_file}.bak" 1>"${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

# Create latest unstable versions - if not in the main Gentoo tree already
for ebuild_file in *.ebuild; do
	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#wine-}"
	echo "ebuild version=${ebuild_version}"
	if [[ "${ebuild_version}" != "1.8" ]]; then
		continue
	fi

	for new_version in ${new_wine_versions}; do
		new_ebuild_file="${ebuild_file/1.8/${new_version}}"

		[ -f "${new_ebuild_file}" ] && continue

		cp "${ebuild_file}" "${new_ebuild_file}"
	done
done

# Patch all ebuild files
for ebuild_file in *.ebuild; do
	# Don't process ebuild files twice!
	if grep -q 'MINOR_V_ODD' "${ebuild_file}" ; then
		continue
	fi
	
	ebuild_version="${ebuild_file%.ebuild}"
	ebuild_version="${ebuild_version#wine-}"
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${ebuild_file}\""
	awk -F '[[:blank:]]+' -vwine_version="${ebuild_version}" \
		'BEGIN{
			# Setup some regular expression constants - to hopefully make the script more readable!
			blank_line_regexp="^[[:blank:]]*$"
			leading_ws_regexp="^[[:blank:]]+"
			trailing_ws_regexp="[[:blank:]]+$"
			end_quote_regexp="[^=]\"[[:blank:]]*$"
			end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
			ebuild_inherit_regexp="^inherit "
			variables="COMMON_DEPEND IUSE GST_P KEYWORDS STAGING_P SRC_URI"
			split(variables, array_variables)
			for (i in array_variables)
				array_variables_regexp[array_variables[i]]="^[[:blank:]]*" gensub(/\_/, "\\_", "g", array_variables[i]) "\=\".*(\"|$)"
			ebuild_phases="pkg_pretend pkg_setup src_unpack src_prepare src_configure multilib_src_configure multilib_src_test multilib_src_install_all pkg_preinst pkg_postinst pkg_prerm pkg_postrm"
			split(ebuild_phases, array_ebuild_phases)
			for (i in array_ebuild_phases) {
				array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
				array_phase_open[array_ebuild_phases[i]]=0
			}
			ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
			bracketed_expression_open_regexp="\\("
			bracketed_expression_close_regexp="\\)"
			bracketed_expression_regexp="\\([^\\)]*\\)"
			if_open_regexp="^[[:blank:]]*if.+then$"
			else_regexp="^[[:blank:]]*else"
			if_close_regexp="^[[:blank:]]*fi"
			emake_target_regexp="emake install DESTDIR=\"\\$\\{D\\}\""
			eselect_check_regexp="^[[:blank:]]+[\\>\\=\\>]+app\\-eselect\\\/eselect\\-opengl"
			keywords_regexp="^[[:blank:]]+KEYWORDS=\".+\""
			keyword_regexp="\\~{0,1}(alpha|amd64|arm|arm64|hppa|ia64|mips|ppc|ppc64|s390|sh|sparc|x86|amd64\\-fbsd|x86\\-fbsd|x86\\-freebsd|amd64\\-linux|arm\\-linux|ia64\\-linux|x86\\-linux|sparc\\-solaris|x64\\-solaris|x86\\-solaris)"
			source_wine_staging_patcher_regexp="^[[:blank:]]*source[[:blank:]]+\".*patchinstall\\.sh.*\"$"
			check_for_pv9999_regexp="\\[\\[ \\$\\{PV\\} == \"9999\" \\]\\]"
			test_gstreamer_or_staging_regexp="\\?\\?[[:blank:]]+\\([[:blank:]]+gstreamer[[:blank:]]+staging[[:blank:]]+\\)"
			legacy_gstreamer_wine_version_regexp="^(1\\.6|1\\.7|1\\.8|1\\.9\\.1)"
			gstreamer_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gstreamer:[\.[:digit:]]+"
			gst_plugins_base_full_atom_match="[<|>]\{0,1\}[=]\{0,1\}media-libs\\/gst-plugins-base:[\.[:digit:]]+"
			patchset_regexp="local[[:blank:]]+PATCHES=\\("
			use_custom_cflags_regexp="use[[:blank:]]+custom\\-cflags"
			staging_use_enabled_regexp="staging\\?[[:blank:]]+"
			staging_use_test_regexp="use staging"
			gstreamer_use_enabled_regexp="gstreamer\\?[[:blank:]]+"
			gstreamer_use_test_regexp="use gstreamer"
			configure_use_with_regexp="\\$\\(use_with[[:blank:]].+\\)"
			package_regexp="\\$\\{P\\}"
			package_version_regexp="\\$\\{PV\\}"
		}
		{
			suppress_current_line=0	

			if (preamble_over == 0) {
				if (($0 ~ if_open_regexp) && ($0 ~ check_for_pv9999_regexp) && (if_check_pv9999_open == 0))
					if_check_pv9999_open=1

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
						sub(package_version_regexp, "${MY_PV}")
					
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

				# Process gstreamer dependencies in COMMON_DEPEND="" variable
				if ($0 ~ array_variables_regexp["COMMON_DEPEND"])
					common_depend_open=1
				if ((common_depend_open == 1) && ($0 ~ (gstreamer_use_enabled_regexp bracketed_expression_open_regexp)))
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

				if ((common_depend_open == 1) && ($0 ~ end_quote_regexp))
					common_depend_open=0

				if ($0 ~ test_gstreamer_or_staging_regexp)
					suppress_current_line=1
				if ($0 ~ array_variables_regexp["KEYWORDS"])
					suppress_current_line=1
				if (($0 ~ array_variables_regexp["GST_P"]) && (wine_version !~ legacy_gstreamer_wine_version_regexp))
					suppress_current_line=1

				if ($0 ~ array_variables_regexp["STAGING_P"])
					sub(package_version_regexp, "${MY_PV}")

				if ((src_uri_open == 1) && ($0 ~ end_quote_regexp))
					src_uri_open=0
			}
			# Ebuild phase based pre-checks
			if (($0 ~ if_regexp) && ($0 ~ "wine_build_environment_check\\(\\)")) {
				printf("%s\n", "S=\"${WORKDIR}/${MY_P}\"")
				printf("\n")
			}
			else if (array_phase_open["src_unpack"] == 1) {
				if_stack+=($0 ~ if_open_regexp) ? 1 : 0
				if_stack+=($0 ~ if_close_regexp) ? -1 : 0
				if (($0 ~ else_regexp) && (if_stack == 1))
					if_check_pv9999_open=0
				if (if_check_pv9999_open == 1)
					suppress_current_line=1
				if ($0 ~ gstreamer_use_test_regexp) {
					if (wine_version ~ legacy_gstreamer_wine_version_regexp)
						sub("gstreamer", "gstreamer010")
					else
						suppress_current_line=1
				}
			}
			else if (array_phase_open["src_prepare"] == 1) {
				if_stack+=($0 ~ if_open_regexp) ? 1 : 0
				if_stack+=($0 ~ if_close_regexp) ? -1 : 0
				
				if (($0 ~ if_open_regexp) && ($0 ~ gstreamer_use_test_regexp) && (if_stack == 1)) {
					if (wine_version ~ legacy_gstreamer_wine_version_regexp)
						sub("gstreamer", "gstreamer010")
					else
						gstreamer_check_open=1
				}
				suppress_current_line=gstreamer_check_open

				if (($0 ~ if_open_regexp) && ($0 ~ staging_use_test_regexp) && (if_stack == 1))
					wine_staging_check_open=1
				if ((wine_staging_check_open == 1) && ($0 ~ source_wine_staging_patcher_regexp))
					sub("$", " || die \"Failed to apply Wine-Staging patches.\"")

					if (($0 ~ if_close_regexp) && (if_stack == 0)) {
					wine_staging_check_open=gstreamer_check_open=0
				}
			}
			else if (array_phase_open["multilib_src_configure"] == 1) {
				if (wine_version !~ legacy_gstreamer_wine_version_regexp)
					array_phase_open["multilib_src_configure"]=2
				else if (($0 ~ configure_use_with_regexp) && (sub("gstreamer", "gstreamer010 gstreamer") == 1))
					array_phase_open["multilib_src_configure"]=2
			}

			# Ebuild phase process opening & closing stanzas for functions
			new_phase_active=""
			for (i in array_ebuild_phases) {
				if ($0 !~ array_ebuild_phases_regexp[array_ebuild_phases[i]])
					continue

				new_phase_active=i
				if_stack=0
				preamble_over=1
				target_block_open=0
				break
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
			
			# Print current line in ebuild
			if (!suppress_current_line)
				print $0

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
						printf("%s%s\n", indent, "let \"MINOR_V_ODD=$(get_version_component_range 2) % 2\"")
						printf("%s%s\n", indent, "MY_PV=\"${PV}\"")
						printf("%s%s\n", indent, "if [[ \"$(get_version_component_range 3)\" =~ ^rc ]]; then")
						printf("%s%s%s\n", indent, indent, "MY_PV=$(replace_version_separator 2 '\''-'\'')")
						printf("%s%s\n", indent, "elif [[ ${MINOR_V_ODD} == 1 ]]; then")
						printf("%s%s%s\n", indent, indent, "KEYWORDS=\"-* ~amd64 ~x86 ~x86-fbsd\"")
						printf("%s%s\n", indent, "else")
						printf("%s%s%s\n", indent, indent, "KEYWORDS=\"-* amd64 x86 x86-fbsd\"")
						printf("%s%s\n", indent, "fi")
						printf("%s%s\n", indent, "MY_P=\"${PN}-${MY_PV}\"")
					}
					if ($0 ~ else_regexp)
						else_check_pv9999_open=1
					else if ($0 ~ if_close_regexp)
						if_check_pv9999_open=else_check_pv9999_open=0
				}
			}
			
			# Ebuild phase based post-checks
			if ((array_phase_open["pkg_pretend"] == 1) && ($0 ~ "wine_build_environment_check")) {
				printf("%s%s\n",	indent, "if [[ ${PV} == \"9999\" ]] && use staging; then")
				printf("%s%s%s\n",	indent, indent, "ewarn \"You have enabled a live ebuild of Wine with USE +staging.\"")
				printf("%s%s%s\n",	indent, indent, "ewarn \"All git branch and commit references will link to the Wine-Staging git tree.\"")
				printf("%s%s%s\n",	indent, indent, "ewarn \"By default the Wine-Staging git tree branch master will be used.\"")
				printf("%s%s\n",	indent, "fi")
				array_phase_open["pkg_pretend"]=2
			}
			if ((array_phase_open["src_unpack"] == 1) && ($0 ~ if_open_regexp) && ($0 ~ check_for_pv9999_regexp) && (if_stack == 1)) {
				if_check_pv9999_open=1
				printf("%s%s%s\n",	 indent, indent, "# Reference either Wine or Wine Staging git branch (depending on +staging use flag)")
				printf("%s%s%s\n",	 indent, indent, "EGIT_BRANCH=${EGIT_BRANCH:-master}")
				printf("%s%s%s\n",	 indent, indent, "if use staging; then")
				printf("%s%s%s%s\n", indent, indent, indent, "EGIT_REPO_URI=${STAGING_EGIT_REPO_URI} EGIT_CHECKOUT_DIR=${STAGING_DIR} git-r3_src_unpack")
				printf("%s%s%s%s\n", indent, indent, indent, "local WINE_COMMIT=$(\"${STAGING_DIR}/patches/patchinstall.sh\" --upstream-commit)")
				printf("%s%s%s%s\n", indent, indent, indent, "[[ ! ${WINE_COMMIT} =~ [[:xdigit:]]{40} ]] && die \"Failed to get Wine git commit corresponding to Wine-Staging git commit ${EGIT_VERSION}.\"")
				printf("%s%s%s%s\n", indent, indent, indent, "einfo \"Building Wine commit ${WINE_COMMIT} referenced by Wine-Staging commit ${EGIT_VERSION} ...\"")
				printf("%s%s%s%s\n", indent, indent, indent, "EGIT_COMMIT=\"${WINE_COMMIT}\"")
				printf("%s%s%s\n",	 indent, indent, "fi")
				if (wine_version !~ legacy_gstreamer_wine_version_regexp) {
					printf("%s%s%s\n",	 indent, indent, "EGIT_CHECKOUT_DIR=\"${S}\" git-r3_src_unpack")
					printf("%s%s%s\n",	 indent, indent, "if use gstreamer && grep -q \"gstreamer-0.10\" \"${S}\"/configure ; then")
					printf("%s%s%s%s\n", indent, indent, indent, "ewarn \"Wine commit ${GSTREAMER_COMMIT} first introduced support for the gstreamer:1.0 branch.\"")
					printf("%s%s%s%s\n", indent, indent, indent, "ewarn \"Specify a newer Wine commit or emerge with USE -gstreamer.\"")
					printf("%s%s%s%s\n", indent, indent, indent, "die \"This live ebuild does not support Wine builds using the older gstreamer:0.1 branch.\"")
					printf("%s%s%s\n",	 indent, indent, "fi")
				}
			}
			if ((array_phase_open["src_prepare"] == 1) && (wine_version !~ "^(1\.8.*|1\.9\.0|1\.9\.1|1\.9\.2|9999)$")) {
				if ((patch_set_open == 0) && $0 ~ (leading_ws_regexp patchset_regexp))
					patch_set_open=1
				if ((patch_set_open == 1) && ($0 ~ (bracketed_expression_close_regexp "$"))) {
					# Hack - disable forced alignment for all gcc >=5.3.x versions - needs a gcc test function for Upstream (in-tree) patch
					printf("%s%s\n",	indent, "if [[ $(gcc-major-version) = 5 && $(gcc-minor-version) -ge 3 ]]; then")
					printf("%s%s%s\n",	indent, indent, "local PATCHES+=( \"${FILESDIR}\"/${PN}-1.9.3-gcc-5_3_0-disable-force-alignment.patch ) #574044")
					printf("%s%s\n",	indent, "fi")
					patch_set_open=2
				}
			}
			if ((array_phase_open["src_configure"] == 1) && (wine_version ~ "^9999$") && ($0 ~ (leading_ws_regexp use_custom_cflags_regexp))) {
				# Hack - disable forced alignment for all gcc >=5.3.x versions - needs a gcc test function for Upstream (in-tree) patch
				printf("%s%s\n",	indent, "if [[ ${PV} == \"9999\" ]] && [[ $(gcc-major-version) = 5 && $(gcc-minor-version) -ge 3 ]]; then")
				printf("%s%s%s\n",	indent, indent, "local CFLAGS=\"${CFLAGS} -fno-omit-frame-pointer\" # bug 574044")
				printf("%s%s\n",	indent, "fi")
				array_ebuild_phases["src_configure"]=2
			}
		}' "${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
		new_ebuild_file="${new_ebuild_file%.new}"
done


# Rebuild the master package Manifest file
[ -n "${new_ebuild_file}" ] && [ -f "${new_ebuild_file}" ] && ebuild "${new_ebuild_file}" manifest
