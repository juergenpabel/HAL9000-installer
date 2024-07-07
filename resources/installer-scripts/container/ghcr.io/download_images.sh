#!/bin/sh

IMAGE_TAG=${1:-unknown}

if [ "${IMAGE_TAG}" = "unknown" ]; then
        echo "Usage: $0 <IMAGE-TAG>"
        echo "       - IMAGE-TAG: the tag for which the images should be downloaded (something like 'stable' or 'development')"
        exit 1
fi

echo "Downloading container images..."
for NAME in mosquitto kalliope frontend console brain ; do
        echo "- ghcr.io/juergenpabel/hal9000-${NAME}:${IMAGE_TAG}..."
        sudo -i -u hal9000 podman pull ghcr.io/juergenpabel/hal9000-${NAME}:${IMAGE_TAG}
done

