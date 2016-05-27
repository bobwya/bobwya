#!/bin/bash

check_php_config()
{
	local slot
	for slot in $(eselect --brief php list cli); do
		local php_dir="etc/php/cli-${slot}"
		if [[ -f "${ROOT}${php_dir}/php.ini" ]] ; then
			dodir "${php_dir}"
			cp -f "${ROOT}${php_dir}/php.ini" "${D}${php_dir}/php.ini" \
					|| die "cp unable to copy php.ini file"
			sed -i -e 's|^allow_url_fopen .*|allow_url_fopen = On|g' "${D}${php_dir}/php.ini" \
					|| die "sed unable to modify php.ini file copy"
		elif [[ "x$(eselect php show cli)" == "x${slot}" ]] ; then
			ewarn
			ewarn "${slot} does not have a php.ini file."
			ewarn "${PN} needs the 'allow_url_fopen' option set to \"On\""
			ewarn "for downloading to work properly."
			ewarn
		else
			elog
			elog "${slot} does not have a php.ini file."
			elog "${PN} may need the 'allow_url_fopen' option set to \"On\""
			elog "for downloading to work properly if you switch to ${slot}"
			elog
		fi
	done
}
