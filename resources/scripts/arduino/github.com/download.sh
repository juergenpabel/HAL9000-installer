#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

"${SCRIPT_DIR}/download_firmware.sh" $@
"${SCRIPT_DIR}/download_filesystem.sh" $@

