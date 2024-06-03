#!/bin/sh

RPI_INITIAL_TURBO_SECS=${1:-30}

if [ -f /boot/firmware/config.txt ]; then
	grep -q '^initial_turbo=' /boot/firmware/config.txt >/dev/null
	if [ $? -eq 0 ]; then
		sudo sed -i "s/^initial_turbo=[[:digit:]]\\+\$/initial_turbo=${RPI_INITIAL_TURBO_SECS}/" /boot/firmware/config.txt
	else
		sudo sh -c "echo \"initial_turbo=${RPI_INITIAL_TURBO_SECS}\" >> /boot/firmware/config.txt"
	fi
fi

