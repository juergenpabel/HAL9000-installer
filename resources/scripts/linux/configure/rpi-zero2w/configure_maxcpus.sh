#!/bin/sh

grep -q 'maxcpus=' /boot/firmware/cmdline.txt >/dev/null
if [ $? -ne 0 ]; then
	sudo sed -i 's/$/ maxcpus=2/' /boot/firmware/cmdline.txt
fi

