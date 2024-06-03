#!/bin/sh

HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"

PIO_TARGET_ENV=`echo "$HAL9000_ARDUINO_VENDOR-$HAL9000_ARDUINO_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

if [ "$HAL9000_ARDUINO_VENDOR" = "unknown" ] || [ "$HAL9000_ARDUINO_PRODUCT" = "unknown" ]; then
	echo "ERROR: missing HAL9000_ARDUINO_VENDOR and/or HAL9000_ARDUINO_PRODUCT env vars"
	exit 1
fi

echo "HAL9000: Compiling arduino firmware..."

cd "${GIT_DIR}"
git submodule update --init resources/repositories/HAL9000

if [ ! -d "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv" ]; then
	echo "ERROR: no python virtual-env in '${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv'"
	exit 1
fi

. "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv/bin/activate"
cd "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino"
pio run -j 1 -e "$PIO_TARGET_ENV"

