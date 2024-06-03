#!/bin/sh

echo "HAL9000: Creating /etc/asound.conf if not existing..."
if [ ! -f /etc/asound.conf ]; then
        sudo touch /etc/asound.conf
fi

