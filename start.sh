#!/bin/sh

echo "#############################################################"
echo "#                     HAL9000 Installer                     #"
echo "#############################################################"

echo "Detecting system configuration..."
HAL9000_HARDWARE_VENDOR="${HAL9000_HARDWARE_VENDOR:-unknown}"
HAL9000_HARDWARE_PRODUCT="${HAL9000_HARDWARE_PRODUCT:-unknown}"
HAL9000_PLATFORM_ARCH="${HAL9000_PLATFORM_ARCH:-unknown}"
HAL9000_PLATFORM_OS="${HAL9000_PLATFORM_OS:-unknown}"
HAL9000_ARDUINO_VENDOR="${HAL9000_ARDUINO_VENDOR:-unknown}"
HAL9000_ARDUINO_PRODUCT="${HAL9000_ARDUINO_PRODUCT:-unknown}"

if [ "$HAL9000_HARDWARE_VENDOR" = "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/sys_vendor ]; then
		HAL9000_HARDWARE_VENDOR=`cat /sys/devices/virtual/dmi/id/sys_vendor`
	fi
	if [ -e /etc/armbian-image-release ]; then
		ARMBIAN_BOARD=`grep '^BOARD=' /etc/armbian-image-release | cut -d'=' -f 2`
		case $ARMBIAN_BOARD in
			orangepi*)
				HAL9000_HARDWARE_VENDOR="Orange Pi"
				;;
			*)
				;;
		esac
	fi
fi
if [ "$HAL9000_HARDWARE_PRODUCT" = "unknown" ]; then
	if [ -e /sys/devices/virtual/dmi/id/product_name ]; then
		HAL9000_HARDWARE_PRODUCT=`cat /sys/devices/virtual/dmi/id/product_name`
	fi
	if [ -e /etc/armbian-image-release ]; then
		ARMBIAN_BOARD=`grep '^BOARD=' /etc/armbian-image-release | cut -d'=' -f 2`
		case $ARMBIAN_BOARD in
			orangepizero2w)
				HAL9000_HARDWARE_PRODUCT="Zero 2W"
				;;
			*)
				;;
		esac
	fi
fi
if [ "$HAL9000_HARDWARE_VENDOR" = "unknown" ] && [ "$HAL9000_HARDWARE_PRODUCT" = "unknown" ]; then
	grep Model /proc/cpuinfo >/dev/null
	if [ $? -eq 0 ]; then
		SYS_MODEL=`cat /proc/cpuinfo | grep Model | cut -d' ' -f2-`
		if [ "x${SYS_MODEL}" != "x" ]; then
			SYS_RPI=`echo "$SYS_MODEL" | cut -c1-12`
			if [ "x${SYS_RPI}" = "xRaspberry Pi" ]; then
				HAL9000_HARDWARE_VENDOR="Raspberry Pi"
				SYS_RPI_ZERO2W=`echo "$SYS_MODEL" | cut -c14-21`
				if [ "x${SYS_RPI_ZERO2W}" = "xZero 2 W" ]; then
					HAL9000_HARDWARE_PRODUCT="Zero 2W"
				fi
			fi
		fi
	fi
fi

if [ "$HAL9000_PLATFORM_OS" = "unknown" ]; then
	case `/usr/bin/uname -o` in
		GNU/Linux)
			HAL9000_PLATFORM_OS="linux"
			;;
		*)
			echo "\e[31mERROR\e[0m: unknown operating system, please add mapping to this script and run again"
			;;
	esac
fi

if [ "$HAL9000_PLATFORM_ARCH" = "unknown" ]; then
	case `/usr/bin/uname -m` in
		aarch64)
			HAL9000_PLATFORM_ARCH="arm64"
			;;
		x86_64)
			HAL9000_PLATFORM_ARCH="amd64"
			;;
		*)
			echo "\e[31mERROR\e[0m: unknown hardware platform, please add mapping to this script and run again"
			exit 1
			;;
	esac
fi

if [ "$HAL9000_ARDUINO_VENDOR" = "unknown" ] || [ "$HAL9000_ARDUINO_PRODUCT" = "unknown" ]; then
	USB_DEVICES=`lsusb | cut -d' ' -f 6 | xargs echo`
	for USB_DEVICE in $USB_DEVICES; do
		case $USB_DEVICE in
			2e8a:000a)
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

