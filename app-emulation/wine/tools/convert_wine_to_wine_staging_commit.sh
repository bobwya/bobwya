# !/bin/bash

# Absolute path to this script.
script_path=$(readlink -f $0)
# Absolute path this script is in.
script_folder=$( dirname "${script_path}" )
script_name=$( basename "${script_path}" )

# Global constants
SHA1_REGEXP="[[:xdigit:]]{40}"
WINE_STAGING_GIT_URL="https://github.com/wine-compholio/wine-staging.git"
# Don't search past back past the first commit for Wine-Staging that supports retreiving Wine commit information
LIMIT_WINE_STAGING_COMMIT="${LIMIT_WINE_STAGING_COMMIT:-aa817e83cf52f43d0a7fa4f78e196a02f9715e28}"
PACKAGE_DIRECTORY="wine-staging"
PATCH_INSTALLER="patches/patchinstall.sh"

# Global variables
VERBOSE=0
TIDY_UP=false


setup_tty_colours()
{
        if ${1}; then
				ttyblack="$( tput setaf 0 )"
                ttyred="$( tput setaf 1 )"
                ttygreen="$( tput setaf 2 )"
                ttyyellow="$( tput setaf 3 )"
                ttyblue="$( tput setaf 4 )"
                ttypurple="$( tput setaf 5 )"
                ttycyan="$( tput setaf 6 )"
                ttywhite="$( tput setaf 7 )"
                ttyblack_bold="$( tput setaf 0 ; tput bold )"
                ttyred_bold="$( tput setaf 1 ; tput bold )"
                ttygreen_bold="$( tput setaf 2 ; tput bold )"
                ttyyellow_bold="$( tput setaf 3 ; tput bold )"
                ttyblue_bold="$( tput setaf 4 ; tput bold )"
                ttypurple_bold="$( tput setaf 5 ; tput bold )"
                ttycyan_bold="$( tput setaf 6 ; tput bold )"
                ttywhite_bold="$( tput setaf 7 ; tput bold )"
                ttyreset="$( tput sgr0 )"
                ttybold_on="$( tput bold )"
                ttyunderline_on="$( tput smul )"
                ttyunderline_off="$( tput rmul )"
        else
				ttyblack=""
                ttyred=""
                ttygreen=""
                ttyyellow=""
                ttyblue=""
                ttypurple=""
                ttycyan=""
                ttywhite=""
                ttyblack_bold=""
                ttyred_bold=""
                ttygreen_bold=""
                ttyyellow_bold=""
                ttyblue_bold=""
                ttypurple_bold=""
                ttycyan_bold=""
                ttywhite_bold=""
                ttyreset=""
                ttybold_on=""
                ttyunderline_on=""
                ttyunderline_off=""
        fi
}

usage_message()
{
	printf "\n%s [%sOPTION%s] %s%sCOMMIT%s [%sDIRECTORY%s]\n" \
		"${script_name}" "${ttycyan_bold}" "${ttyreset}" "${ttygreen_bold}" "${ttyunderline_on}" "${ttyreset}" "${ttycyan_bold}" "${ttyreset}"
	printf "%sOPTION%s\n" "${ttycyan_bold}" "${ttyreset}"
	printf " %s-h%s, %s--help%s\tshow this usage information message\n" "${ttycyan_bold}" "${ttyreset}" "${ttycyan_bold}" "${ttyreset}"
	printf " %s-q%s, %s--quiet%s\treduce amount of information displayed\n" "${ttycyan_bold}" "${ttyreset}" "${ttycyan_bold}" "${ttyreset}"
	printf " %s-t%s, %s--tidy%s\tdelete Wine-Staging git directory (and containing working directory - if empty)\n" "${ttycyan_bold}" "${ttyreset}" "${ttycyan_bold}" "${ttyreset}"
	printf " %s-v%s, %s--verbose%s\tincrease amount of information displayed\n" "${ttycyan_bold}" "${ttyreset}" "${ttycyan_bold}" "${ttyreset}"
	printf "%s%sCOMMIT%s\t\tWine git commit (SHA-1) hash\n" "${ttygreen_bold}" "${ttyunderline_on}" "${ttyreset}"
	printf "%sDIRECTORY%s\tWorking directory to store Wine-Staging git tree\n" "${ttycyan_bold}" "${ttyreset}"
}

