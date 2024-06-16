#!/bin/sh

export PATH=/bin:/usr/bin

IMAGE_SRC="${1:-unknown}"
IMAGE_TAG="${2:-unknown}"

if [ "${IMAGE_SRC}" = "unknown" ] && [ "${IMAGE_TAG}" = "unknown" ]; then
	systemctl --user --quiet list-unit-files pod-hal9000.service > /dev/null
	case "$?" in
		0)
			exit 1 # exit code 'skip' for ExecCondition in HAL9000-installer.service
			;;
		1)
			exit 0 # exit code 'continue' for ExecCondition in HAL9000-installer.service
			;;
		*)
			exit 255 # exit code 'fail' for ExecCondition in HAL9000-installer.service
			;;
	esac
fi

if [ "${IMAGE_SRC}" = "unknown" ] || [ "${IMAGE_TAG}" = "unknown" ]; then
	exit 255 # exit code 'fail' for ExecCondition in HAL9000-installer.service (invalid invocation with only one parameter)
fi


DEVICE_TTYHAL9000_ARGS="--device /dev/ttyHAL9000:/dev/ttyHAL9000"
if [ ! -e /dev/ttyHAL9000 ]; then
	DEVICE_TTYHAL9000_ARGS=""
fi
SYSTEMD_TIMESYNC_ARGS="-v /run/systemd/timesync:/run/systemd/timesync:ro"
if [ ! -e /run/systemd/timesync ]; then
	SYSTEMD_TIMESYNC_ARGS=""
fi

podman network exists hal9000
if [ $? -ne 0 ]; then
	echo -n "Creating network 'hal9000':                 "
	podman network create hal9000
fi

echo -n "Creating pod 'hal9000':                 "
podman pod create --name hal9000 \
                  --infra-name hal9000-infra \
                  -p 127.0.0.1:5555:5000 \
                  -p 127.0.0.1:8888:8080 \
                  -p 127.0.0.1:9999:9000 \
                  --network hal9000 \
                  --hostname hal9000

echo -n "Creating container 'hal9000-mosquitto': "
podman create --pod=hal9000 --name=hal9000-mosquitto \
              --group-add=keep-groups \
              --tz=local \
              --pull=never \
              ${IMAGE_SRC}/hal9000-mosquitto:${IMAGE_TAG}

echo -n "Creating container 'hal9000-kalliope':  "
podman create --pod=hal9000 --name=hal9000-kalliope \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              --device /dev/snd:/dev/snd \
              -v /etc/asound.conf:/etc/asound.conf:ro \
              -v ~hal9000/HAL9000/kalliope:/kalliope/data:ro \
              --tz=local \
              --pull=never \
              ${IMAGE_SRC}/hal9000-kalliope:${IMAGE_TAG}

echo -n "Creating container 'hal9000-frontend':  "
podman create --pod=hal9000 --name=hal9000-frontend \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              -v ~hal9000/HAL9000/frontend:/frontend/data:ro \
              ${DEVICE_TTYHAL9000_ARGS} \
              --tz=local \
              --pull=never \
              ${IMAGE_SRC}/hal9000-frontend:${IMAGE_TAG}

echo -n "Creating container 'hal9000-brain':     "
podman create --pod=hal9000 --name=hal9000-brain \
              --requires hal9000-kalliope,hal9000-frontend \
              --group-add=keep-groups \
              --tz=local \
              -v ~hal9000/HAL9000/brain:/brain/data:ro \
              -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket:rw \
              ${SYSTEMD_TIMESYNC_ARGS} \
              --pull=never \
              ${IMAGE_SRC}/hal9000-brain:${IMAGE_TAG}

echo -n "Creating container 'hal9000-console':   "
podman create --pod=hal9000 --name=hal9000-console \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              -v ~hal9000/HAL9000/console:/console/data:ro \
              --tz=local \
              --pull=never \
              ${IMAGE_SRC}/hal9000-console:${IMAGE_TAG}

echo "Generating systemd files (in ~hal9000/.config/systemd/user)..."
test -d ~hal9000/.config/systemd/user
if [ $? -ne 0 ]; then
        mkdir -p ~hal9000/.config/systemd/user
fi
sh -c "cd ~hal9000/.config/systemd/user ; \
       podman generate systemd -n -f --start-timeout 5 --stop-timeout 5 hal9000"

echo "Creating pod-hal9000.socket..."
cp ~hal9000/.local/share/HAL9000-installer/pod-hal9000.socket \
   ~hal9000/.config/systemd/user/pod-hal9000.socket

echo "Creating socket-proxy for console in systemd (user instance)..."
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-console-proxy.socket \
   ~hal9000/.config/systemd/user/container-hal9000-console-proxy.socket
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-console-proxy.service \
   ~hal9000/.config/systemd/user/container-hal9000-console-proxy.service

echo "Creating socket-proxy for frontend in systemd (user instance)..."
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-frontend-proxy.service \
   ~hal9000/.config/systemd/user/container-hal9000-frontend-proxy.service
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-frontend-proxy.socket \
   ~hal9000/.config/systemd/user/container-hal9000-frontend-proxy.socket

echo "Creating socket-proxy for kalliope in systemd (user instance)..."
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-kalliope-proxy.service \
   ~hal9000/.config/systemd/user/container-hal9000-kalliope-proxy.service
cp ~hal9000/.local/share/HAL9000-installer/container-hal9000-kalliope-proxy.socket \
   ~hal9000/.config/systemd/user/container-hal9000-kalliope-proxy.socket

echo "Switching to socket-activation for console in systemd (user instance)..."
sed -i 's/container-hal9000-console.service//g' \
    ~hal9000/.config/systemd/user/pod-hal9000.service
sed -i 's/After=container/ExecStopPost=systemctl --user stop pod-hal9000.socket\nAfter=container/' \
    ~hal9000/.config/systemd/user/pod-hal9000.service

echo "Reloading systemd (user instance)..."
systemctl --user daemon-reload

echo "Enabling pod-hal9000.[socket|service] in systemd (user instance)..."
systemctl --user --quiet enable pod-hal9000.socket
systemctl --user --quiet enable pod-hal9000.service

echo "Starting pod-hal9000.[socket|service] in systemd (user instance)..."
systemctl --user --quiet start pod-hal9000.socket
systemctl --user --quiet start pod-hal9000.service

