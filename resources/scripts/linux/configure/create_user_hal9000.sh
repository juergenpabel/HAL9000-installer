#!/bin/sh

echo "HAL9000: Creating (non-privileged) user 'hal9000'..."
id hal9000 >/dev/null 2>/dev/null
if [ $? -eq 0 ]; then
	echo "HAL9000: User 'hal9000' already exists"
	exit 0
fi

sudo sh -c 'groupadd -g 9000 hal9000 > /dev/null'
sudo sh -c 'useradd -g hal9000 -G audio,dialout -m -s /bin/sh -u 9000 hal9000 > /dev/null'
sudo -u hal9000 -i sh -c 'echo "export XDG_RUNTIME_DIR=/run/user/9000" >> ~/.profile'

