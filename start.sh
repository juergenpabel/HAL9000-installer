#!/bin/bash

echo "#############################################################"
echo "#                     HAL9000 Installer                     #"
echo "#############################################################"
echo "Detecting system configuration..."
HAL9000_HARDWARE_VENDOR="${1:-unknown}"
HAL9000_HARDWARE_PRODUCT="${2:-unknown}"
HAL9000_PLATFORM_ARCH="${3:-unknown}"
HAL9000_PLATFORM_OS="${4:-unknown}"
HAL9000_ARDUINO_VENDOR="${5:-unknown}"
HAL9000_ARDUINO_PRODUCT="${6:-unknown}"

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

if [ "$HAL9000_ARDUINO_VENDOR" == "unknown" ] || [ "$HAL9000_ARDUINO_PRODUCT" == "unknown" ]; then
	USB_DEVICES=`lsusb | cut -d' ' -f 6 | xargs echo`
	for USB_DEVICE in $USB_DEVICES; do
		case $USB_DEVICE in
			2e8a:TODO)
				HAL9000_ARDUINO_VENDOR="SBComponents"
				HAL9000_ARDUINO_PRODUCT="RoundyPi"
				;;
			2e8a:*)
				HAL9000_ARDUINO_VENDOR="RaspberryPi"
				HAL9000_ARDUINO_PRODUCT="RP2040"
				;;
			1a86:55d4)
				HAL9000_ARDUINO_VENDOR="M5Stack"
				HAL9000_ARDUINO_PRODUCT="Core2"
				;;
			*)
				;;
		esac
	done
fi

echo "- System Vendor:   $HAL9000_HARDWARE_VENDOR"
echo "- System Product:  $HAL9000_HARDWARE_PRODUCT"
echo "- System Arch:     $HAL9000_PLATFORM_ARCH"
echo "- System OS:       $HAL9000_PLATFORM_OS"
echo "- Arduino Vendor:  $HAL9000_ARDUINO_VENDOR"
echo "- Arduino Product: $HAL9000_ARDUINO_PRODUCT"

if [ ! -d .venv ]; then
	echo "Creating python virtual environment for the installer..."
	python3 -m venv .venv
fi
. .venv/bin/activate

export HAL9000_HARDWARE_VENDOR
export HAL9000_HARDWARE_PRODUCT
export HAL9000_PLATFORM_ARCH
export HAL9000_PLATFORM_OS
export HAL9000_ARDUINO_VENDOR
export HAL9000_ARDUINO_PRODUCT

echo "Installing dependencies in python virtual environment..."
pip install -q -r requirements.txt

echo "Starting the installer..."
python3 HAL9000-installer/HAL9000.py

if [ $? -eq 0 ]; then
	echo "Running post-installation checks..."
	id hal9000 2>&1 > /dev/null
	CHECK_USER=$?
	podman container exists hal9000-kalliope 2>&1 > /dev/null
	CHECK_CONTAINER=$?
	stat /etc/udev/rules.d/99-hal9000-alsa.rules 2>&1 > /dev/null
	CHECK_ALSA=$?
	stat /etc/udev/rules.d/99-hal9000-tty.rules 2>&1 > /dev/null
	CHECK_TTY=$?
	if [ $CHECK_USER -eq 0 ] && [ $CHECK_CONTAINER -eq 0 ] && [ $CHECK_ALSA -eq 0 ] && [ $CHECK_TTY -eq 0 ]; then
		echo "HAL9000: Good afternoon, gentlemen. I am (now) a HAL 9000 computer."
		echo " "
		echo "All post-installation checks have passed; reboot and enjoy!"
	else
		echo "HAL9000: I just picked up a fault in the AE-35 Unit."
		echo " "
		echo "Some post-installation checks have failed; did you run all installation steps?"
	fi
else
	echo "HAL9000: I just picked up a fault in the AE-35 Unit."
	echo " "
	echo "Something unexpected happened with the installer - please file a bug report at"
	echo "https://github.com/juergenpabel/HAL9000-installer/issues/new"
fi

