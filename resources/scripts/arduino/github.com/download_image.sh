#!/bin/sh

DOWNLOAD_SOURCE=${1:-unknown}
DOWNLOAD_TARGET=${2:-unknown}


if [ "$DOWNLOAD_SOURCE" = "unknown" ]; then
	echo "Usage: $0 <URL> <DIRECTORY>"
	exit 1
fi

if [ "$DOWNLOAD_TARGET" = "unknown" ]; then
	echo "Usage: $0 $DOWNLOAD_SOURCE <DIRECTORY>"
	exit 1
fi

if [ ! -d "$DOWNLOAD_TARGET" ]; then
	echo "ERROR: the second paramenter must be an existing directory"
	exit 1
fi

echo "HAL9000: Downloading image from '${DOWNLOAD_SOURCE}'..."
wget -q --backups 0 --directory-prefix "$DOWNLOAD_TARGET" -- "$DOWNLOAD_SOURCE"

