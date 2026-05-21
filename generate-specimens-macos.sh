#!/bin/bash
#
# Script to generate HFS, HFS+ and HFSX test files
# Requires Mac OS

source ./shared_macos.sh

assert_availability_binary diskutil
assert_availability_binary hdiutil
assert_availability_binary mkfifo
assert_availability_binary mknod
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`

SPECIMENS_PATH="specimens/${MACOS_VERSION}"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ))

IMAGE_FILE="${SPECIMENS_PATH}/hfsplus"

echo "Creating: case-insensitive HFS+"
hdiutil create -fs 'HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

hdiutil attach "${IMAGE_FILE}.dmg"

create_test_file_entries "/Volumes/TestVolume"

# Sleep to prevent "resource busy" warning.
sleep 3

hdiutil detach disk${VOLUME_DEVICE_NUMBER}

IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_case_sensitive"

echo "Creating: case-sensitive HFS+"
hdiutil create -fs 'Case-sensitive HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

hdiutil attach "${IMAGE_FILE}.dmg"

create_test_file_entries "/Volumes/TestVolume"

# Sleep to prevent "resource busy" warning.
sleep 3

hdiutil detach disk${VOLUME_DEVICE_NUMBER}

# Note that versions of Mac OS before 10.13 not support "sort -V"
MINIMUM_VERSION=`echo "${SHORT_VERSION} 10.7" | tr ' ' '\n' | sed 's/[.]//' | sort -n | head -n 1`

# Note that creating a HFS+ file system with journaling fails on Mac OS 10.4
if test "${MINIMUM_VERSION}" = "107"
then
	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_journaled"

	echo "Creating: case-insensitive HFS+; with journaling"
	hdiutil create -fs 'Journaled HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_journaled_case_sensitive"

	echo "Creating: case-sensitive HFS+; with journaling"
	hdiutil create -fs 'Case-sensitive Journaled HFS+' -size "4M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

	hdiutil attach "${IMAGE_FILE}.dmg"

	create_test_file_entries "/Volumes/TestVolume"

	# Sleep to prevent "resource busy" warning.
	sleep 3

	hdiutil detach disk${VOLUME_DEVICE_NUMBER}
fi

exit ${EXIT_SUCCESS}
