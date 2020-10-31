#!/bin/bash
#
# Script to generate HFS/HFS+/HFSX test files
# Requires MacOS

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

AFSCTOOL="/usr/local/bin/afsctool";

create_test_file_entries()
{
	MOUNT_POINT=$1;

	# Create an empty file
	touch ${MOUNT_POINT}/emptyfile

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	# Create a file
	echo "My file" > ${MOUNT_POINT}/testdir1/testfile1

	# Create a hard link to a file
	ln ${MOUNT_POINT}/testdir1/testfile1 ${MOUNT_POINT}/file_hardlink1

	# Create a symbolic link to a file
	ln -s ${MOUNT_POINT}/testdir1/testfile1 ${MOUNT_POINT}/file_symboliclink1

	# Create a hard link to a directory
	# ln ${MOUNT_POINT}/testdir1 ${MOUNT_POINT}/directory_hardlink1
	# ln: ${MOUNT_POINT}/testdir1: Is a directory

	# Create a symbolic link to a directory
	ln -s ${MOUNT_POINT}/testdir1 ${MOUNT_POINT}/directory_symboliclink1

	# Create a file with an UTF-8 NFC encoded filename
	touch `printf "${MOUNT_POINT}/nfc_t\xc3\xa9stfil\xc3\xa8"`

	# Create a file with an UTF-8 NFD encoded filename
	touch `printf "${MOUNT_POINT}/nfd_te\xcc\x81stfile\xcc\x80"`

	# Create a file with an UTF-8 NFD encoded filename
	touch `printf "${MOUNT_POINT}/nfd_\xc2\xbe"`

	# Create a file with an UTF-8 NFKD encoded filename
	touch `printf "${MOUNT_POINT}/nfkd_3\xe2\x81\x844"`

	# Create a file with filename that requires case folding if
	# the file system is case-insensitive
	touch `printf "${MOUNT_POINT}/case_folding_\xc2\xb5"`

	# Create a file with a forward slash in the filename
	touch `printf "${MOUNT_POINT}/forward:slash"`

	# Create a symbolic link to a file with a forward slash in the filename
	ln -s ${MOUNT_POINT}/forward:slash ${MOUNT_POINT}/file_symboliclink2

	# Create a file with a resource fork with content
	touch ${MOUNT_POINT}/testdir1/resourcefork1
	echo "My resource fork" > ${MOUNT_POINT}/testdir1/resourcefork1/..namedfork/rsrc

	# Create a file with an extended attribute with content
	touch ${MOUNT_POINT}/testdir1/xattr1
	xattr -w myxattr1 "My 1st extended attribute" ${MOUNT_POINT}/testdir1/xattr1

	# Create a directory with an extended attribute with content
	mkdir ${MOUNT_POINT}/testdir1/xattr2
	xattr -w myxattr2 "My 2nd extended attribute" ${MOUNT_POINT}/testdir1/xattr2

	# Create a file that uses HFS+ compression (decmpfs)
	if test -x ${AFSCTOOL};
	then
		# Create a file that uses HFS+ compression (decmpfs) compression method 3
		echo "My compressed file" > ${MOUNT_POINT}/testdir1/compressed1
		${AFSCTOOL} -c -T ZLIB ${MOUNT_POINT}/testdir1/compressed1

		# Create a file that uses HFS+ compression (decmpfs) compression method 4
		ditto --nohfsCompression LICENSE ${MOUNT_POINT}/testdir1/compressed2
		${AFSCTOOL} -c -T ZLIB ${MOUNT_POINT}/testdir1/compressed2

		# Create a file that uses HFS+ compression (decmpfs) compression method 7
		echo "My compressed file" > ${MOUNT_POINT}/testdir1/compressed3
		${AFSCTOOL} -c -T LZVN ${MOUNT_POINT}/testdir1/compressed3

		# Create a file that uses HFS+ compression (decmpfs) compression method 8
		ditto --nohfsCompression LICENSE ${MOUNT_POINT}/testdir1/compressed4
		${AFSCTOOL} -c -T LZVN ${MOUNT_POINT}/testdir1/compressed4
	else
		ditto --hfsCompression LICENSE ${MOUNT_POINT}/testdir1/compressed1
	fi

	# TODO: create file that uses extents (overflow) file
}

