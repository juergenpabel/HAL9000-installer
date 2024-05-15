#!/bin/bash

HAL9000_HARDWARE_VENDOR="${1:-unknown}"
HAL9000_HARDWARE_PRODUCT="${2:-unknown}"
HAL9000_PLATFORM_ARCH="${3:-unknown}"
HAL9000_PLATFORM_OS="${4:-unknown}"

if [ "$HAL9000_HARDWARE_VENDOR" == "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/sys_vendor ]; then
		HAL9000_HARDWARE_VENDOR=`cat /sys/devices/virtual/dmi/id/sys_vendor`
	fi
fi
if [ "$HAL9000_HARDWARE_PRODUCT" == "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/product_name ]; then
		HAL9000_HARDWARE_PRODUCT=`cat /sys/devices/virtual/dmi/id/product_name`
	fi
fi
if [ "$HAL9000_HARDWARE_VENDOR" == "unknown" ] && [ "$HAL9000_HARDWARE_PRODUCT" == "unknown" ]; then
	grep Model /proc/cpuinfo > /dev/null
	if [ $? -eq 0 ]; then
		HAL9000_MODEL=`cat /proc/cpuinfo | grep Model | cut -d' ' -f2-`
		if [ "${HAL9000_MODEL:0:12}" == "Raspberry Pi" ]; then
			HAL9000_HARDWARE_VENDOR="Raspberry Pi"
			HAL9000_HARDWARE_PRODUCT="${HAL9000_MODEL:13}"
			HAL9000_HARDWARE_PRODUCT="${HAL9000_HARDWARE_PRODUCT%% Rev *}"
		fi
	fi
fi

if [ "$HAL9000_PLATFORM_OS" == "unknown" ]; then
	case `/usr/bin/uname -o` in
		GNU/Linux)
			HAL9000_PLATFORM_OS="linux"
			;;
		*)
			echo "ERROR: unknown operating system, please add mapping to this script and run again"
			;;
	esac
fi

if [ "$HAL9000_PLATFORM_ARCH" == "unknown" ]; then
	case `/usr/bin/uname -m` in
		aarch64)
			HAL9000_PLATFORM_ARCH="arm64"
			;;
		x86_64)
			HAL9000_PLATFORM_ARCH="amd64"
			;;
		*)
			echo "ERROR: unknown hardware platform, please add mapping to this script and run again"
			;;
	esac
fi

echo "Hardware Vendor:  $HAL9000_HARDWARE_VENDOR"
echo "Hardware Product: $HAL9000_HARDWARE_PRODUCT"
echo "System Arch:      $HAL9000_PLATFORM_ARCH"
echo "System OS:        $HAL9000_PLATFORM_OS"

python -m venv .venv
. .venv/bin/activate

export HAL9000_HARDWARE_VENDOR
export HAL9000_HARDWARE_PRODUCT
export HAL9000_PLATFORM_ARCH
export HAL9000_PLATFORM_OS

pip install -q -r requirements.txt
python installer/HAL9000.py

