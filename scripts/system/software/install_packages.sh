#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt install -y git python3 python3-venv python3-pip podman

echo "Completed: Press any key to continue"
read -n 1
