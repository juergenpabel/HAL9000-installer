#!/bin/sh

KERNEL_SND_DEVICE_NR=${1:-unknown}
if [ "${KERNEL_SND_DEVICE_NR}" = "unknown" ]; then
	echo "Usage: $0 <SOUND-DEVICE-NR>"
	echo "       - SOUND-DEVICE-NR: the number of the kernel device (/dev/snd/controlC?) which to use"
	exit 1
fi

echo "HAL9000: Configuring udev for ALSA:HAL9000..."
sudo sh -c 'echo "SUBSYSTEM!=\"sound\", GOTO=\"hal9000_alsa_end\""                              >  /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "ACTION!=\"add|change\", GOTO=\"hal9000_alsa_end\""                            >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "KERNEL==\"controlC'${KERNEL_SND_DEVICE_NR}'\", ATTR{/device/id}=\"HAL9000\""  >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo sh -c 'echo "LABEL=\"hal9000_alsa_end\""                                                   >> /etc/udev/rules.d/99-hal9000-alsa.rules'
sudo udevadm control --reload-rules
sudo udevadm trigger

