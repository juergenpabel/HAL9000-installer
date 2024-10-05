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

case "${HAL9000_ARDUINO_ID}" in
	"sbcomponents-roundypi" | "waveshare-rp2040_lcd128")
		HAL9000_ARDUINO_MCU="RP2040"
		;;
	"m5stack-core2")
		HAL9000_ARDUINO_MCU="ESP32"
		;;
	*)
		echo "\e[31mERROR\e[0m: unsupported arduino board-id, please add mapping to this script and run again"
		exit 1
		;;
esac

echo "HAL9000: Flashing firmware '${HAL9000_INSTALL_VERSION}' on '${HAL9000_ARDUINO_ID}' (MCU='${HAL9000_ARDUINO_MCU}')..."
GIT_DIR=`git rev-parse --show-toplevel`

if [ ! -f "${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_firmware_${HAL9000_INSTALL_VERSION}.bin" ]; then
	echo "ERROR: firmware image not found: (${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_firmware_${HAL9000_INSTALL_VERSION}.bin)"
	exit 1
fi

case "${HAL9000_ARDUINO_MCU}" in
	"RP2040")
		if [ ! -x "${GIT_DIR}/resources/downloads/picotool" ]; then
			echo "ERROR: missing picotool (${GIT_DIR}/resources/downloads/picotool)"
			exit 1
		fi
		"${GIT_DIR}/resources/downloads/picotool" load --verify \
		                                          "${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_firmware_${HAL9000_INSTALL_VERSION}.bin" \
                                                          -t bin --offset 0x10000000
		;;
	"ESP32")
		if [ ! -x "${GIT_DIR}/resources/downloads/esptool" ]; then
			echo "ERROR: missing esptool (${GIT_DIR}/resources/downloads/esptool)"
			exit 1
		fi
		"${GIT_DIR}/resources/downloads/esptool" --chip esp32 --port "/dev/ttyHAL9000" --baud 460800 \
		                                         --before default_reset --after hard_reset \
		                                         write_flash -z --flash_mode dio --flash_freq 40m --flash_size 16MB \
		                                         0x1000 "${GIT_DIR}/resources/firmwares/ESP32/bootloader.bin" \
		                                         0x8000 "${GIT_DIR}/resources/firmwares/ESP32/partitions.bin" \
		                                         0xe000 "${GIT_DIR}/resources/firmwares/ESP32/boot_app0.bin" \
		                                         0x10000 "${GIT_DIR}/resources/downloads/${HAL9000_ARDUINO_ID}_firmware_${HAL9000_INSTALL_VERSION}.bin"
		;;
esac

