#!/bin/bash
#
# Script to generate HFS+/HFSX test files for testing Unicode conversions
# Requires MacOS

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

create_test_file_entries_unicode()
{
	MOUNT_POINT=$1;

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	set +e;

	# Create a file for Unicode characters defined in UnicodeData.txt
	for NUMBER in `cat UnicodeData.txt | sed 's/;.*$//'`;
	do
		UNICODE_CHARACTER=`printf "%08x" $(( 0x${NUMBER} ))`;

		touch `python -c "print(''.join(['${MOUNT_POINT}/testdir1/unicode_U+${UNICODE_CHARACTER}_', '${UNICODE_CHARACTER}'.decode('hex').decode('utf-32-be')]).encode('utf-8'))"` 2> /dev/null;

		if test $? -ne 0;
		then
			echo "Unsupported: 0x${UNICODE_CHARACTER}";
		fi
	done

	set -e;
}

MACOS_VERSION=`sw_vers -productVersion`;
SPECIMENS_PATH="specimens/${MACOS_VERSION}";

if ! test -f "UnicodeData.txt";
then
	echo "Missing UnicodeData.txt file. UnicodeData.txt can be obtained from "
	echo "unicode.org make sure you have a local copy in the current working ";
	echo "directory.";

	exit ${EXIT_FAILURE};
fi

if test -d ${SPECIMENS_PATH};
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists.";

	exit ${EXIT_FAILURE};
fi

mkdir -p ${SPECIMENS_PATH};

set -e;

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`;

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ));

# Create raw disk image with a case-insensitive HFS+ file system and files for individual Unicode characters
IMAGE_NAME="hfsplus_unicode_files";
IMAGE_SIZE="32M";

hdiutil create -fs 'HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries_unicode "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

# Create raw disk image with a case-sensitive HFS+ file system and files for individual Unicode characters
IMAGE_NAME="hfsplus_unicode_files_case_sensitive";
IMAGE_SIZE="32M";

hdiutil create -fs 'Case-sensitive HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries_unicode "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

exit ${EXIT_SUCCESS};

