#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"

FIRMWARE_VERSION="${1:-unknown}"
HAL9000_PIO_NAME=`echo "$HAL9000_ARDUINO_VENDOR-$HAL9000_ARDUINO_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`

if [ "$FIRMWARE_VERSION" = "unknown" ]; then
	echo "Usage: $0 <FIRMWARE-VERSION> # most likely 'stable' or 'development'"
	exit 1
fi

echo "HAL9000: Flashing filesystem '${FIRMWARE_VERSION}' on '$HAL9000_ARDUINO_VENDOR: $HAL9000_ARDUINO_PRODUCT'..."

case "${HAL9000_ARDUINO_VENDOR}:${HAL9000_ARDUINO_PRODUCT}" in
	"SBComponents:RoundyPi" | "Waveshare:RP2040_LCD128")
		if [ ! -x "${GIT_DIR}/resources/downloads/picotool" ]; then
			echo "ERROR: missing picotool (${GIT_DIR}/resources/downloads/picotool)"
			exit 1
		fi
		"${GIT_DIR}/resources/downloads/picotool" load --verify -t bin --offset 0x1003f000 \
		                                          "${GIT_DIR}/resources/downloads/${HAL9000_PIO_NAME}_littlefs_${FIRMWARE_VERSION}.bin"
		;;
	"M5Stack:Core2")
		if [ ! -x "${GIT_DIR}/resources/downloads/esptool" ]; then
			echo "ERROR: missing esptool (${GIT_DIR}/resources/downloads/esptool)"
			exit 1
		fi
		"${GIT_DIR}/resources/downloads/esptool" --chip esp32 --port "/dev/ttyHAL9000" --baud 460800 \
		                                         --before default_reset --after hard_reset \
		                                         write_flash -z --flash_mode dio --flash_freq 40m --flash_size 16MB \
		                                         0x200000 "${GIT_DIR}/resources/downloads/${HAL9000_PIO_NAME}_littlefs_${FIRMWARE_VERSION}.bin"
		;;
	*)
		echo "ERROR: unknown MCU (probably missing HAL9000_ARDUINO_VENDOR and HAL9000_ARDUINO_PRODUCT?)"
		exit 1
		;;
esac

