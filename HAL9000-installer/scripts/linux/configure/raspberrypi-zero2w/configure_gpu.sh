#!/bin/sh

RPI_GPU_MB=${1:-16}

if [ -f /boot/firmware/config.txt ]; then
	grep -q '^gpu_mem=' /boot/firmware/config.txt >/dev/null
	if [ $? -eq 0 ]; then
		sudo sed -i "s/^gpu_mem=[[:digit:]]\\+\$/gpu_mem=${RPI_GPU_MB}/" /boot/firmware/config.txt
	else
		sudo sh -c "echo \"gpu_mem=${RPI_GPU_MB}\" >> /boot/firmware/config.txt"
	fi
fi

