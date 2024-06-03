#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

$SCRIPT_DIR/software/run.sh $@
$SCRIPT_DIR/configure/run.sh $@

