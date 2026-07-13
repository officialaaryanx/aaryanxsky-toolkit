#!/bin/bash
# Rebuilds aaryanxsky_1.0_all.deb from the current aaryanxsky-toolkit.sh
# Run this from the repo root after editing the tool.

set -e

PKG_DIR="aaryanxsky_1.0_all"
SCRIPT="aaryanxsky-toolkit.sh"

if [[ ! -f "$SCRIPT" ]]; then
    echo "Error: $SCRIPT not found in current directory."
    exit 1
fi

mkdir -p "$PKG_DIR/DEBIAN" "$PKG_DIR/usr/bin" "$PKG_DIR/usr/share/doc/aaryanxsky"

cat > "$PKG_DIR/DEBIAN/control" << 'EOF'
Package: aaryanxsky
Version: 1.0
Section: utils
Priority: optional
Architecture: all
Depends: whois, geoip-bin, dnsutils, libimage-exiftool-perl, nmap, python3, curl
Recommends: theharvester, dnsenum, aircrack-ng, zip
Maintainer: AaryanXSky <youremail@example.com>
Description: AaryanXSky OSINT & Recon Toolkit
 A menu-driven wrapper around native Kali Linux OSINT and recon tools —
 IP intelligence, domain recon, EXIF forensics, port scanning, Wi-Fi
 recon, and a built-in canary token listener, all from one command.
EOF

cat > "$PKG_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
chmod 755 /usr/bin/aaryanxsky
echo ""
echo "AaryanXSky Toolkit installed."
echo "Run it from anywhere with:  aaryanxsky"
echo ""
exit 0
EOF

chmod 755 "$PKG_DIR/DEBIAN/postinst"
cp "$SCRIPT" "$PKG_DIR/usr/bin/aaryanxsky"
chmod 755 "$PKG_DIR/usr/bin/aaryanxsky"
cp README.md "$PKG_DIR/usr/share/doc/aaryanxsky/README.md" 2>/dev/null || true

dpkg-deb --build --root-owner-group "$PKG_DIR"
echo "Built: ${PKG_DIR}.deb"
