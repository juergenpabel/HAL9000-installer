#!/bin/sh

SCRIPT_SRC=`realpath -s "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/configure_swap.sh 0

