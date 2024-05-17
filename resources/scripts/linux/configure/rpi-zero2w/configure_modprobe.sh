#!/bin/sh

sudo sh -c 'stat /etc/modprobe.d/hal9000-blacklist.conf 2>/dev/null >/dev/null'
if [ $? -ne 0 ]; then
	sudo sh -c 'echo "blacklist ftdi_sio" >> /etc/modprobe.d/hal9000-blacklist.conf'
	sudo sh -c 'echo "blacklist vc4"      >> /etc/modprobe.d/hal9000-blacklist.conf'
fi

