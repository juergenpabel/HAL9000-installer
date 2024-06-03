#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"

HAL9000_FIRMWARE_VERSION="${1:-unknown}"

echo "HAL9000: Downloading firmware version '$HAL9000_FIRMWARE_VERSION' for '$HAL9000_ARDUINO_VENDOR: $HAL9000_ARDUINO_PRODUCT'..."

case "$HAL9000_ARDUINO_VENDOR:$HAL9000_ARDUINO_PRODUCT" in
	"SBComponents:RoundyPi")
		;;
	"M5Stack:Core2")
		;;
	*)
		echo "ERROR: unknown arduino board (probably missing HAL9000_ARDUINO_VENDOR and HAL9000_ARDUINO_PRODUCT?)"
		exit 1
		;;
esac


HAL9000_PIO_NAME=`echo "$HAL9000_ARDUINO_VENDOR-$HAL9000_ARDUINO_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
if [ ! -f "${GIT_DIR}/resources/downloads/${HAL9000_PIO_NAME}_firmware_${HAL9000_FIRMWARE_VERSION}.bin" ]; then
	wget -q --show-progress -O "${GIT_DIR}/resources/downloads/${HAL9000_PIO_NAME}_firmware_${HAL9000_FIRMWARE_VERSION}.bin" \
	     "https://github.com/juergenpabel/HAL9000/releases/download/${HAL9000_FIRMWARE_VERSION}/${HAL9000_PIO_NAME}_firmware.bin"
	if [ $? -ne 0 ]; then
		echo "ERROR: Download failed"
		exit 1
	fi
fi

