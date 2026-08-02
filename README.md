# 🎵 PiPlayer - Production Open-Source Music Player & Bluetooth Receiver

[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Alpine.js](https://img.shields.io/badge/Alpine.js-3.x-8BC0D0?style=flat-square&logo=alpine.js&logoColor=white)](https://alpinejs.dev)
[![MPV](https://img.shields.io/badge/Audio_Engine-MPV-BF4080?style=flat-square)](https://mpv.io)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

**PiPlayer** is a self-hosted, open-source music server and Bluetooth audio receiver designed for Raspberry Pi and Linux devices. It features a Spotify-inspired web interface, hardware & stream volume management, custom equalizer presets, sleep timers, playlist management, and zero-latency Bluetooth receiver mode.

---

## 🌟 Key Features

- **🎨 Spotify-Style Interface**: Real-time position tracking, smooth scrubbing timeline, album artwork, and animated sound spectrum visualizers.
- **🎛️ Dual Master & Stream Volume**: Separate control for physical hardware gain (`amixer sset Master`) and MPV software stream volume.
- **📻 0-Delay Bluetooth Speaker Mode**: Connect your Phone, Laptop, or Tablet over Bluetooth A2DP Sink to stream movies or music directly to your connected speakers with zero latency.
- **📑 Playlist Management System**: Full CRUD playlist support — create custom playlists, add/remove tracks from search or history, and play full playlists sequentially.
- **🎚️ 5-Band Sound Equalizer**: Built-in FFmpeg audio filters (*Normal, Bass Boost, Vocal/Night, Treble Boost, Party/Club*).
- **🌙 Sleep Timer**: Integrated timer (*15m, 30m, 45m, 60m, 90m*) with automatic volume fade and playback pause.
- **⚡ Race-Condition Guarded Search & Playback**: Fast YouTube audio extraction (`yt-dlp`) with atomic request locking to prevent track switching glitches.

---

## 🚀 Quick Start (Automated 1-Command Setup)

Run the single-line automated installer on your Raspberry Pi or Debian/Ubuntu Linux machine:

```bash
curl -sSL https://raw.githubusercontent.com/your-username/raspberry-pi-music-player/main/install.sh | bash
```

Or clone the repository and run:

```bash
git clone https://github.com/your-username/raspberry-pi-music-player.git
cd raspberry-pi-music-player
bash install.sh
```

The installer automatically installs system packages (`mpv`, `bluez`, `yt-dlp`), sets up the Python virtual environment, configures Bluetooth discoverability, and installs auto-restarting `systemd` background services.

---

## 🛠️ Manual Installation Guide

### 1. Install System Dependencies
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv mpv bluetooth bluez rfkill alsa-utils ffmpeg wget
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

### 2. Configure Virtual Environment & Dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Run Web Server
```bash
python run.py
```
Open **`http://<your-pi-ip>:8000`** in any web browser.

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Browser Client (Alpine.js UI)              │
│       Spotify Timeline / Playlists / Equalizer / BT     │
└────────────────────────────┬────────────────────────────┘
                             │ REST / WebSocket (/ws)
┌────────────────────────────▼────────────────────────────┐
│                  FastAPI Backend Server                 │
│      main.py / database.py / bluetooth_service.py       │
└──────────────┬────────────────────────────┬─────────────┘
               │ JSON IPC Pipe              │ Subprocess/ALSA
┌──────────────▼─────────────┐┌─────────────▼─────────────┐
│      MPV Audio Engine      ││     Hardware ALSA Gain    │
│  (alsa/plughw:CARD=Head..) ││   amixer sset Master %  │
└────────────────────────────┘└────────────────────────────┘
```

---

## ⚙️ Managing Background Services

PiPlayer runs as auto-starting systemd services:

```bash
# Check PiPlayer Status
sudo systemctl status piplayer.service

# Restart Services
sudo systemctl restart mpv.service piplayer.service

# View Realtime Server Logs
sudo journalctl -u piplayer.service -f
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
