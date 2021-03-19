# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: dxvk.eclass
# @MAINTAINER:
# Rob Walker <bob.mt.wya@gmail.com>
# @SUPPORTED_EAPIS: 6 7
# @AUTHOR:
# Rob Walker <bob.mt.wya@gmail.com>
# @BLURB: common app-emulation Wine and DXVK functionality
# @DESCRIPTION:
# Eclass to provide functionality common to the ::bobwya Overlay, used by:
#   app-emulation/dxvk
#

if [[ -z "${_DXVK_ECLASS}" ]]; then
_DXVK_ECLASS=1

inherit meson multilib-minimal virtualx

case ${EAPI} in
	6|7)  ;;
	*)  die "EAPI=${EAPI:-0} is not supported" ;;
	esac

EXPORT_FUNCTIONS pkg_postinst

# eclass variables

# eclass functions

# @FUNCTION: _dxvk_get_abi
# @INTERNAL
# @RETURN: abi (bits) - stdout
# @DESCRIPTION:
# Get current ABI.
_dxvk_get_abi() {
	local abi

	if [[ "${ABI}" = "x86" ]]; then
		abi="32"
	elif [[ "${ABI}" = "amd64" ]]; then
		abi="64"
	else
		die "unknown ABI"
	fi
	echo "${abi}"
}

# @FUNCTION: dxvk_get_abi_build_file
# @RETURN: abi_build_file - stdout
# @DESCRIPTION:
# Get dxvk meson build file name, for current ABI.
dxvk_get_abi_build_file() {
	echo "build-win$(_dxvk_get_abi).txt"
}

# @FUNCTION: dxvk_set_configuration_path
# @USAGE:  <configuration_path>
# @DESCRIPTION:
# Set dxvk configuration file to use argument path.
dxvk_set_configuration_path() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local configuration_path="${1}"

	# Load configuration file from /etc/dxvk.conf.
	sed -Ei 's|filePath = "^(\s+)dxvk.conf";$|\1filePath = "'"${configuration_path}"'";|' \
			"${S}/src/util/config/config.cpp" \
		|| die "sed failed"
}

# @FUNCTION: dxvk_fix_setup_script
# @DESCRIPTION:
# Update base directory path. Delete dxvk installation,
# for unused ABI's.
dxvk_fix_setup_script() {
	sed -i -e 's|^basedir=.*$|basedir="'"${EPREFIX}"'/usr"|' \
			"${S}/setup_dxvk.sh" \
		|| die "sed failed"	
	if ! use abi_x86_32; then
		# shellcheck disable=SC2016
		sed -i '\|installFile "$win32_sys_path"|d' \
				"${S}/setup_dxvk.sh" \
			|| die "sed failed"
	fi
	if ! use abi_x86_64; then
		# shellcheck disable=SC2016
		sed -i '\|installFile "$win64_sys_path"|d' \
				"${S}/setup_dxvk.sh" \
			|| die "sed failed"
	fi
}

# @FUNCTION: dxvk_fix_readme
# @DESCRIPTION:
# Update README file.
dxvk_fix_readme() {
	sed -i -e 's|./setup_dxvk.sh|dxvk_setup|g' "${S}/README.md" \
		|| die "sed failed"	
}

# @FUNCTION: dxvk_set_setup_path
# @DESCRIPTION:
# Set correct root dxvk path, for current ABI, in the
# installation / setup script.
dxvk_set_setup_path() {
	sed -i -e "s|x$(_dxvk_get_abi)|$(get_libdir)/dxvk|" \
			"${S}/setup_dxvk.sh" \
		|| die "sed failed"
}

# @FUNCTION: dxvk_set_meson_options
# @DESCRIPTION:
# Add *FLAGS to meson (cross-)build file.
dxvk_set_meson_options() {
	sed -i -e "\|^c[_[:alpha:]]*_args[[:blank:]]*=|d" \
		-e "\|^\[properties\]|d" \
		-e "\|^needs_exe_wrapper = true|i\
[built-in options]\\n\
c_args = $(_meson_env_array "${CFLAGS}")\\n\
cpp_args = $(_meson_env_array "${CXXFLAGS}")\\n\
c_link_args = $(_meson_env_array "${LDFLAGS}")\\n\
cpp_link_args = $(_meson_env_array "${LDFLAGS}")" \
			"${S}/$(dxvk_get_abi_build_file)" \
	|| die "sed failed"
}

# @FUNCTION: dxvk_tests
# @USAGE: <tests_dir>
# @DESCRIPTION:
# This function runs the dxvk tests, for the current ABI.
dxvk_tests() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local test_exe test_path tests_dir wineprefix wine_path wineserver_path

	tests_dir="${1}"
	wine_path="$(readlink -f "$(which wine)")"
	wineprefix="${T}/.wine-${ABI}"
	wineserver_path="$(readlink -f "$(which wineserver)")"

	mkdir -p "${wineprefix}" || die "mkdir failed"
	chown -R "${EUID}" "${wineprefix}" || die "chown failed"

	find "${tests_dir}" -executable -name "*.exe" | while read -r test_path; do
		test_exe="$(basename "${test_path}")"
		einfo "running test: ${test_exe}"
		WINEPREFIX="${wineprefix}" \
			virtx "${wine_path}" start /unix "${test_path}"
		WINEPREFIX="${wineprefix}" \
			"${wineserver_path}" -k
	done
}

# EXPORT_FUNCTIONS function definitions

# @FUNCTION: dxvk_pkg_postinst 
# @DESCRIPTION:
# This ebuild phase function prints a dxvk usage message.
dxvk_pkg_postinst() {
	elog "${CATEGORY}/${PN} is installed. You still have to create"
	elog "DLL overrides in order to use it, for a specified WINEPREFIX:"
	elog "  WINEPREFIX=/path/to/.wine-prefix dxvk-setup install --symlink"
	elog
}

fi
