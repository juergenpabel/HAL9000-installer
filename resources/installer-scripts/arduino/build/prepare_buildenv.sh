#!/bin/sh

SCRIPT_SRC=`realpath -s $0`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`
GIT_DIR=`git rev-parse --show-toplevel`

echo "HAL9000: Preparing build environment for arduino firmware..."
cd "${GIT_DIR}"
git submodule update --init resources/repositories/HAL9000
python3 -m venv "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv"
. "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/.venv/bin/activate"
pip install platformio

