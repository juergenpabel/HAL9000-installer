#!/bin/sh

CONFIGURATION_GIT_URL=${1:-unknown}
CONFIGURATION_GIT_TAG=${2:-unknown}

if [ "${CONFIGURATION_GIT_URL}" = "unknown" ]; then
	echo "Usage: $0 <CONFIG-GIT-URL> <CONFIG-GIT-TAG>"
	echo "       - CONFIG-GIT-URL: most likely 'https://github.com/juergenpabel/HAL9000-demo-en_US.git' (or other language)"
	echo "       - CONFIG-GIT-TAG: a git tag(-prefix) for which commit to use, most likely 'stable' or 'development'"
        exit 1
fi
if [ "${CONFIGURATION_GIT_TAG}" = "unknown" ]; then
	echo "Usage: $0 $1 <CONFIG-GIT-TAG>"
	echo "       - CONFIG-GIT-TAG: a git tag(-prefix) for which commit to use, most likely 'stable' or 'development'"
        exit 1
fi
GIT_NAME=`echo ${CONFIGURATION_GIT_URL} | sed 's#/$##' | sed 's/.git$//' | rev | cut -d'/' -f1 | rev`

SCRIPT_SRC=`realpath "$0"`
SCRIPT_DIR=`dirname "${SCRIPT_SRC}"`

echo "HAL9000: Cloning git repository '${CONFIGURATION_GIT_URL}' to '~hal9000/HAL9000/${GIT_NAME}'..."
sudo -i -u hal9000 sh -c "test -e ~hal9000/HAL9000"
if [ $? -eq 0 ]; then
	echo "ERROR: ~hal9000/HAL9000 already exists, not executing configuration repository setup"
	exit 1
fi
sudo -i -u hal9000 sh -c "mkdir -p ~hal9000/HAL9000"
sudo -i -u hal9000 sh -c "git clone ${CONFIGURATION_GIT_URL} ~hal9000/HAL9000/${GIT_NAME}"

if [ $? -ne 0 ]; then
	echo "ERROR: 'git clone ${CONFIGURATION_GIT_URL} ~hal9000/HAL9000/${GIT_NAME}' failed,"
	echo "       check git url and/or network connectivity"
	exit 1
fi

for SERVICE in kalliope frontend dashboard brain; do
	echo "HAL9000: Copying git repository to '~hal9000/HAL9000/${SERVICE}' and preparing it..."
	sudo -i -u hal9000 sh -c "cp -r ~hal9000/HAL9000/${GIT_NAME} ~hal9000/HAL9000/${SERVICE}"
	SERVICE_GIT_TARGET="${CONFIGURATION_GIT_TAG}/${SERVICE}"
	sudo -i -u hal9000 sh -c "cd ~hal9000/HAL9000/${SERVICE} ; git tag -l ${SERVICE_GIT_TARGET} >/dev/null"
	if [ $? -ne 0 ]; then
		echo "WARNING: git tag '${SERVICE_GIT_TARGET}' not found, using branch '${SERVICE}' instead"
		SERVICE_GIT_TARGET="${SERVICE}"
	fi
	sudo -i -u hal9000 sh -c "cd ~hal9000/HAL9000/${SERVICE} ; git -c advice.detachedHead=false checkout ${SERVICE_GIT_TARGET}"
	sudo -i -u hal9000 sh -c "cd ~hal9000/HAL9000/${SERVICE} ; git submodule update --init --recursive"
done

echo "HAL9000: Adding 'resources' symlink to git repositories for 'dashboard' and 'frontend'..."
sudo -i -u hal9000 sh -c "ln -sf ../resources ~hal9000/HAL9000/frontend/resources"
sudo -i -u hal9000 sh -c "ln -sf ../resources ~hal9000/HAL9000/dashboard/resources"

