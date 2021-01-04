# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

inherit readme.gentoo-r1

MY_PV="$(ver_rs 1- '-')"

DESCRIPTION="A set of font rendering and replacement rules for fontconfig-infinality"
HOMEPAGE="https://github.com/bohoomil"
SRC_URI="https://github.com/bohoomil/${PN}/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND="
	app-eselect/eselect-infinality
	app-eselect/eselect-lcdfilter
	media-libs/fontconfig-infinality
	media-libs/freetype:2[infinality]"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-${MY_PV}"

blacklist_font_conf_array=( "43-wqy-zenhei-sharp.conf" )
eselect_envfile="ultimate"

create_fontconf_symlinks() {
	local font_set="${1}" font_conf font_set_directory
	shift 1

	if font_set_directory="$( find "${S}" -type d -name "${font_set}" -printf '%P\n' -exec false {} + )"; then
		die "find \"${font_set}\" failed"
	fi

	pushd "${font_set_directory}" || die "pushd failed"
	# shellcheck disable=SC2068
	for font_conf; do
		dosym ../../"conf.src.ultimate/${font_conf}" \
			"/etc/fonts/infinality/styles.conf.avail/ultimate-${font_set}/${font_conf}"
	done
	popd || die "popd failed"
}

get_doc_contents() {
	printf "%s\\n%s\\n%s\\n" \
		'1. Disable all rules but 52-infinality.conf using eselect fontconfig' \
		'2. Enable one of the \"ultimate\" presets using eselect infinality' \
		'3. Select ultimate lcdfilter settings using eselect lcdfilter'
}

src_prepare() {
	local blacklist_font_conf

	# shellcheck disable=SC2068
	for blacklist_font_conf in ${blacklist_font_conf_array[@]}; do
		find "${S}" -type f -name "${blacklist_font_conf}" -delete
	done

	cp "${FILESDIR}/${eselect_envfile}" "${T}/${eselect_envfile}" || die "cp failed"

	default
}

src_install() {
	local -ar fontconfig_sets_array=( "combi" "free" "ms" )
	local base_font_confs fontconfig_set fonts_settings_directory \
		DISABLE_AUTOFORMATTING="1" DOC_CONTENTS

	insinto "/etc/fonts/infinality/conf.src.ultimate"
	doins "conf.d.infinality"/*.conf

	# shellcheck disable=SC2068
	for fontconfig_set in "fonts-settings" ${fontconfig_sets_array[@]}; do
		doins "${S}/fontconfig_patches/${fontconfig_set}"/*.conf
	done

	# Extract a list of default .conf files out of Makefile.am
	base_font_confs="$( \
		awk '{
			in_conflinks=in_conflinks || ($0 ~ /^CONF_LINKS\s*=/)
			if (in_conflinks && ($0 ~ /conf\s*(\\){,1}$/))
				printf("%s ", $1)
			in_conflinks=in_conflinks && ($0 !~ /(^\s*|[^\\]\s*)$/)
		}' "${S}/conf.d.infinality/Makefile.am" \
			|| die "awk failed"
	)"

	fonts_settings_directory="${S}/fontconfig_patches/fonts-settings"
	if base_font_confs+="$( find "${fonts_settings_directory}" -type f -name "*.conf" -printf '%f ' -exec false {} + )"; then
		die "find \"${fonts_settings_directory}/*.conf\" failed"
	fi
s
	# shellcheck disable=SC2068
	for fontconfig_set in ${fontconfig_sets_array[@]}; do
		# shellcheck disable=SC2086
		create_fontconf_symlinks "${fontconfig_set}" ${base_font_confs}
	done
	insinto "/usr/share/eselect-lcdfilter/env.d"
	doins "${T}/${eselect_envfile}"

	DOC_CONTENTS="$(get_doc_contents)"
	readme.gentoo_create_doc

	unset -v blacklist_font_conf_array eselect_envfile
}
