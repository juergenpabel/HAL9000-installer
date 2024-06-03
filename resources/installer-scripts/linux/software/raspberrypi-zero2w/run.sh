#!/bin/sh

SCRIPT_SRC=`realpath -s "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/install_fake_nproc.sh 1
$SCRIPT_DIR/install_voicecard.sh