USER_UID=`id -u`
if [ "$USER_UID" != "0" ]; then
	echo "Verifying sudo privileges..."
	echo "NOTICE: This installer requires sudo privileges (for users"
	echo "        'root' and 'hal9000') for various tasks, therefore"
	echo "        we now verify that sudo privileges are granted; the"
	echo "        command to verify this is: sudo -u root -l /bin/sh"
	echo "        Depending on your sudo configuration, it might be"
	echo "        neccessary to enter your password next."
	sudo -u root -l /bin/sh > /dev/null
	if [ $? -ne 0 ]; then
		echo "\e[31mERROR\e[0m:  Due to missing/unverifiable privileges for sudo"
		echo "        usage, the installer can not continue."
		exit 0
	fi
fi

echo "Checking required software packages (for this installer)..."
MISSING_SOFTWARE_PACKAGES=""
for SOFTWARE_PACKAGE in python3 python3-venv python3-pip-whl gcc libpython3-dev libasound2-dev polkitd ; do
	dpkg -s $SOFTWARE_PACKAGE 2>/dev/null >/dev/null
	if [ $? -ne 0 ]; then
		MISSING_SOFTWARE_PACKAGES="$SOFTWARE_PACKAGE $MISSING_SOFTWARE_PACKAGES"
	fi
done
if [ "x$MISSING_SOFTWARE_PACKAGES" != "x" ]; then
	echo "Installing missing software packages (for this installer)..."
	sudo apt install -y $MISSING_SOFTWARE_PACKAGES
fi

if [ ! -d .venv ]; then
	echo "Creating python virtual environment (for this installer)..."
	python3 -m venv .venv --symlinks
fi
. .venv/bin/activate

export HAL9000_SYSTEM_ID=`echo "$HAL9000_HARDWARE_VENDOR-$HAL9000_HARDWARE_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
export HAL9000_ARDUINO_ID=`echo "$HAL9000_ARDUINO_VENDOR-$HAL9000_ARDUINO_PRODUCT" | sed 's/ //g' | tr '[:upper:]' '[:lower:]'`
unset HAL9000_HARDWARE_VENDOR
unset HAL9000_HARDWARE_PRODUCT
unset HAL9000_PLATFORM_ARCH
unset HAL9000_PLATFORM_OS
unset HAL9000_ARDUINO_VENDOR
unset HAL9000_ARDUINO_PRODUCT

echo "Installing dependencies in python virtual environment..."
pip install -q -r requirements.txt

echo "Patching library incompatibilities in python virtual environment..."
patch --force --reject-file=- -strip=0 --silent < resources/patches/textual_terminal-colors.diff >/dev/null 2>/dev/null

echo "Starting the installer..."
python3 HAL9000-installer/HAL9000-installer.py

if [ $? -eq 0 ]; then
	echo "Running post-installation checks..."
	id hal9000 2>/dev/null >/dev/null
	CHECK_USER=$?
	pgrep -u hal9000 -f "/lib/systemd/systemd --user" >/dev/null
	CHECK_SYSTEMD=$?
	stat /etc/udev/rules.d/99-hal9000-alsa.rules 2>/dev/null >/dev/null
	CHECK_ALSA=$?
	stat /etc/udev/rules.d/99-hal9000-tty.rules 2>/dev/null >/dev/null
	CHECK_TTY=$?
	if [ $CHECK_USER -eq 0 ] && [ $CHECK_SYSTEMD -eq 0 ] && [ $CHECK_ALSA -eq 0 ] && [ $CHECK_TTY -eq 0 ]; then
		echo " "
		echo "\e[32mGood afternoon, gentlemen. I am (now) a HAL 9000 computer.\e[0m"
		echo " "
		echo "All post-installation checks have passed; please shutdown (power-off)"
		echo "the system (to fully reset the microcontroller) than power-on"
		echo "...and enjoy!"
		echo " "
		echo "For a quick guide on how to interact with this (demo) installation visit"
		echo "\e[90mhttps://github.com/juergenpabel/HAL9000-installer/wiki/Installation-finished\e[0m"
	else
		echo "\e[31mI just picked up a fault in the AE-35 Unit.\e[0m"
		echo " "
		echo "Some post-installation checks have failed; did you run all installation steps?"
		echo "Take a look at HAL9000-installer.log (output from all executed installation commands)"
	fi
else
	echo "\e[31mI just picked up a fault in the AE-35 Unit.\e[0m"
	echo " "
	echo "Something unexpected happened with the installer - please file a bug report at"
	echo "\e[90mhttps://github.com/juergenpabel/HAL9000-installer/issues/new\e[0m"
fi

