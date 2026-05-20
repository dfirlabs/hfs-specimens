#!/bin/bash
#
# Script to generate HFS, HFS+ and HFSX test files
# Requires Linux with dd, hformat and mkfs.hfsplus

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary hformat
assert_availability_binary mkfs.hfsplus
assert_availability_binary mknod

SPECIMENS_PATH="specimens/hformat"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

USERNAME=$( whoami )
CURRENT_GID=$( id -g )
CURRENT_UID=$( id -u )

MOUNT_POINT="/mnt/hfs"

sudo mkdir -p ${MOUNT_POINT}

set +e

sudo modprobe hfs
if test $? -ne 0
then
	echo "Missing kernel HFS support"
else
	set -e

	IMAGE_SIZE=$(( 1 * 1024 * 1024 ))
	SECTOR_SIZE=512

	# Create a case-insensitive HFS file system
	IMAGE_FILE="${SPECIMENS_PATH}/hfs.raw"

	echo "Creating: case-insensitive HFS"
	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

	hformat -f -l "hfs_test" ${IMAGE_FILE} 0

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

	create_test_file_entries_hfs ${MOUNT_POINT}

	sudo umount ${MOUNT_POINT}

	set +e
fi

SPECIMENS_PATH="specimens/mkfs.hfsplus"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

sudo modprobe hfsplus
if test $? -ne 0
then
	echo "Missing kernel HFS+/HFSX support"
else
	set -e

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus.raw"

	echo "Creating: case-insensitive HFS+"
	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

	mkfs.hfsplus -U ${UID} -v "hfsplus_test" ${IMAGE_FILE}

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

	create_test_file_entries ${MOUNT_POINT}

	sudo umount ${MOUNT_POINT}

	IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_case_sensitive.raw"

	echo "Creating: case-sensitive HFS+"
	dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

	mkfs.hfsplus -s -U ${UID} -v "hfsplus_test" ${IMAGE_FILE}

	sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

	create_test_file_entries ${MOUNT_POINT}

	sudo umount ${MOUNT_POINT}

	# Note that `mkfs.hfsplus -b 32768' currently segfaults.
	for BLOCK_SIZE in 512 1024 2048 4096 8192 16384
	do
		IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_block_${BLOCK_SIZE}.raw"

		echo "Creating: case-insensitive HFS+; block size: ${BLOCK_SIZE}"
		dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

		mkfs.hfsplus -b ${BLOCK_SIZE} -U ${UID} -v "hfsplus_test" ${IMAGE_FILE}

		sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

		create_test_file_entries ${MOUNT_POINT}

		sudo umount ${MOUNT_POINT}
	done

	# TODO: Create a HFS+ file system with different B-tree node sizes
	# mkfs.hfsplus -n

	set +e
fi

exit ${EXIT_SUCCESS}
