
#! /bin/bash

for ebuild_file in *.ebuild; do
	echo "processing ebuild file: \"${ebuild_file}\""
	awk -F '[[:blank:]]+' \
		'BEGIN{
			use_flag="kde"
			leading_ws_regexp="^[[:blank:]]+"
			trailing_ws_regexp="^[[:blank:]]+"
			end_quote_regexp="\"[[:blank:]]*$"
		}
		{
			# spelling fix!
			gsub(/modifing/, "modifying", $0)
			if ($0 ~ /^IUSE\=\".+\"/) {
				for (ifield=2; ifield<=NF; ++ifield) {
					field=$ifield
					sub(/^[\"\+\-]+/, "", field)
					if (field > use_flag)
						break
				}
				if (ifield == NF+1)
					sub(/$/, (" " use_flag), $NF)
				else
					sub(/^/, (use_flag " "), $ifield)
			}
			else if ($0 ~ /DESCRIPTION\=\".+\"/) {
				sub(/\".+\"/, "\"Firefox Web Browser with OpenSUSE patchset, to provide better integration with KDE Desktop\"")
			}
			else if (rdepend_open && ($0 ~ end_quote_regexp)) {
				gsub(end_quote_regexp, "", $0)
				rdepend_open=0
				rdepend_close=1
			}
			else if ($0 ~/^inherit /) {
				gsub(/$/, " mercurial", $0)
			}
			print $0
			if (match($0, leading_ws_regexp))
				indent=substr($0, RSTART, RLENGTH)
			if (rdepend_close) {
				printf("%skde? ( kde-misc/kmozillahelper )\"\n",
						indent)
				rdepend_close=0
			}
			else if ($0 ~ /^MOZ_HTTP_URI\=\".+\"/) {
				printf("\n%s\n%s\n",
						"# Mercurial repository for Mozilla Firefox patches to provide better KDE Integration (developed by Wolfgang Rosenauer for OpenSUSE)",
						"EHG_REPO_URI=\"http://www.rosenauer.org/hg/mozilla\"")
			}
			else if ($0 ~ /^RDEPEND\=\"/) {
				rdepend_open=1
			}
			else if ($0 ~ /mozlinguas\_src\_unpack/) {
				printf("\n%s%s\n%s%s%s\n%s%s%s%s\n%s%s%s\n%s%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s\n",
					indent, "if use kde; then",
					indent, indent,	"if [[ ${MOZ_PV} =~ ^\(10|17|24\)\..*esr$ ]]; then",
					indent, indent,	indent, "EHG_REVISION=\"esr${MOZ_PV%%.*}\"",
					indent, indent,	"else",
					indent, indent,	indent, "EHG_REVISION=\"firefox${MOZ_PV%%.*}\"",
					indent, indent,	"fi",
					indent, indent,	"KDE_PATCHSET=\"firefox-kde-patchset\"",
					indent, indent,	"EHG_CHECKOUT_DIR=\"${WORKDIR}/${KDE_PATCHSET}\"",
					indent, indent,	"mercurial_fetch \"${EHG_REPO_URI}\" \"${KDE_PATCHSET}\"",
					indent, "fi")
			}
			else if ($0 ~ /^src\_prepare\(\)[[:blank:]]+\{/) {
				printf("%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s%s\n%s%s\n\n",
					indent, "if use kde; then",
					indent, indent,	 "# Firefox OpenSUSE KDE integration patchset",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-branded-icons.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-kde.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-kde-114.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/firefox-no-default-ualocale.patch\"",
					indent, indent,	 "# Gecko/toolkit OpenSUSE KDE integration patchset",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-kde.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-language.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/mozilla-prefer_plugin_pref.patch\"",
					indent, indent,	 "epatch \"${EHG_CHECKOUT_DIR}/toolkit-download-folder.patch\"",
					indent, "fi")
			}
		}' "${ebuild_file}" 1>"${ebuild_file}.new" 2>/dev/null
		[ -f "${ebuild_file}.new" ] && mv "${ebuild_file}.new" "${ebuild_file}"
done
