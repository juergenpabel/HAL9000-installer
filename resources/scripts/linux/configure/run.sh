#!/bin/sh

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/create_user_hal9000.sh $@
$SCRIPT_DIR/create_udev_tty.sh $@
$SCRIPT_DIR/create_udev_alsa.sh $@
$SCRIPT_DIR/create_polkit_shutdown.sh $@

