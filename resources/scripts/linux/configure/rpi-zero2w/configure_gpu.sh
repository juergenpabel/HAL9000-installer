#!/bin/sh

grep -q '^gpu_mem=' /boot/firmware/config.txt >/dev/null
if [ $? -eq 0 ]; then
	sudo sed -i 's/^gpu_mem=\d+$/gpu_mem=16/' /boot/firmware/config.txt
else
	sudo sh -c 'echo \"gpu_mem=16\" >> /boot/firmware/config.txt'
fi

