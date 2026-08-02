# PiPlayer - Raspberry Pi Setup and Hardware Configuration

## Document Information

Project:

```
PiPlayer
```

Document:

```
02-raspberry-pi.md
```

Purpose:

Define the Raspberry Pi hardware requirements, operating system setup, software installation, audio configuration, networking, storage layout, and system preparation required to run PiPlayer.

---

# 1. Raspberry Pi Overview

PiPlayer is designed primarily for:

```
Raspberry Pi 3 Model B+
```

The system is optimized for low-power hardware and does not require a powerful computer.

The Raspberry Pi performs:

- Backend hosting
- Music searching
- Queue management
- Audio playback
- Local database storage


---

# 2. Supported Hardware

## Primary Device

```
Raspberry Pi 3B+
```

Specifications:

```
CPU:
Quad Core ARM Cortex-A53

Architecture:
ARMv8 64-bit

RAM:
1GB

Storage:
10GB available

Network:
WiFi / Ethernet
```

---

# 3. Recommended Additional Hardware


## Storage

Recommended:

Minimum:

```
16GB microSD card
```

Better:

```
32GB microSD card
```


Reason:

The operating system, cache, logs, and future music storage require space.

---

## Audio Output


Supported:

### HDMI

Advantages:

- Digital audio
- Good quality
- No extra hardware


---

### 3.5mm Jack

Available on some Pi models.

Advantages:

- Simple
- No setup


---

### USB DAC

Recommended for high-quality audio.

Example:

```
USB Audio Device
```

Advantages:

- Better sound quality
- Less electrical noise


---

### Bluetooth Speaker


Supported through Linux Bluetooth stack.

---

# 4. Operating System


Recommended:

```
Raspberry Pi OS Lite 64-bit
```


Reason:

No desktop environment required.

Advantages:

- Lower RAM usage
- Faster boot
- More storage available


---

# 5. Initial Raspberry Pi Setup


After installing Raspberry Pi OS:


Login:

```
ssh username@raspberrypi-ip
```


Example:

```
ssh aamps@192.168.18.159
```


Update system:


```bash
sudo apt update
sudo apt upgrade -y
```


---

# 6. Required System Packages


Install:


```bash
sudo apt install -y \
python3 \
python3-pip \
python3-venv \
git \
mpv \
ffmpeg \
socat \
sqlite3
```


Purpose:


## Python

Runs backend.


## mpv

Audio playback engine.


## ffmpeg

Audio processing support.


## git

Source code management.


## socat

Useful for testing IPC communication.


## sqlite3

Database management.


---

# 7. Python Environment


Create project directory:


```bash
mkdir ~/piplayer
cd ~/piplayer
```


Create virtual environment:


```bash
python3 -m venv venv
```


Activate:


```bash
source venv/bin/activate
```


Install backend dependencies:


```bash
pip install fastapi uvicorn yt-dlp websockets
```


---

# 8. Project Location


Recommended:


```
/home/aamps/piplayer/
```


Final structure:


```
/home/aamps/piplayer/

├── backend/

├── frontend/

├── database/

├── logs/

└── venv/
```


---

# 9. User Permissions


PiPlayer should run as a normal Linux user.

Recommended:

```
aamps
```


Avoid running:

```
root
```


Reasons:

- Better security
- Easier maintenance
- Safer file handling


---

# 10. Audio Configuration


## Check Audio Devices


Run:


```bash
aplay -l
```


Example:


```
card 0:
 HDMI Audio

card 1:
 USB Audio Device
```


---

# 11. Selecting Default Audio Output


Edit:


```bash
sudo nano /etc/asound.conf
```


Example:


```
defaults.pcm.card 1
defaults.ctl.card 1
```


Restart:


```bash
sudo reboot
```


---

# 12. Testing mpv


Before running PiPlayer:


Test local audio:


```bash
mpv song.mp3
```


Expected:


Audio should play through the selected device.

---

# 13. mpv Configuration


Create:


```
~/.config/mpv/
```


Create:


```
mpv.conf
```


Example:


```
audio-client-name=PiPlayer

volume=80

save-position-on-quit=yes
```


---

# 14. Starting mpv for PiPlayer


PiPlayer controls mpv through IPC.


Start:


```bash
mpv \
--idle=yes \
--no-video \
--input-ipc-server=/tmp/mpv.sock
```


Explanation:


```
--idle=yes

Keep mpv alive without a song
```


```
--no-video

Audio only
```


```
--input-ipc-server

Allows backend control
```


---

# 15. Network Configuration


PiPlayer is designed for LAN usage.


Example:


```
Router

 |

 |

Raspberry Pi
192.168.18.159

 |

 |

Phone / Laptop Browser
```


---

# 16. Static IP Recommendation


The Pi should have a stable address.


Options:


## Router DHCP Reservation

Recommended.


Example:


```
MAC Address:

AA:BB:CC:DD:EE


Assigned:

192.168.18.159
```


---

## Static IP


Alternative:

Configure:

```
/etc/dhcpcd.conf
```


Example:


```
interface wlan0

static ip_address=192.168.18.159/24

static routers=192.168.18.1

static domain_name_servers=192.168.18.1
```


---

# 17. Firewall


Initial setup:

LAN only.


Allow:

```
FastAPI port

8000
```


Example:


```bash
sudo ufw allow 8000
```


---

# 18. Storage Management


Important directories:


```
~/piplayer/

Application code


~/piplayer/database/

SQLite database


~/piplayer/logs/

Application logs


~/Music/

Optional local music
```


---

# 19. Logging


Logs should be stored locally.


Example:


```
logs/

├── app.log

├── player.log

└── errors.log
```


Avoid excessive logging because SD cards have limited writes.

---

# 20. Boot Process


Expected startup:


```
Power On

    |

Linux Boot

    |

Network Available

    |

mpv Service Starts

    |

PiPlayer Backend Starts

    |

Web Interface Available

```


---

# 21. systemd Services


Two services:


## mpv service


Responsible for:

- Keeping player alive
- Creating IPC socket


---

## PiPlayer service


Responsible for:

- Starting FastAPI
- Serving UI
- Managing backend


---

# 22. Maintenance Commands


Check service:


```bash
systemctl status piplayer
```


Restart:


```bash
sudo systemctl restart piplayer
```


View logs:


```bash
journalctl -u piplayer -f
```


---

# 23. Backup


Important files:


```
database.db

config files

playlists

favorites
```


Backup:


```bash
cp database.db backup.db
```


---

# 24. Raspberry Pi Optimization


Recommended:


Disable unnecessary services:


```bash
systemctl list-unit-files
```


Remove unused packages.


---

# 25. Expected Resource Usage


Target:


Application:

```
50-150MB RAM
```


mpv:

```
30-80MB RAM
```


CPU while playing:

```
<10%
```


Storage:

```
<1GB
```


---

# 26. Final Raspberry Pi State


After setup:


The Raspberry Pi should:

- Boot automatically
- Start mpv
- Start PiPlayer backend
- Connect to network
- Serve browser UI
- Play audio
- Require no manual commands


The device becomes a dedicated network music player.