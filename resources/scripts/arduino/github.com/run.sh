#!/bin/sh

FIRMWARE_BASE_URL="https://github.com/juergenpabel/HAL9000/releases/download"
FIRMWARE_BOARD=${1:-roundypi}
FIRMWARE_TAG=${2:-stable}

echo "HAL9000: Downloading and flashing firmware..."
SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
$SCRIPT_DIR/download_image.sh  "${FIRMWARE_BASE_URL}/tag/${FIRMWARE_TAG}/arduino_${FIRMWARE_TAG}_${FIRMWARE_BOARD}.img"    "${SCRIPT_DIR}/downloads"
$SCRIPT_DIR/download_image.sh  "${FIRMWARE_BASE_URL}/tag/${FIRMWARE_TAG}/arduino_${FIRMWARE_TAG}_${FIRMWARE_BOARD}_fs.img" "${SCRIPT_DIR}/downloads"

$SCRIPT_DIR/flash_firmware.sh   "$FIRMWARE_BOARD" "$SCRIPT_DIR/downloads/arduino_${FIRMWARE_TAG}_${FIRMWARE_BOARD}.img"
$SCRIPT_DIR/flash_filesystem.sh "$FIRMWARE_BOARD" "$SCRIPT_DIR/downloads/arduino_${FIRMWARE_TAG}_${FIRMWARE_BOARD}_fs.img"

