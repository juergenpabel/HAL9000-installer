#!/bin/sh

IMAGE_SRC=${1:-ghcr.io/juergenpabel}
IMAGE_TAG=${2:-stable}

echo "HAL9000: Downloading images and deploying containers..."

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/download_images.sh   $IMAGE_SRC $IMAGE_TAG
$SCRIPT_DIR/create_containers.sh $IMAGE_SRC $IMAGE_TAG
$SCRIPT_DIR/deploy_containers.sh $IMAGE_SRC $IMAGE_TAG

