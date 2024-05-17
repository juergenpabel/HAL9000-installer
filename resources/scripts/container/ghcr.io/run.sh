#!/bin/sh

IMAGE_PREFIX="ghcr.io/juergenpabel/hal9000-"
IMAGE_TAG="stable"
if [ "x$1" != "x" ]; then
	IMAGE_TAG="$1"
fi

echo "HAL9000: Downloading images and deploying containers..."

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/download_images.sh   $IMAGE_PREFIX $IMAGE_TAG
$SCRIPT_DIR/create_containers.sh $IMAGE_PREFIX $IMAGE_TAG
$SCRIPT_DIR/deploy_containers.sh $IMAGE_PREFIX $IMAGE_TAG

