#!/bin/bash
#
# Script to generate HFS+ and HFSX test files, that contain many (extended) attributes
# Requires Mac OS

source ./shared_macos.sh

assert_availability_binary diskutil
assert_availability_binary hdiutil
assert_availability_binary mkfifo
assert_availability_binary mknod
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`

SPECIMENS_PATH="specimens/${MACOS_VERSION}-many-attributes"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ))

# Note that versions of Mac OS before 10.13 not support "sort -V"
MINIMUM_VERSION=`echo "${SHORT_VERSION} 10.7" | tr ' ' '\n' | sed 's/[.]//' | sort -n | head -n 1`

for NUMBER_OF_ATTRIBUTES in 100
do
	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_ATTRIBUTES}_attributes"

	echo "Creating: case-insensitive HFS+; with: ${NUMBER_OF_ATTRIBUTES} attributes"
	hdiutil create -fs 'HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Create additional attributes
	touch /Volumes/TestVolume/testdir1/many_xattrs

	# Note that Mac OS 10.4 has no seq
	for (( NUMBER=1; NUMBER <= ${NUMBER_OF_ATTRIBUTES}; NUMBER++ ))
	do
		if test "${MINIMUM_VERSION}" != "107"
		then
			# Mac OS 10.4 xattr does not have a -w option
			xattr -s "myxattr${NUMBER}" "Extended attribute: ${NUMBER}" /Volumes/TestVolume/testdir1/many_xattrs
		else
			xattr -w "myxattr${NUMBER}" "Extended attribute: ${NUMBER}" /Volumes/TestVolume/testdir1/many_xattrs
		fi
	done

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_ATTRIBUTES}_attributes_case_sensitive"

	echo "Creating: case-sensitive HFS+; with: ${NUMBER_OF_ATTRIBUTES} attributes"
	hdiutil create -fs 'Case-sensitive HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Create additional attributes
	touch /Volumes/TestVolume/testdir1/many_xattrs

	# Note that Mac OS 10.4 has no seq
	for (( NUMBER=1; NUMBER <= ${NUMBER_OF_ATTRIBUTES}; NUMBER++ ))
	do
		if test "${MINIMUM_VERSION}" != "107"
		then
			# Mac OS 10.4 xattr does not have a -w option
			xattr -s "myxattr${NUMBER}" "Extended attribute: ${NUMBER}" /Volumes/TestVolume/testdir1/many_xattrs
		else
			xattr -w "myxattr${NUMBER}" "Extended attribute: ${NUMBER}" /Volumes/TestVolume/testdir1/many_xattrs
		fi
	done

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}
done

exit ${EXIT_SUCCESS}
