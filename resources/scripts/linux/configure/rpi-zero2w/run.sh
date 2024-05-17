#!/bin/sh

SCRIPT_DIR=`dirname $0`
$SCRIPT_DIR/configure_maxcpus.sh 2
$SCRIPT_DIR/configure_gpu.sh 16
$SCRIPT_DIR/configure_swap.sh 1024
$SCRIPT_DIR/configure_modprobe.sh
