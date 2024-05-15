#!/bin/bash

echo "HAL9000: Creating (non-privileged) user 'hal9000'..."
id hal9000 >/dev/null 2>/dev/null
if [ "$?" == "0" ]; then
	echo "User 'hal9000' already exists, exiting script"
	exit 1
fi
sudo groupadd -g 9000 hal9000 > /dev/null
sudo useradd -g hal9000 -G audio,dialout -m  -s /bin/bash -u 9000 hal9000  > /dev/null
sudo loginctl enable-linger hal9000  > /dev/null
sudo -u hal9000 -i sh -c 'echo "export XDG_RUNTIME_DIR=/run/user/9000" >> ~/.profile'

