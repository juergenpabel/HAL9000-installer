#!/bin/sh

DEVICE_ID=${1:-1}
echo "HAL9000: Configuring udev for ALSA:HAL9000..."
sudo sh -c 'echo "SUBSYSTEM!=\"sound\", GOTO=\"hal9000_alsa_end\""           >  /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ACTION!=\"add|change\", GOTO=\"hal9000_alsa_end\""         >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "KERNEL==\"controlC'${DEVICE_ID}'\", ATTR{id}=\"HAL9000\""  >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "LABEL=\"hal9000_alsa_end\""                                >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo udevadm control --reload-rules
sudo udevadm trigger

