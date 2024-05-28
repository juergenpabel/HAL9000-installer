#!/bin/sh

SCRIPT_SRC=`realpath -s "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/configure_turbo.sh 60
$SCRIPT_DIR/configure_gpu.sh 16
$SCRIPT_DIR/configure_swap.sh 1024
$SCRIPT_DIR/configure_modprobe.sh

