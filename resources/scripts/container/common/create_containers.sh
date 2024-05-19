#!/bin/sh

IMAGE_SRC="${1:-unknown}"
IMAGE_TAG="${2:-unknown}"

if [ "$IMAGE_SRC" = "unknown" ]; then
	echo "Usage: $0 <IMAGE-SRC> <IMAGE-TAG>"
	echo "       IMAGE-SRC: most likely 'localhost' or 'ghcr.io/juergenpabel'"
	echo "       IMAGE-TAG: most likely 'development' or 'stable'"
	exit 1
fi

if [ "$IMAGE_TAG" = "unknown" ]; then
	echo "Usage: $0 $IMAGE_SRC <IMAGE-TAG>"
	echo "       IMAGE-TAG: most likely 'development' or 'stable'"
	exit 1
fi

sudo -i -u hal9000 podman pod exists hal9000
if [ $? -eq 0 ]; then
	sudo -i -u hal9000 podman pod stop -t 1 hal9000
	sudo -i -u hal9000 podman pod rm hal9000
fi

MISSING_IMAGES=""
for IMAGE_NAME in mosquitto console frontend kalliope brain ; do
	sudo -i -u hal9000 podman image exists "${IMAGE_SRC}/hal9000-${IMAGE_NAME}:${IMAGE_TAG}"
	if [ $? -ne 0 ]; then
		MISSING_IMAGES="'$IMAGE_SRC/hal9000-$IMAGE_NAME:$IMAGE_TAG' $MISSING_IMAGES"
	fi
done
if [ "x$MISSING_IMAGES" != "x" ]; then
	echo "ERROR:  missing container images: $MISSING_IMAGES"
	echo "        aborting script"
	exit 1
fi


DEVICE_TTYHAL9000_ARGS="--device /dev/ttyHAL9000:/dev/ttyHAL9000"
if [ ! -e /dev/ttyHAL9000 ]; then
	DEVICE_TTYHAL9000_ARGS=""
fi
SYSTEMD_TIMESYNC_ARGS="-v /run/systemd/timesync:/run/systemd/timesync:ro"
if [ ! -e /run/systemd/timesync ]; then
	SYSTEMD_TIMESYNC_ARGS=""
fi

sudo -i -u hal9000 podman network exists hal9000
if [ $? -ne 0 ]; then
	echo -n "Creating network 'hal9000':                 "
	sudo -i -u hal9000 podman network create hal9000
fi

echo -n "Creating pod 'hal9000':                 "
sudo -i -u hal9000 podman pod create --name hal9000 \
                  -p 127.0.0.1:8080:8080 \
                  -p 127.0.0.1:9000:9000 \
                  --network hal9000 \
                  --infra-name hal9000-infra \
                  --hostname hal9000

echo -n "Creating container 'hal9000-mosquitto': "
sudo -i -u hal9000 podman create --pod=hal9000 --name=hal9000-mosquitto \
              --group-add=keep-groups \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-mosquitto:$IMAGE_TAG

echo -n "Creating container 'hal9000-kalliope':  "
sudo -i -u hal9000 podman create --pod=hal9000 --name=hal9000-kalliope \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              --device /dev/snd:/dev/snd \
              -v /etc/asound.conf:/etc/asound.conf:ro \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-kalliope:$IMAGE_TAG

echo -n "Creating container 'hal9000-frontend':  "
sudo -i -u hal9000 podman create --pod=hal9000 --name=hal9000-frontend \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              $DEVICE_TTYHAL9000_ARGS \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-frontend:$IMAGE_TAG

echo -n "Creating container 'hal9000-brain':     "
sudo -i -u hal9000 podman create --pod=hal9000 --name=hal9000-brain \
              --requires hal9000-kalliope,hal9000-frontend \
              --group-add=keep-groups \
              --tz=local \
              $SYSTEMD_TIMESYNC_ARGS \
              --pull=never \
              $IMAGE_SRC/hal9000-brain:$IMAGE_TAG

echo -n "Creating container 'hal9000-console':   "
sudo -i -u hal9000 podman create --pod=hal9000 --name=hal9000-console \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-console:$IMAGE_TAG

if [ "x$DEVICE_TTYHAL9000_ARGS" = "x" ]; then
	echo "NOTICE: no mircocontroller (/dev/ttyHAL9000) detected, not"
	echo "        mounting the device into container 'hal9000-frontend'"
	echo "        use the web-frontend (http://127.0.0.1:9000) as the"
	echo "        user-interface (an open session is required for"
	echo "        HAL9000 startup to complete)"
fi

