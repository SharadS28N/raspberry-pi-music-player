#!/usr/bin/env bash
# One-line installer script for pi-aamps (Pi Advanced Audio & Music Player System)
set -e

echo "========================================================="
echo "   pi-aamps — Automated Raspberry Pi Installer"
echo "========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or using sudo: sudo bash install.sh"
  exit 1
fi

echo "[+] Updating apt repositories..."
apt-get update -y

echo "[+] Installing system dependencies (MPV, FFmpeg, BlueZ, ALSA, Python3)..."
apt-get install -y python3 python3-pip mpv ffmpeg alsa-utils bluez pulseaudio shairport-sync gmediarender

INSTALL_DIR="/opt/pi-aamps"
echo "[+] Deploying pi-aamps files to ${INSTALL_DIR}..."
mkdir -p "$INSTALL_DIR"
cp -rf backend frontend run.py requirements.txt LICENSE README.md "$INSTALL_DIR/"

echo "[+] Installing Python packages..."
python3 -m pip install -r "$INSTALL_DIR/requirements.txt" --break-system-packages || python3 -m pip install -r "$INSTALL_DIR/requirements.txt"

echo "[+] Installing systemd service..."
cp pi-aamps.service /etc/systemd/system/pi-aamps.service
systemctl daemon-reload
systemctl enable pi-aamps.service
systemctl restart pi-aamps.service

IP=$(hostname -I | awk '{print $1}')
echo "========================================================="
echo "  🎉 pi-aamps installed successfully!"
echo "  Access Web OS interface at: http://${IP}:8000"
echo "========================================================="
