#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

echo "HAL9000: Preparing build environment for arduino firmware..."
cd "${GIT_DIR}"
git submodule update --init resources/repositories/HAL9000
cd "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino"
python3 -m venv .venv
. .venv/bin/activate
pip install platformio

