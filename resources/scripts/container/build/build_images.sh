#!/bin/sh

# TODO: $2 instead env var?
CONFIG_DIRECTORY=${CONFIG_DIRECTORY:-demo-en_US}

echo "Building images with language-related configurations from '$CONFIG_DIRECTORY'"
echo " "

GIT_REPODIR=$(realpath "$1")
cd "$GIT_REPODIR"
GIT_REPODIR=`git rev-parse --show-toplevel`
cd - >/dev/null
echo "Using '$GIT_REPODIR' as the base directory for the 'HAL9000' respository."
cd "$GIT_REPODIR"
git submodule update --init

echo "Building image 'hal9000-mosquitto'..."
podman image exists localhost/hal9000-mosquitto:latest >/dev/null
if [ $? -eq 0 ]; then
	podman image rm     localhost/hal9000-mosquitto:latest >/dev/null
fi
podman pull docker.io/library/eclipse-mosquitto:latest
podman tag  docker.io/library/eclipse-mosquitto:latest localhost/hal9000-mosquitto:latest

echo "Building image 'hal9000-kalliope'..."
cd "$GIT_REPODIR/kalliope"
git submodule update --recursive "$CONFIG_DIRECTORY"
podman image exists localhost/hal9000-kalliope:latest
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-kalliope:latest
fi
podman build --build-arg KALLIOPE_CONFIG_DIRECTORY="$CONFIG_DIRECTORY" --tag localhost/hal9000-kalliope:latest -f Containerfile .

echo "Building image 'hal9000-frontend'..."
cd "$GIT_REPODIR/enclosure/services/frontend/"
git submodule update --recursive "$CONFIG_DIRECTORY"
if [ ! -e "$CONFIG_DIRECTORY/assets" ]; then
	ln -s ../assets $CONFIG_DIRECTORY/assets
fi
podman image exists localhost/hal9000-frontend:latest
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-frontend:latest
fi
podman build --build-arg FRONTEND_CONFIG_DIRECTORY="$CONFIG_DIRECTORY" --tag localhost/hal9000-frontend:latest -f Containerfile .

echo "Building image 'hal9000-brain'..."
cd "$GIT_REPODIR/enclosure/services/brain/"
git submodule update --recursive "$CONFIG_DIRECTORY"
podman image exists localhost/hal9000-brain:latest
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-brain:latest
fi
podman build --build-arg BRAIN_CONFIG_DIRECTORY="$CONFIG_DIRECTORY" --tag localhost/hal9000-brain:latest -f Containerfile .

echo "Building image 'hal9000-console'..."
cd "$GIT_REPODIR/enclosure/services/console/"
git submodule update --recursive "$CONFIG_DIRECTORY"
if [ ! -e "$CONFIG_DIRECTORY/assets" ]; then
	ln -s ../assets $CONFIG_DIRECTORY/assets
fi
podman image exists localhost/hal9000-console:latest
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-console:latest
fi
podman build --build-arg CONSOLE_CONFIG_DIRECTORY="$CONFIG_DIRECTORY" --tag localhost/hal9000-console:latest -f Containerfile .

