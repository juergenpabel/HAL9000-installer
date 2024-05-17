#!/bin/sh

TAG=${1:-latest}

echo "Downloading container images..."
for NAME in mosquitto kalliope frontend console brain ; do
        echo "- ghcr.io/juergenpabel/hal9000-$NAME:$TAG ..."
        sudo -u hal9000 -i podman pull ghcr.io/juergenpabel/hal9000-$NAME:$TAG
done

