# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )


# Rename and patch all the stock mesa ebuild files
cd "${script_folder%/tools}"

# Remove unneeded patch files
rm "files"/mesa-10*.patch 2>/dev/null

# Patch metadata.xml file
metadata_file="metadata.xml"
mv "${metadata_file}" "${metadata_file}.bak"
gawk 'BEGIN{
        obsolete_use_flag_regexp="^[[:blank:]]+\<flag name\=\"(gles|openvg)\"\>.+$"
    }
    {
		if ($0 !~ obsolete_use_flag_regexp)
			printf("%s\n", $0)
    }' "${metadata_file}.bak" > "${metadata_file}" 2>/dev/null
rm "${metadata_file}.bak"

# Rename and patch all ebuild files
for old_ebuild_file in *.ebuild; do
	# Don't process the ebuild files twice!
	if grep -q '# Move lib{EGL,GL*,OpenVG} and others from /usr/lib to /usr/lib/opengl/xorg-x11/lib' "${old_ebuild_file}" ; then
		ebuild_file="${old_ebuild_file}"
		continue
	fi

	# bump media-libs/mesa ebuild revision (-rX) by +1 or make first (-r1) revision
	# Only supports >=media-libs/mesa-11.x
	ebuild_file=$( echo "${old_ebuild_file%.ebuild}" | awk -F'[\-\_\.]' \
		'{
			if ((NF < 1) || ($2 < 11))
				exit 1
			
			revision=$NF
			if (revision ~ /^r/) {
				sub(/^r/, "", revision)
				sub(/\-r[[:digit:]]+/, "")
				revision+=1
			}
			else
				revision=1
			printf("%s-r%d.ebuild\n", $0, revision)
		}' 2>/dev/null
	)
	if [[ "${ebuild_file}" == "" ]]; then
		rm "${old_ebuild_file}"
		continue
	fi
	
	new_ebuild_file="${ebuild_file}.new"
	echo "processing ebuild file: \"${old_ebuild_file}\" -> \"${ebuild_file}\""
	mv "${old_ebuild_file}" "${ebuild_file}"
	awk -F '[[:blank:]]+' \
		'BEGIN{
			# Setup some regular expression constants - to hopefully make the script more readable!
			blank_line_regexp="^[[:blank:]]*$"
			leading_ws_regexp="^[[:blank:]]+"
			trailing_ws_regexp="^[[:blank:]]+"
			end_quote_regexp="[^=]\"[[:blank:]]*$"
			end_curly_bracket_regexp="^[[:blank:]]*\}[[:blank:]]*$"
			ebuild_inherit_regexp="^inherit "
			ebuild_phases="pkg_setup src_prepare multilib_src_configure multilib_src_install multilib_src_install_all multilib_src_test pkg_postinst pkg_prerm"
			split(ebuild_phases, array_ebuild_phases)
			for (i in array_ebuild_phases) {
				array_ebuild_phases_regexp[array_ebuild_phases[i]]="^" gensub(/\_/, "\\_", "g", array_ebuild_phases[i]) "\\(\\)[[:blank:]]+"
				array_phase_open[array_ebuild_phases[i]]=0
			}
			ebuild_message_regexp="^[[:blank:]]+(einfo|elog|ewarn)"
			if_open_regexp="^[[:blank:]]+if"
			if_close_regexp="^[[:blank:]]+fi"
			emake_target_regexp="emake install DESTDIR=\"\\$\\{D\\}\""
			eselect_check_regexp="^[[:blank:]]+[\\>\\=\\>]+app\\-eselect\\\/eselect\\-opengl"
			keywords_regexp="^[[:blank:]]+KEYWORDS=\".+\""
			keyword_regexp="\\~{0,1}(alpha|amd64|arm|arm64|hppa|ia64|mips|ppc|ppc64|s390|sh|sparc|x86|amd64\\-fbsd|x86\\-fbsd|x86\\-freebsd|amd64\\-linux|arm\\-linux|ia64\\-linux|x86\\-linux|sparc\\-solaris|x64\\-solaris|x86\\-solaris)"
		}
		{
			suppress_current_line=0	

			if (preamble_over == 0) {
				# Change dependency on app-eselect/eselect_opengl to a newer patched version
				if ($0 ~ eselect_check_regexp)
					sub(/[\.[:digit:]]+$/, "1.3.1-r5")
					
				# Mark all converted ebuilds as unstable
				if ($0 ~ keywords_regexp)
					$0=gensub(keyword_regexp, "~\\1", "g")
			}
			# Ebuild phase based pre-checks
			if ((array_phase_open["pkg_postinst"] ==1) &&  ($0 ~ end_curly_bracket_regexp)) {
				printf("\n")
				printf("%s%s\n", indent, "ewarn \"This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues\"")
				printf("%s%s\n", indent, "ewarn \"when switching GL providers.\"")
				printf("%s%s\n", indent, "ewarn \"This package can only be used in conjuction with a specially patched version\"") 
				printf("%s%s\n", indent, "ewarn \"of app-select/eselect-opengl .\"")
			}
			
			# Ebuild phase process opening & closing stanzas for functions
			new_phase_active=""
			for (i in array_ebuild_phases) {
				if ($0 ~ array_ebuild_phases_regexp[array_ebuild_phases[i]]) {
					new_phase_active=i
					preamble_over=1
					target_block_open=0
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
			
			
			# Print current line in ebuild
			if (!suppress_current_line)
				print $0

			# Extract whitespace type and indent level for current line in the ebuild - so we step lightly!
			if (match($0, leading_ws_regexp))
				indent=substr($0, RSTART, RLENGTH)

			
			# Ebuild phase based post-checks
			if (array_phase_open["multilib_src_install"] == 1) {
				if ($0 ~ emake_target_regexp)
					target_block_open=1
				if (target_block_open == 1) {
					printf("\n")
					printf("%s%s\n", indent, "# Move lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} files from /usr/lib to /usr/lib/opengl/xorg-x11/lib")
					printf("%s%s\n", indent, "ebegin \"Moving lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} in order to implement dynamic GL switching support\"")
					printf("%s%s\n", indent, "local gl_dir=\"/usr/$(get_libdir)/opengl/${OPENGL_DIR}\"")
					printf("%s%s\n", indent, "dodir ${gl_dir}/lib")
					printf("%s%s\n", indent, "for x in \"${ED}\"/usr/$(get_libdir)/lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} ; do")
					printf("%s%s%s\n", indent, indent, "if [ -f ${x} -o -L ${x} ]; then")
					printf("%s%s%s%s\n", indent, indent, indent, "mv -f \"${x}\" \"${ED}${gl_dir}\"/lib \\")
					printf("%s%s%s%s%s\n", indent, indent, indent, indent, "|| die \"Failed to move ${x}\"")
					printf("%s%s%s\n", indent, indent, "fi")
					printf("%s%s\n", indent, "done")
					printf("%s%s\n", indent, "eend $?")
					array_phase_open["multilib_src_install"]=2
					target_block_open=0
				}
			}
			
		}' "${ebuild_file}" 1>"${new_ebuild_file}" 2>/dev/null
		[ -f "${new_ebuild_file}" ] || exit 1
		mv "${new_ebuild_file}" "${ebuild_file}"
done

# Rebuild the master package Manifest file
[ -f "${ebuild_file}" ] && ebuild "${ebuild_file}" manifest
