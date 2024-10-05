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

echo "HAL9000: Downloading firmware and filesystem (version '${HAL9000_INSTALL_VERSION}') for '${HAL9000_ARDUINO_ID}' from github..."
SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "${SCRIPT_SRC}"`

"${SCRIPT_DIR}"/download_firmware.sh   "${HAL9000_ARDUINO_ID}" "${HAL9000_INSTALL_VERSION}"
"${SCRIPT_DIR}"/download_filesystem.sh "${HAL9000_ARDUINO_ID}" "${HAL9000_INSTALL_VERSION}"

