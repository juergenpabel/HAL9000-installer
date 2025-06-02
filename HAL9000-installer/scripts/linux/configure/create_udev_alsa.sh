#!/bin/sh

export ALSA_ID=${1:-unknown}
if [ "${ALSA_ID}" = "unknown" ]; then
	echo "Usage: $0 <ALSA-ID>"
	echo "       - ALSA-ID: the ID of the ALSA device to mount in the container"
	echo "                  (the value in the square-brackets in /proc/asound/cards)"
	exit 1
fi

echo "HAL9000: Configuring udev for ALSA:HAL9000..."

sudo sh -c 'echo "SUBSYSTEM!=\"sound\", GOTO=\"hal9000_alsa_end\""                                                                     >  /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ACTION!=\"add|change\", GOTO=\"hal9000_alsa_end\""                                                                   >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "                                                  RUN+=\"/usr/bin/mkdir -p             /dev/snd/HAL9000\""           >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ATTRS{id}==\"'${ALSA_ID}'\",KERNEL==\"card?\",    RUN+=\"/usr/bin/ln -f /dev/snd/timer /dev/snd/HAL9000/timer\""     >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ATTRS{id}==\"'${ALSA_ID}'\",KERNEL==\"controlC?\",RUN+=\"/usr/bin/ln -f /dev/snd/%k    /dev/snd/HAL9000/controlC0\"" >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ATTRS{id}==\"'${ALSA_ID}'\",KERNEL==\"pcmC?D?c\", RUN+=\"/usr/bin/ln -f /dev/snd/%k    /dev/snd/HAL9000/pcmC0D0c\""  >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ATTRS{id}==\"'${ALSA_ID}'\",KERNEL==\"pcmC?D?p\", RUN+=\"/usr/bin/ln -f /dev/snd/%k    /dev/snd/HAL9000/pcmC0D0p\""  >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "LABEL=\"hal9000_alsa_end\""                                                                                          >> /etc/udev/rules.d/99-hal9000-alsa.rules'

sudo udevadm control --reload-rules
sudo udevadm trigger

