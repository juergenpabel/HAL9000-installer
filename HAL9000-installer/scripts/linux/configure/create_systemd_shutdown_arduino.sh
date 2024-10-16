#!/bin/sh

echo "HAL9000: Creating systemd shutdown script for arduino poweroff..."
if [ ! -f /lib/systemd/system-shutdown/HAL9000-arduino-poweroff.shutdown ]; then
	( echo '#!/bin/bash' ; \
	  echo 'socat EXEC:"echo '\''[\"system/runlevel\", \"kill\"]'\''" OPEN:/dev/ttyHAL9000' \
	) | sudo tee /lib/systemd/system-shutdown/HAL9000-arduino-poweroff.shutdown > /dev/null
	sudo chmod 755 /lib/systemd/system-shutdown/HAL9000-arduino-poweroff.shutdown
fi
