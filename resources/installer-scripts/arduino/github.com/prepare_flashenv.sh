#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

HAL9000_PLATFORM_ARCH="${HAL9000_PLATFORM_ARCH:-unknown}"
HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"

HAL9000_ARDUINO_MCU="unknown"
HAL9000_ARDUINO_RP2040TOOLS_VERSION="1.0.6"
HAL9000_ARDUINO_ESPTOOLS_VERSION="4.7.0"

if [ "$HAL9000_PLATFORM_ARCH" = "unknown" ]; then
	echo "ERROR: HAL9000_PLATFORM_ARCH not set (or 'unknown')"
	exit 1
fi

case "${HAL9000_ARDUINO_VENDOR}:${HAL9000_ARDUINO_PRODUCT}" in
	"SBComponents:RoundyPi" | "Waveshare:RP2040_LCD128")
		HAL9000_ARDUINO_MCU="RP2040"
		;;
	"M5Stack:Core2")
		HAL9000_ARDUINO_MCU="ESP32"
		;;
	*)
		;;
esac

if [ "$HAL9000_ARDUINO_MCU" = "unknown" ]; then
	echo "ERROR: unknown MCU (probably missing HAL9000_ARDUINO_VENDOR and HAL9000_ARDUINO_PRODUCT?)"
	exit 1
fi

echo "HAL9000: Preparing environment for flashing '$HAL9000_ARDUINO_VENDOR: $HAL9000_ARDUINO_PRODUCT'..."

case "$HAL9000_ARDUINO_MCU" in
	"RP2040")
		if [ ! -x "${GIT_DIR}/resources/downloads/picotool" ]; then
			VERSION="$HAL9000_ARDUINO_RP2040TOOLS_VERSION"
			ARCH="$HAL9000_PLATFORM_ARCH"

			if [ ! -f "${GIT_DIR}/resources/downloads/rp2040tools-${VERSION}-linux_${ARCH}.tar.bz2" ]; then
				wget -q --show-progress -O "${GIT_DIR}/resources/downloads/rp2040tools-${VERSION}-linux_${ARCH}.tar.bz2" \
				     "https://github.com/arduino/rp2040tools/releases/download/${VERSION}/rp2040tools-${VERSION}-linux_${ARCH}.tar.bz2"
				if [ $? -ne 0 ]; then
					echo "ERROR: Download failed"
					exit 1
				fi
			fi
			if [ ! -d "${GIT_DIR}/resources/downloads/tools_linux_${ARCH}" ]; then
				tar xf "${GIT_DIR}/resources/downloads/rp2040tools-${VERSION}-linux_${ARCH}.tar.bz2" --directory "${GIT_DIR}/resources/downloads/"
			fi
			if [ ! -d "${GIT_DIR}/resources/downloads/tools_linux_${ARCH}" ]; then
				echo "ERROR: tar extract failed"
				exit 1
			fi
			if [ ! -x "${GIT_DIR}/resources/downloads/picotool" ]; then
				ln -s "tools_linux_${ARCH}/picotool"   "${GIT_DIR}/resources/downloads/picotool"
			fi
		fi
	;;
	"ESP32")
		if [ ! -x "${GIT_DIR}/resources/downloads/esptool" ]; then
			VERSION="$HAL9000_ARDUINO_ESPTOOLS_VERSION"
			if [ "$HAL9000_PLATFORM_ARCH" = "amd64" ]; then
				ARCH="linux-$HAL9000_PLATFORM_ARCH"
			else
				ARCH="$HAL9000_PLATFORM_ARCH"
			fi

			if [ ! -f "${GIT_DIR}/resources/downloads/esptool-v${VERSION}-${ARCH}.zip" ]; then
				wget -q --show-progress -O "${GIT_DIR}/resources/downloads/esptool-v${VERSION}-${ARCH}.zip" \
				     "https://github.com/espressif/esptool/releases/download/v${VERSION}/esptool-v${VERSION}-${ARCH}.zip"
				if [ $? -ne 0 ]; then
					echo "ERROR: Download failed"
					exit 1
				fi
			fi
			if [ ! -d "${GIT_DIR}/resources/downloads/esptool-${ARCH}" ]; then
				unzip -q "${GIT_DIR}/resources/downloads/esptool-v${VERSION}-${ARCH}.zip" -d "${GIT_DIR}/resources/downloads/"
				chmod +x "${GIT_DIR}/resources/downloads/esptool-${ARCH}/esptool"
			fi
			if [ ! -d "${GIT_DIR}/resources/downloads/esptool-${ARCH}" ]; then
				echo "ERROR: unzip extract failed"
				exit 1
			fi
			if [ ! -x "${GIT_DIR}/resources/downloads/esptool" ]; then
				ln -s "esptool-${ARCH}/esptool" "${GIT_DIR}/resources/downloads/esptool"
			fi
		fi
	;;
	*)
		echo "ERROR: unsupported microcontroller chip '$HAL9000_ARDUINO_MCU'"
		exit 1
esac

