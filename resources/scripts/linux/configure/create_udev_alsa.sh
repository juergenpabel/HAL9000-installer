#!/bin/sh

echo "HAL9000: Configuring udev for ALSA:HAL9000..."
if [ ! -f /etc/udev/rules.d/99-hal9000-alsa.rules ]; then
        sudo sh -c 'echo "SUBSYSTEM!=\"sound\", GOTO=\"hal9000_alsa_end\""                                              >> /etc/udev/rules.d/99-hal9000-alsa.rules'
        sudo sh -c 'echo "ACTION!=\"add\", GOTO=\"hal9000_alsa_end\""                                                   >> /etc/udev/rules.d/99-hal9000-alsa.rules'
        sudo sh -c 'echo "DEVPATH==\"/devices/platform/soc/soc:sound/sound/card?\", ATTR{id}=\"HAL9000\""               >> /etc/udev/rules.d/99-hal9000-alsa.rules'
        sudo sh -c 'echo "DEVPATH==\"/devices/pci0000:00/0000:00:08.1/0000:c1:00.6/sound/card?\", ATTR{id}=\"HAL9000\"" >> /etc/udev/rules.d/99-hal9000-alsa.rules'
        sudo sh -c 'echo "LABEL=\"hal9000_alsa_end\""                                                                   >> /etc/udev/rules.d/99-hal9000-alsa.rules'
        sudo udevadm control --reload-rules
        sudo udevadm trigger
fi

