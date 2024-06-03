#!/bin/sh

sudo -i -u hal9000 podman pod exists hal9000
if [ $? -ne 0 ]; then
	echo "ERROR: pod 'hal9000' does not exist"
	exit 1 
fi

echo "Generating systemd files (in ~hal9000/.config/systemd/user)..."
sudo -i -u hal9000 test -d ~hal9000/.config/systemd/user
if [ $? -ne 0 ]; then
	sudo -i -u hal9000 mkdir -p ~hal9000/.config/systemd/user
fi
sudo -i -u hal9000 sh -c "cd ~hal9000/.config/systemd/user ; \
                          podman generate systemd -n -f --start-timeout 5 --stop-timeout 5 hal9000"

echo "Reloading systemd (user instance)..."
sudo -i -u hal9000 systemctl --user daemon-reload

echo "Enabling pod-hal9000.service in systemd (user instance)..."
sudo -i -u hal9000 systemctl --user enable pod-hal9000.service

