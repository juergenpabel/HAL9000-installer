#!/bin/sh

HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"
HAL9000_PLATFORM_ARCH="${HAL9000_PLATFORM_ARCH:-unknown}"

if [ "$HAL9000_ARDUINO_VENDOR" = "unknown" ] || [ "$HAL9000_ARDUINO_PRODUCT" = "unknown" ]; then
        echo "ERROR: missing HAL9000_ARDUINO_VENDOR and/or HAL9000_ARDUINO_PRODUCT env vars"
        exit 1
fi
if [ "$HAL9000_PLATFORM_ARCH" = "unknown" ]; then
        echo "ERROR: missing HAL9000_PLATFORM_ARCH env var (most likely 'amd64' or 'arm64')"
        exit 1
fi

FIRMWARE_VERSION=${1:-unknown}
if [ "$FIRMWARE_VERSION" = "unknown" ]; then
        echo "Usage: $0 <FIRMWARE-VERSION> # most likely 'stable' or 'development'"
        exit 1
fi

echo "HAL9000: Downloading and flashing firmware (version '$FIRMWARE_VERSION') for '$HAL9000_ARDUINO_VENDOR: $HAL9000_ARDUINO_PRODUCT' from github..."

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/prepare_flashenv.sh

$SCRIPT_DIR/download_firmware.sh "${FIRMWARE_VERSION}"
$SCRIPT_DIR/download_filesystem.sh "${FIRMWARE_VERSION}"

$SCRIPT_DIR/flash_firmware.sh "${FIRMWARE_VERSION}"
$SCRIPT_DIR/flash_filesystem.sh "${FIRMWARE_VERSION}"

