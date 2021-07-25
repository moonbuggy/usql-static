#! /bin/bash

CWD="$(pwd)"
BUILD_DIR="${CWD}/builds"
TEMP_DIR="$(mktemp -d)"
INFO_FILE="${CWD}/build_info.txt"

unset WRITE_FILE

prev_build_type=''

cleanup () {	rm -rf "${TEMP_DIR}" >/dev/null 2>&1;	}

trap cleanup EXIT

case $(uname -p) in
	x86_64) THIS_ARCH='amd64' ;;
	*) echo 'ERROR: unknown host architecture' && exit 1 ;;
esac

## process tarballs
#
do_tarballs () {
	local tee_file; tee_file="${INFO_FILE}"

	[ "${1}" = 'no_file_out' ] \
		&& unset WRITE_FILE && shift

	if [ "${WRITE_FILE}" ]; then
		rm -f "${INFO_FILE}" >/dev/null 2>&1
	else
		tee_file='/dev/null'
	fi

	local build_type

	cd "${TEMP_DIR}" || { echo 'ERROR: could not change to temp directory'; exit 1; }

	for tarball in $(echo "${@}" | sort -uV); do
		[ -e "${tarball}" ] || break

		build_type="$(echo "${tarball}" | xargs -n1 basename | cut -d'-' -f2)"
		file_arch="$(echo "${tarball//.tar.gz/}" | xargs -n1 basename | rev | cut -d'-' -f1 | rev)"

		dest_file="usql-${build_type}-${file_arch}"
		dest_filepath="${TEMP_DIR}/${dest_file}"

		# untar and rename the binary
		tar -zxf "${tarball}" -C "${TEMP_DIR}"
		chmod a+x "${TEMP_DIR}/usql"
		mv "${TEMP_DIR}/usql" "${dest_filepath}"

		# only ask for available drivers if the executable will run on the host architecture
		[ "${file_arch}" = "${THIS_ARCH}" ] && available_drivers="$("./${dest_file}" -c '\drivers' 2>/dev/null)"

		# then print available drivers once, after all the architectures for the type are run
		[ -n "${prev_build_type}" ] && [ "${build_type}" != "${prev_build_type}" ] \
			&& printf '%s\n\n' "${available_drivers}" | tee -a "${tee_file}"
		
		file "${dest_file}" | tee -a "${tee_file}"

		# more detailed file information
		#	readelf -A "${dest_file}" #| tee -a "${INFO_FILE}"

		prev_build_type="${build_type}"
	done

	# print available drivers for the last build type
	printf '%s\n\n' "${available_drivers}" | tee -a "${tee_file}"
}

## the latest version found in the build directory
#
get_latest_version () {
	all_builds=$(ls "${BUILD_DIR}"/*.tar.gz 2>/dev/null)
	if [ -n "${all_builds}" ]; then
		echo "${all_builds}" | xargs -n1 basename | sed -E 's|^[^[:digit:]]+([[:digit:].]+)-.*$|\1|m' | sort -uV | tail -n1
	else
		echo "ERROR: no matching builds in ${BUILD_DIR}"
		exit 1
	fi
}


# if we're given files as arguments we'll just process those files
[ -n "${1}" ] \
	&& found_builds="$(realpath -e "${@}")" \
	&& unset WRITE_FILE

# otherwise, do the latest versions found in the build directory
[ -z "${found_builds}" ] \
	&& latest_version="$(get_latest_version)" \
	&& found_builds="$(find "${BUILD_DIR}/" -maxdepth 1 -type f -print0 -name "*${latest_version}*.tar.gz" | xargs -0 -n1 | sort -uV)" \
	&& found_desc=" for version ${latest_version} in ${BUILD_DIR}" \
	&& WRITE_FILE=1

printf 'Found builds%s:\n\n%s\n\n' "${found_desc}" "${found_builds//${BUILD_DIR}\//  }"

do_tarballs "${found_builds}"
