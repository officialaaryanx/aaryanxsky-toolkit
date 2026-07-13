#!/bin/bash
# Uninstalls AaryanXSky Toolkit and optionally its data.

TARGET_BIN="/usr/local/bin/aaryanxsky"
DATA_DIR="$HOME/.aaryanxsky-toolkit"

echo "Removing $TARGET_BIN ..."
sudo rm -f "$TARGET_BIN"

read -rp "Also delete stored logs/loot/canary data in $DATA_DIR? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$DATA_DIR"
    echo "Data removed."
fi

echo "Uninstall complete."
