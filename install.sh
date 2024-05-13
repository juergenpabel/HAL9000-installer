#!/bin/bash

SYSTEM_HARDWARE_VENDOR="${1:-unknown}"
SYSTEM_HARDWARE_PRODUCT="${2:-unknown}"
SYSTEM_PLATFORM_ARCH="${3:-unknown}"
SYSTEM_PLATFORM_OS="${4:-unknown}"

if [ "$SYSTEM_HARDWARE_VENDOR" == "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/sys_vendor ]; then
		SYSTEM_HARDWARE_VENDOR=`cat /sys/devices/virtual/dmi/id/sys_vendor`
	fi
fi
if [ "$SYSTEM_HARDWARE_PRODUCT" == "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/product_name ]; then
		SYSTEM_HARDWARE_PRODUCT=`cat /sys/devices/virtual/dmi/id/product_name`
	fi
fi
if [ "$SYSTEM_HARDWARE_VENDOR" == "unknown" ] && [ "$SYSTEM_HARDWARE_PRODUCT" == "unknown" ]; then
	grep Model /proc/cpuinfo > /dev/null
	if [ $? -eq 0 ]; then
		SYSTEM_MODEL=`cat /proc/cpuinfo | grep Model | cut -d' ' -f2-`
		if [ "${SYSTEM_MODEL:0:12}" == "Raspberry Pi" ]; then
			SYSTEM_HARDWARE_VENDOR="Raspberry Pi"
			SYSTEM_HARDWARE_PRODUCT="${SYSTEM_MODEL:13}"
			SYSTEM_HARDWARE_PRODUCT="${SYSTEM_HARDWARE_PRODUCT%% Rev *}"
		fi
	fi
fi

if [ "$SYSTEM_PLATFORM_OS" == "unknown" ]; then
	case `/usr/bin/uname -o` in
		GNU/Linux)
			SYSTEM_PLATFORM_OS="linux"
			;;
		*)
			echo "ERROR: unknown operating system, please add mapping to this script and run again"
			;;
	esac
fi

if [ "$SYSTEM_PLATFORM_ARCH" == "unknown" ]; then
	case `/usr/bin/uname -m` in
		aarch64)
			SYSTEM_PLATFORM_ARCH="arm64"
			;;
		x86_64)
			SYSTEM_PLATFORM_ARCH="amd64"
			;;
		*)
			echo "ERROR: unknown hardware platform, please add mapping to this script and run again"
			;;
	esac
fi


echo "Hardware Vendor:  $SYSTEM_HARDWARE_VENDOR"
echo "Hardware Product: $SYSTEM_HARDWARE_PRODUCT"
echo "System Arch:      $SYSTEM_PLATFORM_ARCH"
echo "System OS:        $SYSTEM_PLATFORM_OS"

python -m venv .venv
. .venv/bin/activate

pip install -q -r requirements.txt
python installer/HAL9000.py