create_test_file_entries_unicode()
{
	MOUNT_POINT=$1;

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	set +e;

	# Create a file for every supported Unicode character
	for NUMBER in `seq $(( 0x00000000 )) $(( 0x110000 ))`;
	do
		UNICODE_CHARACTER=`printf "%08x" ${NUMBER}`;

		touch `python -c "print('/'.join(['${MOUNT_POINT}/testdir1', '${UNICODE_CHARACTER}'.decode('hex').decode('utf-32-be')]).encode('utf-8'))"` 2> /dev/null;

		if test $? -ne 0;
		then
			echo "Unsupported: 0x${UNICODE_CHARACTER}";
		fi
	done

	set -e;
}

MACOS_VERSION=`sw_vers -productVersion`;
SPECIMENS_PATH="specimens/${MACOS_VERSION}";

if test -d ${SPECIMENS_PATH};
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists.";

	exit ${EXIT_FAILURE};
fi

mkdir -p ${SPECIMENS_PATH};

set -e;

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`;

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ));

# Create raw disk image with a case-insensitive HFS+ file system
IMAGE_NAME="hfsplus";
IMAGE_SIZE="4M";

hdiutil create -fs 'HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

# Create raw disk image with a case-sensitive HFS+ file system
IMAGE_NAME="hfsplus_case_sensitive";
IMAGE_SIZE="4M";

hdiutil create -fs 'Case-sensitive HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

# Create raw disk image with a case-insensitive HFS+ file system with journaling
IMAGE_NAME="hfsplus_journaled";
IMAGE_SIZE="4M";

hdiutil create -fs 'Journaled HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

# Create raw disk image with a case-sensitive HFS+ file system with journaling
IMAGE_NAME="hfsplus_journaled_case_sensitive";
IMAGE_SIZE="4M";

hdiutil create -fs 'Case-sensitive Journaled HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

create_test_file_entries "/Volumes/TestVolume";

hdiutil detach disk${VOLUME_DEVICE_NUMBER};

for NUMBER_OF_FILES in 100 1000 10000 100000;
do
	if test ${NUMBER_OF_FILES} -eq 100000;
	then
		IMAGE_SIZE="64M";

	elif test ${NUMBER_OF_FILES} -eq 10000;
	then
		IMAGE_SIZE="8M";
	else
		IMAGE_SIZE="4M";
	fi

	# Create raw disk image with a case-insensitive HFS+ file system
	IMAGE_NAME="hfsplus_${NUMBER_OF_FILES}_files";

	hdiutil create -fs 'HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

	hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

	create_test_file_entries "/Volumes/TestVolume";

	# Create additional files
	for NUMBER in `seq 2 ${NUMBER_OF_FILES}`;
	do
		if test $(( ${NUMBER} % 2 )) -eq 0;
		then
			touch /Volumes/TestVolume/testdir1/TestFile${NUMBER};
		else
			touch /Volumes/TestVolume/testdir1/testfile${NUMBER};
		fi
	done

	hdiutil detach disk${VOLUME_DEVICE_NUMBER};

	# Create raw disk image with a case-sensitive HFS+ file system
	IMAGE_NAME="hfsplus_${NUMBER_OF_FILES}_files_case_sensitive";

	hdiutil create -fs 'Case-sensitive HFS+' -size ${IMAGE_SIZE} -type UDIF -volname TestVolume ${SPECIMENS_PATH}/${IMAGE_NAME};

	hdiutil attach ${SPECIMENS_PATH}/${IMAGE_NAME}.dmg;

	create_test_file_entries "/Volumes/TestVolume";

	# Create additional files
	for NUMBER in `seq 2 ${NUMBER_OF_FILES}`;
	do
		if test $(( ${NUMBER} % 2 )) -eq 0;
		then
			touch /Volumes/TestVolume/testdir1/TestFile${NUMBER};
		else
			touch /Volumes/TestVolume/testdir1/testfile${NUMBER};
		fi
	done

	hdiutil detach disk${VOLUME_DEVICE_NUMBER};
done

exit ${EXIT_SUCCESS};

