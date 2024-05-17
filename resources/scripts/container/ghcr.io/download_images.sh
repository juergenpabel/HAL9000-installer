#!/bin/sh

TAG="latest"
if [ "x$1" != "x" ]; then
	TAG="$1"
fi

echo "Downloading container images..."
for NAME in mosquitto kalliope frontend console brain ; do
        echo "- ghcr.io/juergenpabel/hal9000-$NAME:$TAG ..."
        sudo -u hal9000 -i podman pull ghcr.io/juergenpabel/hal9000-$NAME:$TAG
done

