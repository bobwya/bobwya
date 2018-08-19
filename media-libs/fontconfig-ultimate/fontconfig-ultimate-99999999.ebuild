# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034

EAPI=7

inherit readme.gentoo-r1

MY_PN="infinality_bundle"

DESCRIPTION="A set of font rendering and replacement rules for fontconfig-infinality"
HOMEPAGE="https://github.com/archfan/infinality_bundle"

if [[ "${PV}" == "99999999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/archfan/infinality_bundle.git"
	EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_PN}"
fi

LICENSE="MIT"
SLOT="0"
IUSE=""
DEPEND="
	app-eselect/eselect-infinality
	app-eselect/eselect-lcdfilter
	media-libs/fontconfig-infinality
	media-libs/freetype:2[infinality]"
RDEPEND="${DEPEND}"

blacklist_font_conf="43-wqy-zenhei-sharp.conf"
eselect_envfile="ultimate"

create_fontconf_symlinks() {
	local font_set="${1}" font_conf
	pushd "${S}/fontconfig_patches/${font_set}" || die "pushd failed"
	# shellcheck disable=SC2068
	for font_conf in ${@:1} *.conf; do
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

src_unpack() {
	default
	if [[ "${PV}" == "99999999" ]]; then
		git-r3_src_unpack
		unpack "${WORKDIR}/${MY_PN}/02_fontconfig-iu/${PN}-git.tar.bz2"
		mv "${PN}-git" "${P}" || die "mv failed"
	fi
}

src_prepare() {
	pushd "${S}/fontconfig_patches/fonts-settings" || die "pushd failed"
	rm -f ${blacklist_font_conf} || die "rm failed"
	popd || die "popd failed"

	cp "${FILESDIR}/${eselect_envfile}" "${T}/${eselect_envfile}" || die "cp failed"

	default
}

src_install() {
	insinto "/etc/fonts/infinality/conf.src.ultimate"
	doins "conf.d.infinality"/*.conf
	doins "fontconfig_patches"/{ms,free,combi,fonts-settings}/*.conf

	# Extract a list of default .conf files out of Makefile.am
	local base_font_confs
	base_font_confs="$(awk \
		'{
			in_conflinks=in_conflinks || ($0 ~ /^CONF_LINKS\s*=/)
			if (in_conflinks && ($0 ~ /conf\s*(\\){,1}$/))
				printf("%s ", $1)
			in_conflinks=in_conflinks && ($0 !~ /(^\s*|[^\\]\s*)$/)
		}' "${S}/conf.d.infinality/Makefile.am" \
			|| die "awk failed"
	)"

	base_font_confs+="$(
		find "${S}/fontconfig_patches/fonts-settings" -type f -name "*.conf" -printf '%f ' -exec false {} + \
			&& die "find failed"
	)"

	local font_set
	for font_set in ms free combi; do
		# shellcheck disable=SC2086
		create_fontconf_symlinks "${font_set}" ${base_font_confs}
	done
	insinto "/usr/share/eselect-lcdfilter/env.d"
	doins "${T}/${eselect_envfile}"

	local	DISABLE_AUTOFORMATTING="1" DOC_CONTENTS
	DOC_CONTENTS="$(get_doc_contents)"
	readme.gentoo_create_doc

	unset -f create_fontconf_symlinks
	unset -v blacklist_font_conf eselect_envfile
}