setup_tty_colours true

if ((EUID == 0)); then
	printf "\n%s : %sThis script should not be run as the %sroot%s user!!%s\n" \
	"${script_name}" "${ttyred_bold}" "${ttyunderline_on}" "${ttyunderline_off}" "${ttyreset}" 1>&2
	exit 10
fi

while [ -n "${1}" ]; do
	case "${1}" in
		-h|--help)
			usage_message
			exit 0;;
		-q|--quiet)
			VERBOSE=$((VERBOSE-1));;
		-t|--tidy*)
			TIDY_UP=true;;
		-v|--verbose)
			VERBOSE=$((VERBOSE+1));;
		-*)
			printf "\n%s : %sUnknown option \"%s%s%s\"%s\n" \
				"${script_name}" "${ttyred_bold}" "${ttygreen_bold}" "${1}" "${ttyred_bold}" "${ttyreset}" 1>&2
			usage_message
			exit 1;;
		*)
			break;;
	esac
	shift 1
done

if ((VERBOSE < 1)); then
	STDOUT="/dev/null"
else
	STDOUT="/dev/stdout"
fi

if [ ! -z ${1} ] && [[ ${1} =~ ${SHA1_REGEXP} ]]; then
	WINE_GIT_COMMIT="${1}"
else
	printf "\n%s : %sPlease supply a 40-digit hexidecimal Wine git commit (SHA-1) hash%s\n" \
		"${script_name}" "${ttyred_bold}" "${ttyreset}" 1>&2
	usage_message
	exit 1
fi

shift 1

if [ ! -z ${1} ]; then
	WORKING_DIRECTORY="${1}"
else
	WORKING_DIRECTORY="$(mktemp -d --tmpdir "wine-staging.XXXXXXXXXX")"
	if ((VERBOSE >= 0)); then
		printf "\nUsing temporary working folder: %s%s%s\n" \
				"${ttygreen_bold}" "${WORKING_DIRECTORY}" "${ttyreset}" 1>&2
	fi
fi

if [ ! -d "${WORKING_DIRECTORY}" ] && ! mkdir -pv "${WORKING_DIRECTORY}" 1>${STDOUT}; then
	printf "\n%s : %sUnable to create working folder: %s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttygreen_bold}" "${WORKING_DIRECTORY}" "${ttyreset}" 1>&2
	exit 2
fi

cd "${WORKING_DIRECTORY}" 1>${STDOUT}

if [ ! -d "${PACKAGE_DIRECTORY}" ]; then
	printf "%sPlease wait%s ... Clone Wine-Staging git tree from: %s%s%s%s%s\n" \
		"${ttyred_bold}" "${ttyreset}" "${ttyblue_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_URL}" "${ttyunderline_off}" "${ttyreset}" 1>${STDOUT}
	if ! git clone "${WINE_STAGING_GIT_URL}" 1>${STDOUT} ; then
		printf "\n%s : %sUnable to clone Wine-Staging git tree from: %s%s%s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttyblue_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_URL}" "${ttyunderline_off}" "${ttyreset}" 1>&2
		exit 3
	fi
fi

cd "${PACKAGE_DIRECTORY}"

if ! git reset --hard origin/master 1>${STDOUT} ; then
	printf "\n%s : %sUnable to reset Wine-Staging git tree to master branch%s\n" \
		"${script_name}" "${ttyred_bold}" "${ttyreset}" 1>&2
	exit 4
fi
	
