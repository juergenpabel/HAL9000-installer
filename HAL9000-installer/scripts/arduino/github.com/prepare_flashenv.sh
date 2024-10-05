#!/bin/sh

HAL9000_ARDUINO_ID="${1:-unknown}"

if [ "${HAL9000_ARDUINO_ID}" = "unknown" ]; then
	echo "Usage: $0 <ARDUINO-ID>"
	echo "       - ARDUINO-ID: something like 'm5stack-core2' or 'sbcomponents-roundypi'"
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
		echo "\e[31mERROR\e[0m: arduino-board id, please add mapping to this script and run again"
		exit 1
		;;
esac

case `/usr/bin/uname -m` in
	aarch64)
		SYSTEM_PLATFORM_ARCH="arm64"
		;;
	x86_64)
		SYSTEM_PLATFORM_ARCH="amd64"
		;;
	*)
		echo "\e[31mERROR\e[0m: unsupported hardware platform"
		exit 1
		;;
esac


echo "HAL9000: Preparing environment for flashing '${HAL9000_ARDUINO_ID}'..."
GIT_DIR=`git rev-parse --show-toplevel`

case "${HAL9000_ARDUINO_MCU}" in
	"RP2040")
		if [ ! -x "${GIT_DIR}/resources/downloads/picotool" ]; then
			VERSION="1.0.6"

			ARCH="${SYSTEM_PLATFORM_ARCH}"

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
			VERSION="4.7.0"
			if [ "${SYSTEM_PLATFORM_ARCH}" = "amd64" ]; then
				ARCH="linux-${SYSTEM_PLATFORM_ARCH}"
			else
				ARCH="${SYSTEM_PLATFORM_ARCH}"
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
esac

