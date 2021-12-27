#!/bin/sh

CUSTOM_BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG=""
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# Pass an empty rootpath. genimage makes a full copy of the given rootpath to
# ${GENIMAGE_TMP}/root so passing TARGET_DIR would be a waste of time and disk
# space. We don't rely on genimage to build the rootfs image, just to insert a
# pre-built one in the disk image.

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

echo "Post-image: processing $@"

# Process custom args
for arg in "$@"
do
	case "${arg}" in
		--genimage0)
			GENIMAGE_CFG="${CUSTOM_BOARD_DIR}/genimage0.cfg"
			echo "Genimage set to genimage0.cfg"
		;;
	esac
done

# Override cmdline.txt
cat << __EOF__ > "${BINARIES_DIR}/rpi-firmware/cmdline.txt"
console=ttyAMA0,115200 ipv6.disable=1 consoleblank=0 vt.global_cursor_default=0 logo.nologo ignore_loglevel root=/dev/mmcblk0p2 rootwait
__EOF__

# Override config.txt
cat << __EOF__ > "${BINARIES_DIR}/rpi-firmware/config.txt"
start_file=start.elf
fixup_file=fixup.dat
kernel=zImage
dtoverlay=miniuart-bt
gpu_mem_256=128
gpu_mem_512=196
gpu_mem_1024=384
dtoverlay=krnbt=on
dtparam=audio=on
boot_delay=0
disable_splash=1
enable_uart=1
__EOF__

# Create empty video.txt
touch ${BINARIES_DIR}/video.txt

echo "Generating SD image"
rm -rf "${GENIMAGE_TMP}"

genimage                           \
	--rootpath "${ROOTPATH_TMP}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
  --config "${GENIMAGE_CFG}"

exit $?

