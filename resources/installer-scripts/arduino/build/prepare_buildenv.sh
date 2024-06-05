#!/bin/sh

HAL9000_INSTALL_VERSION="${1:-unknown}"

if [ "${HAL9000_INSTALL_VERSION}" = "unknown" ]; then
	echo "Usage: $0 <FIRMWARE-VERSION>"
	echo "       - FIRMWARE-VERSION: something like 'stable' or 'development'"
	exit 1
fi

echo "HAL9000: Preparing build environment for arduino firmware..."
GIT_DIR=`git rev-parse --show-toplevel`

cd "${GIT_DIR}"
git submodule update --init resources/repositories/HAL9000

cd "${GIT_DIR}/resources/repositories/HAL9000/"
git checkout --quiet master
git pull
git checkout --quiet "${HAL9000_INSTALL_VERSION}"

cd "${GIT_DIR}/resources/repositories/HAL9000/enclosure/firmware/arduino/"
if [ ! -d .venv ]; then
	python3 -m venv .venv
fi
. .venv/bin/activate
pip install platformio

if [ -f requirements.txt ]; then
	pip install -r requirements.txt
fi

