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

echo "HAL9000: Compiling arduino filesystem..."
GIT_DIR=`git rev-parse --show-toplevel`

cd "${GIT_DIR}/resources/repositories/HAL9000/"
git checkout --quiet "${HAL9000_INSTALL_VERSION}"
cd "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/"
if [ ! -d .venv ]; then
	echo "ERROR: no python virtual-env in '${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv'"
	echo "       run '${GIT_DIR}/HAL9000-installer/scripts/arduino/build/prepare_buildenv.sh' first"
	exit 1
fi

. .venv/bin/activate
pio run -j 1 -e "${HAL9000_ARDUINO_ID}" -t buildfs

