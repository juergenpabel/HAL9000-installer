#!/bin/sh

USER_UID=`/usr/bin/id -u`
USER_NAME=`/usr/bin/id -un`
IMAGE_SRC="${1:-unknown}"
IMAGE_TAG="${2:-unknown}"

if [ "$IMAGE_SRC" = "unknown" ]; then
	echo "Usage: $0 <IMAGE-SRC> <IMAGE-TAG>"
	echo "       IMAGE-SRC: most likely 'localhost' or 'ghcr.io/juergenpabel'
	echo "       IMAGE-TAG: most likely 'development' or 'stable'
	exit 1
fi

if [ "$IMAGE_TAG" = "unknown" ]; then
	echo "Usage: $0 $IMAGE_SRC <IMAGE-TAG>"
	echo "       IMAGE-TAG: most likely 'development' or 'stable'
	exit 1
fi

if [ "x$USER_NAME" != "xhal9000" ]; then
	echo "ERROR: this script should be run as the application user 'hal9000' (current user='$USER_NAME')"
	exit 1
fi

if [ "x$XDG_RUNTIME_DIR" = "x" ]; then
	echo "ERROR: for connecting with the user-instance of systemd, the environment variable XDG_RUNTIME_DIR must be set (export XDG_RUNTIME_DIR=/run/user/$USER_UID/)"
	exit 1
fi


podman pod exists hal9000
if [ $? -eq 0 ]; then
	echo "ERROR: pod 'hal9000' exists, aborting script (remove pod and start script again => podman pod rm hal9000)"
	exit 1
fi

MISSING_IMAGES=""
for IMAGE_NAME in mosquitto console frontend kalliope brain ; do
	podman image exists "${IMAGE_SRC}/hal9000-${IMAGE_NAME}:${IMAGE_TAG}"
	if [ $? -ne 0 ]; then
		MISSING_IMAGES="'$IMAGE_SRC/hal9000-$IMAGE_NAME:$IMAGE_TAG' $MISSING_IMAGES"
	fi
done
if [ "x$MISSING_IMAGES" != "x" ]; then
	echo "        ERROR:  missing images => $MISSING_IMAGES"
	echo "                aborting script"
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

echo -n "Creating pod 'hal9000':                 "
podman pod create --name hal9000 \
                  -p 127.0.0.1:8080:8080 \
                  -p 127.0.0.1:9000:9000 \
                  --network hal9000 \
                  --infra-name hal9000-infra \
                  --hostname hal9000

echo -n "Creating container 'hal9000-mosquitto': "
podman create --pod=hal9000 --name=hal9000-mosquitto \
              --group-add=keep-groups \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-mosquitto:$IMAGE_TAG

echo -n "Creating container 'hal9000-kalliope':  "
podman create --pod=hal9000 --name=hal9000-kalliope \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              --device /dev/snd:/dev/snd \
              -v /etc/asound.conf:/etc/asound.conf:ro \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-kalliope:$IMAGE_TAG

echo -n "Creating container 'hal9000-frontend':  "
podman create --pod=hal9000 --name=hal9000-frontend \
              --requires hal9000-mosquitto \
              --group-add=keep-groups \
              $DEVICE_TTYHAL9000_ARGS \
              --tz=local \
              --pull=never \
              $IMAGE_SRC/hal9000-frontend:$IMAGE_TAG

echo -n "Creating container 'hal9000-brain':     "
podman create --pod=hal9000 --name=hal9000-brain \
              --requires hal9000-kalliope,hal9000-frontend \
              --group-add=keep-groups \
              --tz=local \
              $SYSTEMD_TIMESYNC_ARGS \
              --pull=never \
              $IMAGE_SRC/hal9000-brain:$IMAGE_TAG

echo -n "Creating container 'hal9000-console':   "
podman create --pod=hal9000 --name=hal9000-console \
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

