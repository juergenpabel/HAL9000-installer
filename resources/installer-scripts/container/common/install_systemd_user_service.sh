#!/bin/sh

IMAGE_SRC=${1:-unknown}
IMAGE_TAG=${2:-unknown}

if [ "$IMAGE_SRC" = "unknown" ] || [ "$IMAGE_TAG" = "unknown" ]; then
	echo "Usage: $0 <IMAGE-SRC> <IMAGE-TAG>"
	echo "       IMAGE-SRC: most likely 'ghcr.io/juergenpabel' or 'localhost'"
	echo "       IMAGE-TAG: most likely 'stable', 'development' or 'latest'"
        exit 1
fi

SCRIPT_SRC=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_SRC"`

sudo -i -u hal9000 sh -c "mkdir -p ~hal9000/.config/systemd/user"
sudo -i -u hal9000 sh -c "sed -e 's#IMAGE_SRC#$IMAGE_SRC#g' -e 's#IMAGE_TAG#$IMAGE_TAG#g' > ~hal9000/.config/systemd/user/HAL9000-installer.service" \
                   < "$SCRIPT_DIR"/HAL9000-installer.service.template

sudo -i -u hal9000 sh -c "mkdir -p ~hal9000/.local/share/HAL9000-installer"
sudo -i -u hal9000 sh -c "cat - > ~hal9000/.local/share/HAL9000-installer/install_pod-hal9000.sh" \
                   < "$SCRIPT_DIR"/install_pod-hal9000.sh.template
sudo -i -u hal9000 sh -c "chmod 755 ~hal9000/.local/share/HAL9000-installer/install_pod-hal9000.sh"

sudo -i -u hal9000 systemctl --user daemon-reload
sudo -i -u hal9000 systemctl --user enable HAL9000-installer.service

