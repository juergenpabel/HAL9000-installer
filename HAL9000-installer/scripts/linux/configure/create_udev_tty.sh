#!/bin/sh

echo "HAL9000: Configuring udev for /dev/ttyHAL9000..."
if [ ! -f /etc/udev/rules.d/99-hal9000-tty.rules ]; then
        sudo sh -c 'echo "SUBSYSTEM!=\"tty\", GOTO=\"hal9000_tty_end\""                                   >>  /etc/udev/rules.d/99-hal9000-tty.rules'
        sudo sh -c 'echo "ACTION!=\"add|change\", GOTO=\"hal9000_tty_end\""                               >>  /etc/udev/rules.d/99-hal9000-tty.rules'
        sudo sh -c 'echo "ATTRS{idVendor}==\"2e8a\", ATTRS{idProduct}==\"000a\", SYMLINK+=\"ttyHAL9000\"" >>  /etc/udev/rules.d/99-hal9000-tty.rules'
        sudo sh -c 'echo "ATTRS{idVendor}==\"1a86\", ATTRS{idProduct}==\"55d4\", SYMLINK+=\"ttyHAL9000\"" >>  /etc/udev/rules.d/99-hal9000-tty.rules'
        sudo sh -c 'echo "LABEL=\"hal9000_tty_end\""                                                      >>  /etc/udev/rules.d/99-hal9000-tty.rules'
        sudo udevadm control --reload-rules
        sudo udevadm trigger
fi

