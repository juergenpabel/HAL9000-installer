#!/bin/sh

IMAGE_TAG=${1:-stable}

echo "HAL9000: Downloading images and deploying containers..."

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/download_images.sh $IMAGE_TAG
$SCRIPT_DIR/install_systemd_user_service.sh ghcr.io/juergenpabel $IMAGE_TAG

