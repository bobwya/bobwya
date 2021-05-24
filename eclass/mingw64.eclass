# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: mingw64.eclass
# @MAINTAINER:
# Rob Walker <bob.mt.wya@gmail.com>
# @SUPPORTED_EAPIS: 6 7
# @AUTHOR:
# Rob Walker <bob.mt.wya@gmail.com>
# @BLURB: common app-emulation Wine and DXVK functionality
# @DESCRIPTION:
# Eclass to provide functionality common to the ::bobwya Overlay, used by:
#   app-emulation/dxvk
#   app-emulation/wine-staging
#   app-emulation/wine-vanilla
# This simple eclass checks for a correctly built, posix-threaded mingw64
# cross-build environment.
#

if [[ -z "${_MINGW_ECLASS}" ]]; then
_MINGW_ECLASS=1

case ${EAPI} in
	6|7)  ;;
	*)  die "EAPI=${EAPI:-0} is not supported" ;;
	esac

# eclass variables

# eclass functions

# @FUNCTION: _mingw64_get_gcc_thread_model
# @INTERNAL
# @USAGE:  <cross_environment>
# @RETURN: <gcc_thread_model>
# @DESCRIPTION:
# Determines the Mingw GCC threading model for the specified
# cross environment architecture.
_mingw64_get_gcc_thread_model() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local cross_environment cross_gcc

	cross_environment="${1#cross-}"
	cross_gcc="${cross_environment}-gcc"
	LC_ALL=C "${cross_gcc}" -v 2>&1 | \
		awk -F'[ ]*:[ ]*' '{ if ($1 == "Thread model") print $2 }'
}
	
# @FUNCTION: mingw64_check_requirements
# @USAGE:  <mingw64_min_version> <mingw64_gcc_min_version>
# @DESCRIPTION:
# Checks that the installed Mingw runtime and gcc version meet
# the specified minimum versions, for all support cross-compilation
# architectures. Check that the installed Mingw runtime has
# USE +libraries enabled, for all support cross-compilation architectures.
mingw64_check_requirements() {
	(($# == 2)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (2)"

	local -a cross_environments
	local mingw64_min_version="${1}" \
		mingw64_gcc_min_version="${2}" \
		mingw_error=0 gcc_thread_model

	use abi_x86_32 && cross_environments+=("cross-i686-w64-mingw32")
	use abi_x86_64 && cross_environments+=("cross-x86_64-w64-mingw32")

	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	# shellcheck disable=SC2068
	for cross_environment in ${cross_environments[@]}; do
		if ! has_version -b ">=${cross_environment}/mingw64-runtime-${mingw64_min_version}[libraries]"; then
			mingw_error=1
			eerror "Missing mingw64 runtime requirement:"
			eerror ">=${cross_environment}/mingw64-runtime-${mingw64_min_version}[libraries]"
		fi
		if ! has_version -b ">=${cross_environment}/gcc-${mingw64_gcc_min_version}" ; then
			mingw_error=1
			eerror "Missing mingw64 gcc package requirement:"
			eerror ">=${cross_environment}/gcc-${mingw64_gcc_min_version}"
		fi
		gcc_thread_model="$(_mingw64_get_gcc_thread_model "${cross_environment}")"
		if [[ "${gcc_thread_model}" != "posix" ]]; then
			mingw_error=1
			eerror "mingw64 gcc does not support posix threading, rebuild with:"
			eerror "EXTRA_ECONF=\"--enable-threads=posix\" emerge -1 ${cross_environment}/gcc"
		fi

		((mingw_error)) || continue

		eerror "See: https://wiki.gentoo.org/wiki/Mingw"
		eerror "${cross_environment} toolchain is not properly installed."
		die
	done
}

# @FUNCTION: mingw64_gcc_version_leq
# @USAGE:  <mingw64_gcc_max_version>
# @RETURN: 0=true 1=false
# @DESCRIPTION:
# Check that all installed Mingw gcc version(s) are less than or equal
# to the specified maximum version, for all support cross-compilation
# architectures.
mingw64_gcc_version_leq() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local -a cross_environments
	local mingw64_gcc_max_version="${1}"

	use abi_x86_32 && cross_environments+=("cross-i686-w64-mingw32")
	use abi_x86_64 && cross_environments+=("cross-x86_64-w64-mingw32")

	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	# shellcheck disable=SC2068
	for cross_environment in ${cross_environments[@]}; do
		if ! has_version -b "<=${cross_environment}/gcc-${mingw64_gcc_max_version}"; then
			return 1
		fi
	done

	return 0
}

# @FUNCTION: mingw64_gcc_version_geq
# @USAGE:  <mingw64_gcc_min_version>
# @RETURN: 0=true 1=false
# @DESCRIPTION:
# Check that all installed Mingw gcc version(s) are greater than or equal
# to the specified minimum version, for all support cross-compilation
# architectures.
mingw64_gcc_version_geq() {
	(($# == 1)) || die "${FUNCNAME[0]}(): invalid parameter count: ${#} (1)"

	local -a cross_environments
	local mingw64_gcc_min_version="${1}"

	use abi_x86_32 && cross_environments+=("cross-i686-w64-mingw32")
	use abi_x86_64 && cross_environments+=("cross-x86_64-w64-mingw32")

	[[ "${MERGE_TYPE}" = "binary" ]] && return 0

	# shellcheck disable=SC2068
	for cross_environment in ${cross_environments[@]}; do
		if ! has_version -b ">=${cross_environment}/gcc-${mingw64_gcc_min_version}"; then
			return 1
		fi
	done

	return 0
}

fi
