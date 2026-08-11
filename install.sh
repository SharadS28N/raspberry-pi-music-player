#!/usr/bin/env bash
# ==============================================================================
# PiPlayer Production Automated One-Command Installer
# Supported OS: Raspberry Pi OS (Debian 11/12), Ubuntu, Debian Linux
# Usage: bash install.sh  OR  curl -sSL https://raw.githubusercontent.com/.../install.sh | bash
# ==============================================================================

set -e

GREEN='\031[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${CYAN}   PiPlayer Production Open-Source Automated Setup          ${NC}"
echo -e "${BLUE}============================================================${NC}"

# Detect installation user & paths
INSTALL_USER="${SUDO_USER:-$USER}"
if [ "$INSTALL_USER" = "root" ]; then
    INSTALL_USER="aamps"
fi

INSTALL_DIR="/home/${INSTALL_USER}/piplayer"
if [ -d "$(pwd)/backend" ]; then
    INSTALL_DIR="$(pwd)"
fi

echo -e "${GREEN}[1/6] Updating system package index and installing dependencies...${NC}"
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip python3-venv mpv bluetooth bluez rfkill alsa-utils bluez-tools pulseaudio-module-bluetooth ffmpeg wget unzip

echo -e "${GREEN}[2/6] Installing latest standalone yt-dlp binary...${NC}"
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

echo -e "${GREEN}[3/6] Setting up Python virtual environment...${NC}"
cd "${INSTALL_DIR}"
python3 -m venv venv
"${INSTALL_DIR}/venv/bin/pip" install --upgrade pip
"${INSTALL_DIR}/venv/bin/pip" install -r requirements.txt

echo -e "${GREEN}[4/6] Optimizing hardware audio & Bluetooth receiver settings...${NC}"
amixer sset PCM on 2>/dev/null || amixer sset Master on 2>/dev/null || true
amixer sset PCM 85% 2>/dev/null || amixer sset Master 85% 2>/dev/null || true

# Configure BlueZ for A2DP Speaker Sink & PIN-less JustWorks pairing
if [ -f /etc/bluetooth/main.conf ]; then
    sudo sed -i 's/#\?Class = .*/Class = 0x20041C/' /etc/bluetooth/main.conf
    sudo sed -i 's/#\?DiscoverableTimeout = .*/DiscoverableTimeout = 0/' /etc/bluetooth/main.conf
    sudo sed -i 's/#\?PairableTimeout = .*/PairableTimeout = 0/' /etc/bluetooth/main.conf
    sudo sed -i 's/#\?AutoEnable = .*/AutoEnable = true/' /etc/bluetooth/main.conf
fi

sudo systemctl restart bluetooth 2>/dev/null || true
sudo rfkill unblock bluetooth 2>/dev/null || true
sudo hciconfig hci0 class 0x20041C 2>/dev/null || true
sudo hciconfig hci0 piscan 2>/dev/null || true
sudo bluetoothctl power on 2>/dev/null || true
sudo bluetoothctl discoverable on 2>/dev/null || true
sudo bluetoothctl pairable on 2>/dev/null || true


echo -e "${GREEN}[5/6] Creating systemd service daemons...${NC}"

# Create MPV Background Service
sudo bash -c "cat > /etc/systemd/system/mpv.service << 'EOF'
[Unit]
Description=MPV Audio Engine for PiPlayer
After=sound.target network.target bluetooth.target pulseaudio.service

[Service]
Type=simple
User=${INSTALL_USER}
ExecStart=/usr/bin/mpv --idle=yes --ytdl=yes --ytdl-format=bestaudio/best --audio-device=pulse --cache=yes --demuxer-max-bytes=8M --demuxer-readahead-secs=8 --network-timeout=5 --input-ipc-server=/tmp/mpv.sock --no-video
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF"


# Create PiPlayer Web Server Service
sudo bash -c "cat > /etc/systemd/system/piplayer.service << 'EOF'
[Unit]
Description=PiPlayer Production Web Server
After=network-online.target sound.target bluetooth.target mpv.service
Wants=network-online.target mpv.service

[Service]
Type=simple
User=${INSTALL_USER}
WorkingDirectory=${INSTALL_DIR}/backend
ExecStart=${INSTALL_DIR}/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF"

echo -e "${GREEN}[6/6] Reloading and starting systemd services...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable mpv.service
sudo systemctl enable piplayer.service
sudo systemctl restart mpv.service
sudo systemctl restart piplayer.service

IP_ADDR=$(hostname -I | awk '{print $1}')

echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}  SUCCESS: PiPlayer setup complete!                        ${NC}"
echo -e "${CYAN}  Access Web Player UI: http://${IP_ADDR}:8000             ${NC}"
echo -e "${BLUE}============================================================${NC}"
