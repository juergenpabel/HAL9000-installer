#!/bin/sh

echo "HAL9000: Downloading, building and installing soundcard driver (seeed-voicecard)..."

GIT_REPODIR=`git rev-parse --show-toplevel`

dpkg -s dkms 2>/dev/null >/dev/null
if [ $? -ne 0 ]; then
	echo "Installing software package 'dkms'..."
	sudo apt install -q -y dkms
fi

dkms status | grep "^seeed-voicecard/" | grep -q "installed$"
if [ $? -ne 0 ]; then
	if [ ! -d "$GIT_REPODIR/resources/repositories/seeed-voicecard" ]; then
		git clone https://github.com/HinTak/seeed-voicecard "$GIT_REPODIR/resources/repositories/seeed-voicecard"
	fi
	if [ ! -d "$GIT_REPODIR/resources/repositories/seeed-voicecard" ]; then
		echo "ERROR: 'git clone ...' failed, probably an (yet?) unsupported kernel version"
		exit 1
	fi
	GIT_REPODIR="$GIT_REPODIR/resources/repositories/seeed-voicecard"

	cd "$GIT_REPODIR"
	git checkout v`uname -r | cut -d. -f1-2`
	if [ $? -ne 0 ]; then
		echo "ERROR: 'git checkout' of branch failed, probably an (yet?) unsupported kernel version"
		exit 1
	fi
	sudo ./install.sh
else
	echo "NOTICE:  Already installed"
fi

