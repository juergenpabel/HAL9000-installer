#!/bin/sh

IMAGE_PREFIX="localhost/hal9000-"
IMAGE_TAG="latest"
if [ "x$1" != "x" ]; then
	IMAGE_TAG="$1"
fi

echo "HAL9000: Building images and deploying containers..."

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/prepare_buildenv.sh
$SCRIPT_DIR/build_images.sh      $IMAGE_PREFIX $IMAGE_TAG
$SCRIPT_DIR/create_containers.sh $IMAGE_PREFIX $IMAGE_TAG
$SCRIPT_DIR/deploy_containers.sh $IMAGE_PREFIX $IMAGE_TAG

