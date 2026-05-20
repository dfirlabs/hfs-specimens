#!/bin/bash
#
# Script to generate HFS+ and HFSX test files, that contain many files
# Requires Linux with dd and mkfs.hfsplus

source ./shared_linux.sh

assert_availability_binary dd
assert_availability_binary mkfs.hfsplus
assert_availability_binary mknod

SPECIMENS_PATH="specimens/mkfs.hfsplus-many-files"

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

sudo modprobe hfsplus
if test $? -ne 0
then
	echo "Missing kernel HFS+/HFSX support"
else
	set -e

	SECTOR_SIZE=512

	for NUMBER_OF_FILES in 100 1000 10000 100000
	do
		if test ${NUMBER_OF_FILES} -eq 100000
		then
			IMAGE_SIZE=$(( 64 * 1024 * 1024 ))

		elif test ${NUMBER_OF_FILES} -eq 10000
		then
			IMAGE_SIZE=$(( 8 * 1024 * 1024 ))
		else
			IMAGE_SIZE=$(( 1 * 1024 * 1024 ))
		fi

		IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_FILES}_files.raw"

		echo "Creating: case-insensitive HFS+; with: ${NUMBER_OF_FILES} files"
		dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

		mkfs.hfsplus -U ${UID} -v "hfsplus_test" ${IMAGE_FILE}

		sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

		sudo chown ${USERNAME} ${MOUNT_POINT}

		create_test_file_entries ${MOUNT_POINT}

		# Create additional files
		for NUMBER in `seq 3 ${NUMBER_OF_FILES}`
		do
			if test $(( ${NUMBER} % 2 )) -eq 0
			then
				touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER}
			else
				touch ${MOUNT_POINT}/testdir1/testfile${NUMBER}
			fi
		done

		sudo umount ${MOUNT_POINT}

		IMAGE_FILE="${SPECIMENS_PATH}/hfsplus_${NUMBER_OF_FILES}_files_case_sensitive.raw"

		echo "Creating: case-sensitive HFS+; with: ${NUMBER_OF_FILES} files"
		dd if=/dev/zero of=${IMAGE_FILE} bs=${SECTOR_SIZE} count=$(( ${IMAGE_SIZE} / ${SECTOR_SIZE} )) 2> /dev/null

		mkfs.hfsplus -s -U ${UID} -v "hfsplus_test" ${IMAGE_FILE}

		sudo mount -o loop,rw,gid=${CURRENT_GID},uid=${CURRENT_UID} ${IMAGE_FILE} ${MOUNT_POINT}

		sudo chown ${USERNAME} ${MOUNT_POINT}

		create_test_file_entries ${MOUNT_POINT}

		# Create additional files
		for NUMBER in `seq 3 ${NUMBER_OF_FILES}`
		do
			if test $(( ${NUMBER} % 2 )) -eq 0
			then
				touch ${MOUNT_POINT}/testdir1/TestFile${NUMBER}
			else
				touch ${MOUNT_POINT}/testdir1/testfile${NUMBER}
			fi
		done

		sudo umount ${MOUNT_POINT}
	done
fi

exit ${EXIT_SUCCESS}
