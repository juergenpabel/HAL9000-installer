#!/bin/sh

USER_UID=`/usr/bin/id -u`
USER_NAME=`/usr/bin/id -un`

if [ "x$USER_NAME" != "xhal9000" ]; then
	echo "ERROR: this script should only be run as the 'hal9000' user"
	exit 1
fi

if [ "x$XDG_RUNTIME_DIR" == "x" ]; then
	echo "ERROR: for connecting with the user-instance of systemd, the"
	echo "       environment variable XDG_RUNTIME_DIR must be set:"
	echo "       export XDG_RUNTIME_DIR=/run/user/$USER_UID/"
	exit 1
fi

podman pod exists hal9000
if [ $? -ne 0 ]; then
	echo "ERROR: pod 'hal9000' does not exist"
	exit 1 
fi

LINGER=`loginctl list-users | grep "^$USER_UID " | cut -d' ' -f 3`
if [ "x$LINGER" != "xyes" ]; then
	loginctl enable-linger $USER_NAME
fi

echo "Generating systemd files (in ~/.config/systemd/user)..."
mkdir -p ~/.config/systemd/user
cd ~/.config/systemd/user
podman generate systemd -n -f --start-timeout 5 --stop-timeout 5 hal9000
cd - >/dev/null

echo "Reloading systemd (user instance)..."
systemctl --user daemon-reload

echo "Enabling pod-hal9000.service in systemd (user instance)..."
systemctl --user enable pod-hal9000.service

