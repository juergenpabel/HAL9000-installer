#!/bin/sh

IMAGE_SRC="localhost"
IMAGE_TAG=${1:-latest}

echo "HAL9000: Building images and deploying containers..."

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/prepare_buildenv.sh
$SCRIPT_DIR/build_images.sh      $IMAGE_SRC $IMAGE_TAG
$SCRIPT_DIR/create_containers.sh $IMAGE_SRC $IMAGE_TAG
$SCRIPT_DIR/deploy_containers.sh $IMAGE_SRC $IMAGE_TAG

