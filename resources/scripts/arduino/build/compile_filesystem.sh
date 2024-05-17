#!/bin/sh

HARDWARE_ARDUINO_VENDOR="${1:-SBComponents}"
HARDWARE_ARDUINO_PRODUCT="${2:-RoundyPi}"

PIO_TARGET_ENV=`echo "$HARDWARE_ARDUINO_VENDOR-$HARDWARE_ARDUINO_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

echo "HAL9000: Compiling arduino firmware..."
cd "${GIT_DIR}"
git submodule update --init resources/repositories/HAL9000
cd "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino"

if [ ! -d .venv ]; then
	echo "ERROR: no python virtual-env in '${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv'"
	exit 1
fi

. .venv/bin/activate
pio run -j 1 -e "$PIO_TARGET_ENV" -t buildfs

