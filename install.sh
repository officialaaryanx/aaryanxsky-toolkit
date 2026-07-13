#!/bin/bash
# ============================================================
#  AaryanXSky Toolkit — Installer
#  Usage (after cloning):   ./install.sh
#  Usage (one-liner):       curl -sSL <raw-url>/install.sh | bash
# ============================================================

set -e

REPO_URL="https://github.com/officialaaryanx/aaryanxsky-toolkit.git"
INSTALL_DIR="/tmp/aaryanxsky-toolkit-install"
TARGET_BIN="/usr/local/bin/aaryanxsky"
SCRIPT_NAME="aaryanxsky-toolkit.sh"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}== AaryanXSky Toolkit Installer ==${NC}"

# If running as a standalone curl|bash (no local repo present), clone it.
if [[ ! -f "./$SCRIPT_NAME" ]]; then
    echo "Cloning repository..."
    rm -rf "$INSTALL_DIR"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

if [[ ! -f "./$SCRIPT_NAME" ]]; then
    echo -e "${RED}Could not find $SCRIPT_NAME. Aborting.${NC}"
    exit 1
fi

echo "Installing to $TARGET_BIN ..."
sudo cp "./$SCRIPT_NAME" "$TARGET_BIN"
sudo chmod +x "$TARGET_BIN"

echo
echo -e "${GREEN}Installed successfully.${NC}"
echo "Run it from anywhere with:  aaryanxsky"
echo
read -rp "Check/install dependencies now? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    sudo apt update
    sudo apt install -y whois geoip-bin theharvester dnsenum \
        libimage-exiftool-perl nmap aircrack-ng python3 curl zip
    echo -e "${GREEN}Dependencies installed.${NC}"
fi

echo
echo "Launching toolkit..."
sleep 1
exec aaryanxsky
