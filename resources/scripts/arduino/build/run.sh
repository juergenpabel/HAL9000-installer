#!/bin/sh

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/prepare_buildenv.sh $@
$SCRIPT_DIR/compile_firmware.sh $@
$SCRIPT_DIR/flash_firmware.sh $@

