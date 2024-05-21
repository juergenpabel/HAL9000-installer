#!/bin/sh

echo "Preparing build environment..."

dpkg -s podman 2>/dev/null >/dev/null
if [ $? -ne 0 ]; then
	sudo apt install -y podman
fi

sudo loginctl enable-linger hal9000 >/dev/null

