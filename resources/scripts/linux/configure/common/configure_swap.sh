#!/bin/sh

SWAPSIZE_MB=${1:-1024}
if [ "x$SWAPSIZE_MB" != "x0" ]; then
	sudo sed -i 's/^CONF_SWAPSIZE=[[:digit:]]\\+\$/CONF_SWAPSIZE=${SWAPSIZE_MB}/' /etc/dphys-swapfile
	sudo systemctl restart dphys-swapfile.service
	sudo sh -c "echo 'vm.swappiness=0' > /etc/sysctl.d/99-hal9000-swappiness.conf"
else
	sudo systemctl stop    dphys-swapfile.service
	sudo systemctl disable dphys-swapfile.service
fi

