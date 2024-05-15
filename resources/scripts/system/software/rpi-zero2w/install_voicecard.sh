#!/bin/bash

cd ~
echo "HAL9000: Downloading, building and installing soundcard driver (seeed-voicecard)..."
if [ ! -d seeed-voicecard ]; then
        git clone https://github.com/HinTak/seeed-voicecard
fi
cd seeed-voicecard
git checkout v`uname -r | cut -d. -f1-2`
sed -i 's/dkms build -k/dkms build -j 1 -k/g' install.sh
sudo ./install.sh 

