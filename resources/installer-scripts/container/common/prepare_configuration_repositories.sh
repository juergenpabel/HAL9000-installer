#!/bin/sh

CONFIGURATION_GIT_URL=${1:-unknown}

if [ "${CONFIGURATION_GIT_URL}" = "unknown" ]; then
	echo "Usage: $0 <CONFIG-GIT-URL>"
	echo "       - CONFIG-GIT-URL: most likely 'https://github.com/juergenpabel/HAL9000-demo-en_US.git' (or other language)"
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

for SERVICE in kalliope frontend console brain; do
	echo "HAL9000: Copying git repository to '~hal9000/HAL9000/${SERVICE}' and preparing it..."
	sudo -i -u hal9000 sh -c "cp -r ~hal9000/HAL9000/${GIT_NAME} ~hal9000/HAL9000/${SERVICE}"
	sudo -i -u hal9000 sh -c "cd ~hal9000/HAL9000/${SERVICE} ; git checkout ${SERVICE}"
	sudo -i -u hal9000 sh -c "cd ~hal9000/HAL9000/${SERVICE} ; git submodule update --init --recursive"
done

echo "HAL9000: Adding 'assets' symlink to git repositories for 'console' and 'frontend'..."
sudo -i -u hal9000 sh -c "ln -sf ../assets ~hal9000/HAL9000/frontend/assets"
sudo -i -u hal9000 sh -c "ln -sf ../assets ~hal9000/HAL9000/console/assets"

