#!/bin/sh

SWAPSIZE_MB=${1:-1024}
if [ "x$SWAPSIZE_MB" != "x0" ]; then
	sudo sed -i 's/^CONF_SWAPSIZE=.*$/CONF_SWAPSIZE=$SWAPSIZE_MB/' /etc/dphys-swapfile
	sudo systemctl restart dphys-swapfile.service
else
	sudo systemctl stop    dphys-swapfile.service
	sudo systemctl disable dphys-swapfile.service
fi

