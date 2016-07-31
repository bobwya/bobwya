# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit readme.gentoo-r1 versionator

MY_PV=$(replace_all_version_separators "-")
DESCRIPTION="A set of font rendering and replacement rules for fontconfig-infinality"
HOMEPAGE="http://bohoomil.com/"

if [[ "${PV}" == "9999" ]]; then
	FCU_PR="r99999999"
	EGIT_REPO_URI="https://github.com/bohoomil/${PN}.git"
	EGIT3_STORE_DIR="${T:-EGIT3_STORE_DIR}"
	inherit git-r3
else
	FCU_PR="r$(replace_all_version_separators "")"
	SRC_URI="https://github.com/bohoomil/${PN}/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="MIT"
SLOT="0"
IUSE=""
DEPEND="
	app-eselect/eselect-infinality
	app-eselect/eselect-lcdfilter
	media-libs/fontconfig-infinality
	=media-libs/freetype-2.6.3-${FCU_PR}:2[infinality]"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${PN}-${MY_PV}"

blacklist_font_conf="43-wqy-zenhei-sharp.conf"
eselect_envfile="ultimate"

create_fontconf_symlinks() {
	local font_set="${1}"
	shift 1
	pushd "${S}/fontconfig_patches/${font_set}" || die "pushd"
	local font_conf
	for font_conf in $@ *.conf; do
		dosym	../../conf.src.ultimate/"${font_conf}" \
				/etc/fonts/infinality/styles.conf.avail/"ultimate-${font_set}/${font_conf}"
	done
	popd || die "popd"
}

pkg_setup() {
	DISABLE_AUTOFORMATTING="1"
	DOC_CONTENTS=$(sed -e 's:${EROOT}:'"${EROOT}"':' "${FILESDIR}"/doc.txt)
}

src_prepare() {
	pushd "${S}/fontconfig_patches/fonts-settings" || die "pushd"
	rm -f ${blacklist_font_conf} || die "rm"
	popd || die "popd"

	# Generate lcdfilter config
	cp -f "${FILESDIR}/${eselect_envfile}" "${T}/${eselect_envfile}" || die "cp"
	awk '{
		if (sub(/^[#]{,1}\s*export\s+/, "") && ($0 ~ /^INFINALITY_FT/))
			print $0;
	}' "${S}/freetype/infinality-settings.sh" >> "${T}/${eselect_envfile}" || die "awk"
	default
}

src_install() {
	insinto /etc/fonts/infinality/conf.src.ultimate
	doins conf.d.infinality/*.conf
	doins fontconfig_patches/{ms,free,combi,fonts-settings}/*.conf

	# Extract a list of default .conf files out of Makefile.am
	local base_font_confs=$(awk '{
			in_conflinks=in_conflinks || ($0 ~ /^CONF_LINKS\s*=/)
			if (in_conflinks && ($0 ~ /conf\s*(\\){,1}$/))
				printf("%s ", $1)
			in_conflinks=in_conflinks && ($0 !~ /(^\s*|[^\\]\s*)$/)
		}' "${S}/conf.d.infinality/Makefile.am" || die "awk")

	base_font_confs+=$(find "${S}/fontconfig_patches/fonts-settings" \
		-type f -name "*.conf" -printf '%f ' || die "find")

	local font_set
	for font_set in ms free combi; do
		create_fontconf_symlinks "${font_set}" ${base_font_confs}
	done
	insinto /usr/share/eselect-lcdfilter/env.d
	doins "${T}/${eselect_envfile}"

	readme.gentoo_create_doc

	unset -f create_fontconf_symlinks
	unset -v blacklist_font_conf eselect_envfile
}
