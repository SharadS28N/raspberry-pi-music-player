#!/usr/bin/env bash
# Script to package pi-aamps into a standard Debian (.deb) package
set -e

PACKAGE_NAME="pi-aamps"
VERSION="2.5.0"
BUILD_DIR="/tmp/${PACKAGE_NAME}_${VERSION}_all"

echo "========================================================="
echo " Building Debian Package: ${PACKAGE_NAME}_${VERSION}_all.deb"
echo "========================================================="

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/opt/pi-aamps"
mkdir -p "$BUILD_DIR/etc/systemd/system"
mkdir -p "$BUILD_DIR/usr/bin"

# Copy package control
cp debian/control "$BUILD_DIR/DEBIAN/control"

# Copy postinst script
cat << 'EOF' > "$BUILD_DIR/DEBIAN/postinst"
#!/bin/sh
set -e
echo "Setting up pi-aamps Python dependencies..."
pip3 install -r /opt/pi-aamps/requirements.txt --break-system-packages || true
systemctl daemon-reload
systemctl enable pi-aamps.service
systemctl restart pi-aamps.service || true
echo "pi-aamps service installed and started successfully!"
EOF
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# Copy source code
cp -r backend frontend run.py requirements.txt LICENSE README.md "$BUILD_DIR/opt/pi-aamps/"
cp pi-aamps.service "$BUILD_DIR/etc/systemd/system/"

# Create binary wrapper symlink
cat << 'EOF' > "$BUILD_DIR/usr/bin/pi-aamps"
#!/bin/sh
exec python3 /opt/pi-aamps/run.py "$@"
EOF
chmod +x "$BUILD_DIR/usr/bin/pi-aamps"

# Build .deb package
dpkg-deb --build "$BUILD_DIR" "${PACKAGE_NAME}_${VERSION}_all.deb"

echo "Success! Created package: ${PACKAGE_NAME}_${VERSION}_all.deb"
echo "To install on any Debian/Raspbian system run:"
echo "   sudo apt install ./${PACKAGE_NAME}_${VERSION}_all.deb"
