#!/bin/sh

HAL9000_LANGUAGES=${1:-en,de}

GIT_DIR=`git rev-parse --show-toplevel`

echo "Extracting strings from python application..."
xgettext -o "${GIT_DIR}/HAL9000-installer/locales/HAL9000-installer.pot"  "${GIT_DIR}/HAL9000-installer/HAL9000.py"

echo "$HAL9000_LANGUAGES" | sed 's/ //g' | sed 's/,/\n/g' | while read HAL9000_LANGUAGE; do
	echo "Updating and compiling PO files for language '$HAL9000_LANGUAGE'..."
	msgmerge --update --backup=none \
	         "${GIT_DIR}/HAL9000-installer/locales/${HAL9000_LANGUAGE}/LC_MESSAGES/HAL9000-installer.po" \
	         "${GIT_DIR}/HAL9000-installer/locales/HAL9000-installer.pot"
	msgfmt -o "${GIT_DIR}/HAL9000-installer/locales/${HAL9000_LANGUAGE}/LC_MESSAGES/HAL9000-installer.mo" \
	          "${GIT_DIR}/HAL9000-installer/locales/${HAL9000_LANGUAGE}/LC_MESSAGES/HAL9000-installer.po"
done

