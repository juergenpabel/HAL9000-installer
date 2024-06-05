#!/bin/sh

HAL9000_ARDUINO_ID="${1:-unknown}"
HAL9000_INSTALL_VERSION="${2:-unknown}"

if [ "${HAL9000_ARDUINO_ID}" = "unknown" ]; then
	echo "Usage: $0 <ARDUINO-ID> <FIRMWARE-VERSION>"
	echo "       - ARDUINO-ID: something like 'm5stack-core2' or 'sbcomponents-roundypi'"
	echo "       - FIRMWARE-VERSION: something like 'stable' or 'development'"
	exit 1
fi
if [ "${HAL9000_INSTALL_VERSION}" = "unknown" ]; then
	echo "Usage: $0 '${HAL9000_ARDUINO_ID}' <FIRMWARE-VERSION>"
	echo "       - FIRMWARE-VERSION: something like 'stable' or 'development'"
	exit 1
fi

echo "HAL9000: Downloading filesystem version '${HAL9000_INSTALL_VERSION}' for '${HAL9000_ARDUINO_ID}'..."
GIT_DIR=`git rev-parse --show-toplevel`

if [ ! -f "${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_littlefs_${HAL9000_INSTALL_VERSION}.bin" ]; then
	wget -q --show-progress -O "${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_littlefs_${HAL9000_INSTALL_VERSION}.bin" \
	     "https://github.com/juergenpabel/HAL9000/releases/download/${HAL9000_INSTALL_VERSION}/${HAL9000_ARDUINO_ID}_littlefs.bin"
	if [ $? -ne 0 ]; then
		echo "ERROR: Download failed"
		exit 1
	fi
fi

