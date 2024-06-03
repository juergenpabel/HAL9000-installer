#!/bin/sh

SCRIPT_SRC=`realpath -s "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/create_user_hal9000.sh $@
$SCRIPT_DIR/create_udev_tty.sh $@
$SCRIPT_DIR/create_udev_alsa.sh $@
$SCRIPT_DIR/create_polkit_shutdown.sh $@
$SCRIPT_DIR/touch_asound_conf.sh $@

