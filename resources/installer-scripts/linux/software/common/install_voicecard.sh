#!/bin/sh

echo "HAL9000: Downloading, building and installing soundcard driver (seeed-voicecard)..."

GIT_REPODIR=`git rev-parse --show-toplevel`

dpkg -s dkms 2>/dev/null >/dev/null
if [ $? -ne 0 ]; then
	echo "Installing software package 'dkms'..."
	sudo apt install -q -y dkms
fi

if [ -f /etc/voicecard/dkms.conf ]; then
	export `grep "^PACKAGE_NAME="    /etc/voicecard/dkms.conf | sed 's/"//g'`
	export `grep "^PACKAGE_VERSION=" /etc/voicecard/dkms.conf | sed 's/"//g'`
else
	export PACKAGE_NAME="seeed-voicecard"
	export PACKAGE_VERSION=""
fi
dkms status | grep "^${PACKAGE_NAME}/${PACKAGE_VERSION}" | grep -q "installed$"
if [ $? -eq 0 ]; then
	echo "NOTICE:  dkms module 'seeed-voicecard' already installed"
else
	if [ ! -d "${GIT_REPODIR}/resources/repositories/seeed-voicecard" ]; then
		git clone https://github.com/HinTak/seeed-voicecard "${GIT_REPODIR}/resources/repositories/seeed-voicecard"
	fi
	if [ ! -d "${GIT_REPODIR}/resources/repositories/seeed-voicecard" ]; then
		echo "ERROR: 'git clone ...' failed, probably an (yet?) unsupported kernel version"
		exit 1
	fi
	GIT_REPODIR="${GIT_REPODIR}/resources/repositories/seeed-voicecard"

	cd "${GIT_REPODIR}"
	git checkout v`uname -r | cut -d. -f1-2`
	if [ $? -ne 0 ]; then
		echo "ERROR: 'git checkout' of branch failed, probably an (yet?) unsupported kernel version"
		exit 1
	fi
	sudo ./install.sh
fi

# notes: 1. install dkms module on all installed kernels
#        2. dkms install with '--force' neccessary to replace non-functional module 'snd_soc_wm8960' from packaged kernel
export `grep "^PACKAGE_NAME="    /etc/voicecard/dkms.conf | sed 's/"//g'`
export `grep "^PACKAGE_VERSION=" /etc/voicecard/dkms.conf | sed 's/"//g'`
find /boot/ -maxdepth 1 -name 'vmlinuz-*v8' | sed 's#/boot/vmlinuz-##g' | while read KERNEL_VERSION ; do
	echo "HAL9000: Building kernel module for kernel ${KERNEL_VERSION} with dkms '${PACKAGE_NAME}/${PACKAGE_VERSION}'"
	sudo dkms install --force -m "${PACKAGE_NAME}" -v "${PACKAGE_VERSION}" -k "${KERNEL_VERSION}"
done
grep -q '^autoinstall_all_kernels="yes"$' /etc/dkms/framework.conf
if [ $? -eq 1 ]; then
	sudo sh -c 'echo "autoinstall_all_kernels=\"yes\"" >> /etc/dkms/framework.conf'
fi
# notes: 1a. update /etc/asound.conf (symlink to /etc/voicecard/asound_2mic.conf) for changed ALSA ID
#        1b. update /var/lib/alsa/asound.state (symlink to /etc/voicecard/asound_wm8960.state) for changed ALSA ID
#        2. /etc/voicecard is a git repo, add and commit
echo "HAL9000: Changing ALSA ID in /etc/voicecard/"
sudo sed -i 's/seeed2micvoicec/HAL9000/g' /etc/voicecard/asound_*.conf
sudo sed -i 's/seeed2micvoicec/HAL9000/g' /etc/voicecard/*.state
sudo sh -c 'cd /etc/voicecard ; git add -u ; git commit -m "HAL9000: changed ALSA ID"'

