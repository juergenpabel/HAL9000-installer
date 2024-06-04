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

echo "HAL9000: Installing files for HAL9000-installer.service in systemd (user instance)..."
sudo -i -u hal9000 sh -c "mkdir -p ~hal9000/.config/systemd/user"
sudo -i -u hal9000 sh -c "mkdir -p ~hal9000/.local/share/HAL9000-installer"
find "$SCRIPT_DIR" -name "*.template" -printf '%f\n' | while read FILENAME; do
	sudo -i -u hal9000 sh -c "cat - > ~hal9000/.local/share/HAL9000-installer/$FILENAME" \
	                                < "$SCRIPT_DIR/$FILENAME"
done

sudo -i -u hal9000 sh -c "sed -e 's#IMAGE_SRC#${IMAGE_SRC}#g' -e 's#IMAGE_TAG#${IMAGE_TAG}#g' \
                          < ~hal9000/.local/share/HAL9000-installer/HAL9000-installer.service.template \
                          > ~hal9000/.local/share/HAL9000-installer/HAL9000-installer.service"
sudo -i -u hal9000 sh -c "ln -s ~hal9000/.local/share/HAL9000-installer/HAL9000-installer.service \
                                ~hal9000/.config/systemd/user/HAL9000-installer.service"
sudo -i -u hal9000 sh -c "cat - > ~hal9000/.local/share/HAL9000-installer/install_pod-hal9000.sh" \
     < "$SCRIPT_DIR"/install_pod-hal9000.sh.template
sudo -i -u hal9000 sh -c "chmod 755 ~hal9000/.local/share/HAL9000-installer/install_pod-hal9000.sh"

echo "HAL9000: Activating HAL9000-installer.service in systemd (user instance)..."
sudo -i -u hal9000 systemctl --user daemon-reload
sudo -i -u hal9000 systemctl --user --quiet enable HAL9000-installer.service

