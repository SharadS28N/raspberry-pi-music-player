# 🎵 PiPlayer - Production Open-Source Music Player & BT Sound Receiver

[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Alpine.js](https://img.shields.io/badge/Alpine.js-3.x-8BC0D0?style=flat-square&logo=alpine.js&logoColor=white)](https://alpinejs.dev)
[![Lucide](https://img.shields.io/badge/Icons-Lucide-3B82F6?style=flat-square)](https://lucide.dev)
[![License](https://img.shields.io/badge/License-MIT-black.svg?style=flat-square)](LICENSE)

**PiPlayer** is a self-hosted music server, synchronized lyrics viewer, 10-band audio equalizer, and **dedicated zero-latency Bluetooth audio sound receiver (A2DP Sink)** built for Raspberry Pi and Linux systems. It features a high-contrast **Black & White Neubrutalism UI**, zero-emoji icon design, dual hardware/software volume controls, and mobile PWA standalone app support.

---

## 🌟 Core Features & Capabilities

- **⚡ Dedicated Wireless BT Sound Receiver (A2DP Sink)**:
  - **Zero-Latency Real-Time Audio**: Powered by PulseAudio 17 real-time scheduling (`nice-level = -11`, `latency_msec=20`, `adjust_time=0`) for instant 0-delay audio streaming from smartphones, laptops, or PCs.
  - **Audio Device Class (`0x20041C`)**: Configured BlueZ CoD so smartphones and PCs automatically recognize your Pi as an **Audio Loudspeaker**.
  - **Automated PIN-Free Pairing**: Uses `NoInputNoOutput` BlueZ pairing agent so devices pair seamlessly without PIN roadblocks.
  - **On-Demand Power Toggle**: Keep Bluetooth disabled by default for privacy and enable it with a single click from the Web UI.

- **🎛️ Dual Sound & Hardware Gain Controls**:
  - **Raspberry Pi Hardware Master Gain**: Direct control over physical ALSA audio output (`amixer sset PCM`).
  - **Music Player Software Gain**: Independent output control for software music streaming.

- **🎤 Synchronized On-Screen Lyrics**: Real-time LRC lyric synchronization fetched via LRCLIB API. Displays live timestamped lines with active line highlighting and smooth auto-scrolling.

- **🎛️ 10-Band Custom Audio Equalizer**: 10 precision frequency sliders (60Hz to 16kHz) with instant audio presets (*Flat, Bass Boost, Vocal, Rock, Pop, Jazz, EDM, Party*).

- **📱 Neubrutalism UI & Native Mobile PWA App**:
  - **Pure Black & White Aesthetic**: Stark high-contrast theme (`#000000` & `#FFFFFF`), 2px/3px solid borders, and 4px block shadows.
  - **Zero Emojis**: 100% SVG icon design using Lucide Icons.
  - **Mobile PWA Support**: Install PiPlayer as a standalone native app on iOS, Android, macOS, and Windows.

- **📑 Playlist & Favorites System**: Save custom playlists, manage tracks, favorite tracks with persistent SQLite storage, and enjoy one-click playback.

---

## 🚀 Quick Start (1-Command Automated Installer)

Run the automated installer on your Raspberry Pi or Debian/Ubuntu system:

```bash
curl -sSL https://raw.githubusercontent.com/SharadS28N/raspberry-pi-music-player/main/install.sh | bash
```

Or clone the repository and run the installer locally:

```bash
git clone https://github.com/SharadS28N/raspberry-pi-music-player.git
cd raspberry-pi-music-player
bash install.sh
```

---

## 🛠️ Manual Setup Guide

### 1. Install System Dependencies
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv mpv bluetooth bluez rfkill alsa-utils pulseaudio-module-bluetooth ffmpeg wget
sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp
```

### 2. Configure Virtual Environment
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Start Server
```bash
python run.py
```
Access the application at **`http://<your-pi-ip>:8000`** in any web browser.

---

## 🧪 Running Unit Tests

Run the test suite to verify backend endpoints, lyrics fetcher, and Bluetooth controls:

```bash
python -m unittest discover -s tests -p "test_*.py"
```

---

## 🤝 Contributing

We welcome community contributions! Please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide before submitting pull requests or reporting issues.

---

## 📄 License

This project is licensed under the **[MIT License](LICENSE)**.
