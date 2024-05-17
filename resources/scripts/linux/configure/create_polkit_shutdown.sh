#!/bin/sh

echo "HAL9000: Configuring polkit for system shutdown/reboot..."

sudo sh -c 'stat /etc/polkit-1/rules.d/99-hal9000-shutdown.js 2>/dev/null >/dev/null'
if [ $? -ne 0 ]; then
	sudo sh -c 'echo "/* Allow user hal9000 to reboot/poweroff */"                                        >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "polkit.addRule(function(action, subject) {"                                         >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "    if (subject.user == \"hal9000\") {"                                             >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "        if (action.id == \"org.freedesktop.login1.reboot\""                         >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "        ||  action.id == \"org.freedesktop.login1.reboot-multiple-sessions\""       >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "        ||  action.id == \"org.freedesktop.login1.power-off\""                      >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "        ||  action.id == \"org.freedesktop.login1.power-off-multiple-sessions\") {" >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "            return polkit.Result.YES;"                                              >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "        }"                                                                          >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "    }"                                                                              >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
	sudo sh -c 'echo "});"                                                                                >> /etc/polkit-1/rules.d/99-hal9000-shutdown.js'
fi

