#!/bin/bash
#
# Script to generate HFS/HFS+/HFSX test files
# Requires Linux with dd, hformat and mkfs.hfsplus

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1;

	which ${BINARY} > /dev/null 2>&1;
	if test $? -ne ${EXIT_SUCCESS};
	then
		echo "Missing binary: ${BINARY}";
		echo "";

		exit ${EXIT_FAILURE};
	fi
}

# Creates test file entries on traditional HFS.
#
# Arguments:
#   a string containing the mount point of the image file
#
create_test_file_entries_hfs()
{
	MOUNT_POINT=$1;

	# Create an empty file
	touch ${MOUNT_POINT}/emptyfile

	# Create a directory
	mkdir ${MOUNT_POINT}/testdir1

	# Create a file
	echo "My file" > ${MOUNT_POINT}/testdir1/testfile1

	# Create a hard link to a file
	# ln: failed to create hard link: Operation not permitted

	# Create a symbolic link to a file
	# ln: failed to create symbolic link: Operation not permitted

	# Create a hard link to a directory
	# ln: hard link not allowed for directory

	# Create a symbolic link to a directory
	# ln: failed to create symbolic link: Operation not permitted

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

	# Create a file with a forward slash
	touch `printf "${MOUNT_POINT}/forward:slash"`

	# TODO: Create a file with a resource fork with content

	# Create a file with an extended attribute
        # setfattr: Operation not supported

	# Create a directory with an extended attribute
        # setfattr: Operation not supported

	# Create a file with an extended attribute that is not stored inline
        # setfattr: Operation not supported

	# TODO: create file that uses extents (overflow) file.
}

# Creates test file entries on HFS+/HFSX.
#
# Arguments:
#   a string containing the mount point of the image file
#
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
	# ln: hard link not allowed for directory

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

	# Create a file with a forward slash
	touch `printf "${MOUNT_POINT}/forward:slash"`

	# TODO: Create a file with a resource fork with content

	# Create a file with an extended attribute
	touch ${MOUNT_POINT}/testdir1/xattr1
	setfattr -n "user.myxattr1" -v "My 1st extended attribute" ${MOUNT_POINT}/testdir1/xattr1

	# Create a directory with an extended attribute
	mkdir ${MOUNT_POINT}/testdir1/xattr2
	setfattr -n "user.myxattr2" -v "My 2nd extended attribute" ${MOUNT_POINT}/testdir1/xattr2

	# Create a file with an extended attribute that is not stored inline
	# Note that the Linux HFS+ implementation does not suport creating extended attributes
	# that are not stored inline, this supports upto approximately 3800 bytes of value data.

	# TODO: create file that uses extents (overflow) file.
}

assert_availability_binary dd;
assert_availability_binary hformat;
assert_availability_binary mkfs.hfsplus;

CURRENT_GID=$( id -g );
CURRENT_UID=$( id -u );

MOUNT_POINT="/mnt/hfs";

sudo mkdir -p ${MOUNT_POINT};

DEFAULT_IMAGE_SIZE=$(( 1 * 1024 * 1024 ));

IMAGE_SIZE=${DEFAULT_IMAGE_SIZE};
SECTOR_SIZE=512;

SPECIMENS_PATH="specimens/hformat";

if test -d ${SPECIMENS_PATH};
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists.";

	exit ${EXIT_FAILURE};
fi

mkdir -p ${SPECIMENS_PATH};

set -e;

# Create a case-insensitive HFS file system
IMAGE_NAME="hfs.raw";
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

hformat -f -l "hfs_test" ${IMAGE_FILE} 0;

sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

create_test_file_entries_hfs ${MOUNT_POINT};

sudo umount ${MOUNT_POINT};

set +e;

SPECIMENS_PATH="specimens/mkfs.hfsplus";

if test -d ${SPECIMENS_PATH};
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists.";

	exit ${EXIT_FAILURE};
fi

mkdir -p ${SPECIMENS_PATH};

set -e;

# Create a case-insensitive HFS+ file system
IMAGE_NAME="hfsplus.raw";
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

mkfs.hfsplus -U ${UID} -v "hfsplus_test" ${IMAGE_FILE};

sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

create_test_file_entries ${MOUNT_POINT};

sudo umount ${MOUNT_POINT};

# Create a case-sensitive HFS+ file system
IMAGE_NAME="hfsplus_case_sensitive.raw";
IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

mkfs.hfsplus -s -U ${UID} -v "hfsplus_test" ${IMAGE_FILE};

sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

create_test_file_entries ${MOUNT_POINT};

sudo umount ${MOUNT_POINT};

# Create a HFS+ file system with different block sizes
# Note that `mkfs.hfsplus -b 32768' currently segfaults.
for BLOCK_SIZE in 512 1024 2048 4096 8192 16384;
do
	IMAGE_NAME="hfsplus_block_${BLOCK_SIZE}.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	mkfs.hfsplus -b ${BLOCK_SIZE} -U ${UID} -v "hfsplus_test" ${IMAGE_FILE};

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

	create_test_file_entries ${MOUNT_POINT};

	sudo umount ${MOUNT_POINT};
done

# TODO: Create a HFS+ file system with different B-tree node sizes
# mkfs.hfsplus -n

for NUMBER_OF_FILES in 100 1000 10000 100000;
do
	if test ${NUMBER_OF_FILES} -eq 100000;
	then
		IMAGE_SIZE=$(( 64 * 1024 * 1024 ));

	elif test ${NUMBER_OF_FILES} -eq 10000;
	then
		IMAGE_SIZE=$(( 8 * 1024 * 1024 ));
	else
		IMAGE_SIZE=$(( 1 * 1024 * 1024 ));
	fi

	# Create a case-insensitive HFS+ file system
	IMAGE_NAME="hfsplus_${NUMBER_OF_FILES}_files.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	mkfs.hfsplus -U ${UID} -v "hfsplus_test" ${IMAGE_FILE};

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

	sudo chown ${USERNAME} ${MOUNT_POINT};

	create_test_file_entries ${MOUNT_POINT};

	# Create additional files
	for NUMBER in `seq 3 ${NUMBER_OF_FILES}`;
	do
		if test $(( ${NUMBER} % 2 )) -eq 0;
		then
			touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER};
		else
			touch ${MOUNT_POINT}/testdir1/testfile${NUMBER};
		fi
	done

	sudo umount ${MOUNT_POINT};

	# Create a case-sensitive HFS+ file system
	IMAGE_NAME="hfsplus_${NUMBER_OF_FILES}_files_case_sensitive.raw"
	IMAGE_FILE="${SPECIMENS_PATH}/${IMAGE_NAME}";

	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null;

	mkfs.hfsplus -s -U ${UID} -v "hfsplus_test" ${IMAGE_FILE};

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT};

	sudo chown ${USERNAME} ${MOUNT_POINT};

	create_test_file_entries ${MOUNT_POINT};

	# Create additional files
	for NUMBER in `seq 3 ${NUMBER_OF_FILES}`;
	do
		if test $(( ${NUMBER} % 2 )) -eq 0;
		then
			touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER};
		else
			touch ${MOUNT_POINT}/testdir1/testfile${NUMBER};
		fi
	done

	sudo umount ${MOUNT_POINT};
done

exit ${EXIT_SUCCESS};

