#!/bin/sh

RPI_MAX_CPUS=${1:-2}

if [ -f /boot/firmware/cmdline.txt ]; then
	grep -q 'maxcpus=' /boot/firmware/cmdline.txt >/dev/null
	if [ $? -ne 0 ]; then
		sudo sed -i "s/\$/ maxcpus=${RPI_MAX_CPUS}/" /boot/firmware/cmdline.txt
	else
		sudo sed -i "s/ maxcpus=[[:digit:]]\\+/ maxcpus=${RPI_MAX_CPUS}/" /boot/firmware/cmdline.txt
	fi
fi

