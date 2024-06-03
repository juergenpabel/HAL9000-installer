#!/bin/sh

IMAGE_SRC="localhost"
IMAGE_TAG=${1:-latest}

echo "HAL9000: Building images and deploying containers..."

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/build_images.sh
$SCRIPT_DIR/install_systemd_user_service.sh $IMAGE_SRC $IMAGE_TAG

