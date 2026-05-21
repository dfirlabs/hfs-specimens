#!/bin/bash
#
# Script to generate HFS+ and HFSX test files, that contain many files
# Requires Mac OS

source ./shared_macos.sh

assert_availability_binary diskutil
assert_availability_binary hdiutil
assert_availability_binary mkfifo
assert_availability_binary mknod
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`

SPECIMENS_PATH="specimens/${MACOS_VERSION}-many-files"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ))

for NUMBER_OF_FILES in 100 1000 10000 100000
do
	if test ${NUMBER_OF_FILES} -eq 100000
	then
		IMAGE_SIZE="64M"

	elif test ${NUMBER_OF_FILES} -eq 10000
	then
		IMAGE_SIZE="8M"
	else
		IMAGE_SIZE="4M"
	fi

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_FILES}_files"

	echo "Creating: case-insensitive HFS+; with: ${NUMBER_OF_FILES} files"
	hdiutil create -fs 'HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Create additional files
	# Note that Mac OS 10.4 has no seq
	for (( NUMBER=2; NUMBER <= ${NUMBER_OF_FILES}; NUMBER++ ))
	do
		if test $(( ${NUMBER} % 2 )) -eq 0
		then
			touch /Volumes/TestVolume/testdir1/TestFile${NUMBER}
		else
			touch /Volumes/TestVolume/testdir1/testfile${NUMBER}
		fi
	done

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_FILES}_files_case_sensitive"

	echo "Creating: case-sensitive HFS+; with: ${NUMBER_OF_FILES} files"
	hdiutil create -fs 'Case-sensitive HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Create additional files
	# Note that Mac OS 10.4 has no seq
	for (( NUMBER=2; NUMBER <= ${NUMBER_OF_FILES}; NUMBER++ ))
	do
		if test $(( ${NUMBER} % 2 )) -eq 0
		then
			touch /Volumes/TestVolume/testdir1/TestFile${NUMBER}
		else
			touch /Volumes/TestVolume/testdir1/testfile${NUMBER}
		fi
	done

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}
done

exit ${EXIT_SUCCESS}