while true; do
	WINE_STAGING_GIT_COMMIT=$(git rev-parse HEAD)
	if [[ ! ${WINE_STAGING_GIT_COMMIT} =~ ${SHA1_REGEXP} ]]; then
		printf "\n%s : %sUnable to obtain Wine-Staging git commit (SHA-1) hash%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttyreset}" 1>&2
		exit 5
	fi
	if [[ "${WINE_STAGING_GIT_COMMIT}" == "${LIMIT_WINE_STAGING_COMMIT}" ]]; then
		printf "\n%s : %sUnable to locate Wine-Staging git commit corresponding to Wine git commit:%s %s%s%s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttygreen_bold}" "${ttyunderline_on}" "${WINE_GIT_COMMIT}" "${ttyunderline_off}" "${ttyreset}" 1>&2
		exit 6
	fi
	if ((VERBOSE >= 0)); then
		printf "Processing Wine-Staging commit: %s%s%s%s%s ...\n"\
			"${ttygreen_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_COMMIT}" "${ttyunderline_off}" "${ttyreset}"
	else
		printf "%s.%s" "${ttyblack_bold}" "${ttyreset}"
	fi
	if [ ! -f "${WORKING_DIRECTORY}/${PACKAGE_DIRECTORY}/${PATCH_INSTALLER}" ]; then
		printf "\n%s : %sError - unable to access file %s%s%s utility for Wine-Staging git commit: %s%s%s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttyyellow_bold}" "${WORKING_DIRECTORY}/${PACKAGE_DIRECTORY}/${PATCH_INSTALLER}"\
			"${ttyred_bold}" "${ttygreen_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_COMMIT}" "${ttyunderline_off}" "${ttyreset}" 1>&2
		exit 7
	fi
	
	MATCHED_WINE_GIT_COMMIT=$( \
		gawk 'BEGIN {
			upstream_commit_function_regexp="^(upstream_commit|version)\(\)"
			function_close_regexp="^\}$"
			sha1_hash_regexp="[[:xdigit:]]{40}"
			echo_commit_regexp=("^[[:blank:]]*echo[[:blank:]]+\"([[:blank:]]+commit[[:blank:]]+|)(" sha1_hash_regexp ")\"")
		}
		{
			if ($0 ~ upstream_commit_function_regexp)
				upstream_commit_open=1
			if ((upstream_commit_open == 1) && ($0 ~ echo_commit_regexp)) {
				print gensub(echo_commit_regexp, "\\2", "1")
				exit 0
			}
			if ($0 ~ function_close_regexp)
				upstream_commit_open=0
		}' "${WORKING_DIRECTORY}/${PACKAGE_DIRECTORY}/${PATCH_INSTALLER}" 2>/dev/null \
	)
	if [[ ! "${MATCHED_WINE_GIT_COMMIT}" =~ ${SHA1_REGEXP} ]]; then
		printf "\n%s : %sFailed to get Wine git commit corresponding to Wine-Staging git commit: %s%s%s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttygreen_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_COMMIT}"\
			"${ttyunderline_off}" "${ttyreset}" 1>&2
		exit 8
	fi
	if [[ "${WINE_GIT_COMMIT}" == "${MATCHED_WINE_GIT_COMMIT}" ]]; then
		break
	fi
	if ! git reset --hard HEAD~1 1>${STDOUT}; then
		printf "\n%s : %sError - git reset (HEAD-1) command failed at Wine-Staging git commit: %s%s%s%s%s\n" \
			"${script_name}" "${ttyred_bold}" "${ttygreen_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_COMMIT}"\
			"${ttyunderline_off}" "${ttyreset}" 1>&2
		exit 9
	fi
done

if [[ ${TIDY_UP} == true ]]; then
	rm -rf "${WORKING_DIRECTORY}/${PACKAGE_DIRECTORY}" 1>${STDOUT}
	rmdir "${WORKING_DIRECTORY}" 1>${STDOUT}
fi

printf "\n%sFound Match!!%s\n\n%25s%s%s%s%s\n%s%25s%20s%s\n%25s%s%s%s%s\n" \
	"${ttygreen_bold}" "${ttyreset}"\
	"Wine-Staging git commit: "\
	"${ttygreen_bold}" "${ttyunderline_on}" "${WINE_STAGING_GIT_COMMIT}" "${ttyreset}"\
	"${ttyyellow_bold}" "" "=" "${ttyreset}"\
	"Wine git commit: "\
	"${ttygreen_bold}" "${ttyunderline_on}" "${WINE_GIT_COMMIT}" "${ttyreset}"

exit 0