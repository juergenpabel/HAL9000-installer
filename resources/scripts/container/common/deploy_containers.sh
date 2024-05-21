#!/bin/sh

sudo -i -u hal9000 podman pod exists hal9000
if [ $? -ne 0 ]; then
	echo "ERROR: pod 'hal9000' does not exist"
	exit 1 
fi

echo "Generating systemd files (in ~hal9000/.config/systemd/user)..."
sudo -i -u hal9000 sh -c 'mkdir -p ~hal9000/.config/systemd/user'
cd ~/.config/systemd/user
sudo -i -u hal9000 podman generate systemd -n -f --start-timeout 5 --stop-timeout 5 hal9000
cd - >/dev/null

echo "Reloading systemd (user instance)..."
sudo -i -u hal9000 systemctl --user daemon-reload

echo "Enabling pod-hal9000.service in systemd (user instance)..."
sudo -i -u hal9000 systemctl --user enable pod-hal9000.service

