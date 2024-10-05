#!/bin/sh

HAL9000_INSTALL_VERSION=${1:-unknown}
HAL9000_CONFIG_DIR=${HAL9000_CONFIG_DIR:-demo-en_US} # TODO

if [ "${HAL9000_INSTALL_VERSION}" = "unknown" ]; then
	echo "Usage: $0 <SOFTWARE-VERSION>"
	echo "       - SOFTWARE-VERSION: most likely something like 'stable' or 'development'"
	exit 1
fi

echo "HAL9000: Building images with language-related configurations from '${HAL9000_CONFIG_DIR}'"
SCRIPT_SRC=`realpath -s "$0"`
SCRIPT_DIR=`dirname "${SCRIPT_SRC}"`
cd "${SCRIPT_DIR}"
GIT_REPODIR=`git rev-parse --show-toplevel`

cd "${GIT_REPODIR}"
git submodule update --init resources/repositories/HAL9000
GIT_REPODIR="${GIT_REPODIR}/resources/repositories/HAL9000"
echo "Using '${GIT_REPODIR}' as the base directory for the 'HAL9000' respository."
cd "${GIT_REPODIR}"
git checkout --quiet master
git pull
git checkout --quiet "${HAL9000_INSTALL_VERSION}"

echo "Building image 'hal9000-mosquitto'..."
podman image exists localhost/hal9000-mosquitto:${HAL9000_INSTALL_VERSION} >/dev/null
if [ $? -eq 0 ]; then
	podman image rm     localhost/hal9000-mosquitto:${HAL9000_INSTALL_VERSION} >/dev/null
fi
podman pull docker.io/library/eclipse-mosquitto:latest
podman tag  docker.io/library/eclipse-mosquitto:latest localhost/hal9000-mosquitto:${HAL9000_INSTALL_VERSION}

echo "Building image 'hal9000-kalliope'..."
cd "${GIT_REPODIR}/kalliope"
git submodule update --init --recursive "${HAL9000_CONFIG_DIR}"
podman image exists localhost/hal9000-kalliope:${HAL9000_INSTALL_VERSION}
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-kalliope:${HAL9000_INSTALL_VERSION}
fi
podman build --build-arg KALLIOPE_CONFIG_DIRECTORY="${HAL9000_CONFIG_DIR}" --tag localhost/hal9000-kalliope:${HAL9000_INSTALL_VERSION} -f Containerfile .

echo "Building image 'hal9000-frontend'..."
cd "${GIT_REPODIR}/enclosure/services/frontend/"
git submodule update --init --recursive "${HAL9000_CONFIG_DIR}"
if [ ! -e "${HAL9000_CONFIG_DIR}/resources" ]; then
	ln -s ../resources "${HAL9000_CONFIG_DIR}/resources"
fi
podman image exists localhost/hal9000-frontend:${HAL9000_INSTALL_VERSION}
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-frontend:${HAL9000_INSTALL_VERSION}
fi
podman build --build-arg FRONTEND_CONFIG_DIRECTORY="${HAL9000_CONFIG_DIR}" --tag localhost/hal9000-frontend:${HAL9000_INSTALL_VERSION} -f Containerfile .

echo "Building image 'hal9000-console'..."
cd "${GIT_REPODIR}/enclosure/services/console/"
git submodule update --init --recursive "${HAL9000_CONFIG_DIR}"
if [ ! -e "${HAL9000_CONFIG_DIR}/resources" ]; then
	ln -s ../resources "${HAL9000_CONFIG_DIR}/resources"
fi
podman image exists localhost/hal9000-console:${HAL9000_INSTALL_VERSION}
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-console:${HAL9000_INSTALL_VERSION}
fi
podman build --build-arg CONSOLE_CONFIG_DIRECTORY="${HAL9000_CONFIG_DIR}" --tag localhost/hal9000-console:${HAL9000_INSTALL_VERSION} -f Containerfile .

echo "Building image 'hal9000-brain'..."
cd "${GIT_REPODIR}/enclosure/services/brain/"
git submodule update --init --recursive "${HAL9000_CONFIG_DIR}"
podman image exists localhost/hal9000-brain:${HAL9000_INSTALL_VERSION}
if [ $? -eq 0 ]; then
	podman image rm localhost/hal9000-brain:${HAL9000_INSTALL_VERSION}
fi
podman build --build-arg BRAIN_CONFIG_DIRECTORY="${HAL9000_CONFIG_DIR}" --tag localhost/hal9000-brain:${HAL9000_INSTALL_VERSION} -f Containerfile .

