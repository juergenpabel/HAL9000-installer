#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/prepare_buildenv.sh $@
$SCRIPT_DIR/compile_firmware.sh $@
$SCRIPT_DIR/flash_firmware.sh $@

