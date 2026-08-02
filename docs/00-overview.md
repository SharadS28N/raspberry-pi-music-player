# PiPlayer - Project Overview

## Document Information

Project:

```
PiPlayer
```

Document:

```
00-overview.md
```

Purpose:

Define the overall vision, goals, scope, architecture direction, and development principles of PiPlayer.

---

# 1. Project Introduction

PiPlayer is a self-hosted, lightweight music streaming and playback system designed to run on a Raspberry Pi.

It provides a modern browser-based music interface that allows users to control music playback from any device connected to the same network.

The Raspberry Pi acts as:

- Music server
- Playback device
- Queue manager
- Media controller


The browser acts as:

- User interface
- Remote control
- Search interface
- Playlist manager


The system is designed to provide a premium music application experience while running on low-power hardware.

---

# 2. Core Idea

The main idea:

> Turn a Raspberry Pi into a personal music appliance controlled completely through a web browser.

A user should be able to:

1. Open a browser.
2. Visit:

```
http://192.168.18.159
```

3. Search for music.
4. Press play.
5. Hear audio from the Raspberry Pi.
6. Control everything without SSH.


Normal usage should require no terminal access.

SSH is only for:

- Installation
- Updates
- Maintenance
- Troubleshooting

---

# 3. Project Goals

## Primary Goals

### Browser-Based Music Control

Create a complete web interface for music playback.

Users should have access to:

- Search
- Play
- Pause
- Skip
- Queue management
- Volume control
- Progress control


---

### Lightweight Performance

The application must run comfortably on:

```
Raspberry Pi 3 Model B+
```

Hardware constraints:

```
RAM:
1GB

Storage:
10GB

CPU:
Quad-core ARM Cortex-A53
```


The application should avoid unnecessary resource usage.

---

### Modern User Experience

The interface should feel like a premium music application.

Required qualities:

- Smooth
- Responsive
- Clean
- Fast
- Visually polished


The UI should be inspired by modern music applications while maintaining an original PiPlayer identity.

---

# 4. Non Goals

PiPlayer is NOT intended to be:

## A YouTube Clone

The application does not host video content.

It only uses online sources to obtain playable audio.

---

## A Full Streaming Service

It is a personal music system.

Not intended for:

- Millions of users
- Public distribution
- Commercial streaming

---

## A Video Player

The main purpose is music playback.

Video support is optional and secondary.

---

## A Heavy Media Server

PiPlayer is not designed to replace:

- Jellyfin
- Plex
- Large NAS systems


---

# 5. Target Hardware

Primary device:

```
Raspberry Pi 3B+
```


Expected environment:

```
Raspberry Pi OS
Linux
Python 3
Local network
```


Audio output:

Supported:

- HDMI
- 3.5mm audio
- USB DAC
- Bluetooth speakers


---

# 6. High Level Architecture


```
                    User Device

                  Web Browser
                       |
                       |
                HTTP / WebSocket
                       |
                       |
              -------------------
              |                 |
              |   FastAPI       |
              |   Backend       |
              |                 |
              -------------------
                 |       |      |
                 |       |      |
                 |       |      |
              yt-dlp   SQLite  mpv IPC
                 |              |
                 |              |
              YouTube          mpv
                                |
                                |
                           Audio System
                                |
                                |
                          Raspberry Pi
```


---

# 7. Main Components


## Frontend

Responsible for:

- User interface
- User interactions
- Displaying playback state
- Sending commands


Technologies:

- HTML
- CSS
- JavaScript
- HTMX
- Alpine.js


---

## Backend

Responsible for:

- API handling
- Business logic
- Player control
- Queue management
- Database operations


Technology:

```
Python + FastAPI
```


---

## mpv Player

Responsible for:

- Audio playback
- Seeking
- Volume
- Playback state


Communication:

```
JSON IPC
```


---

## yt-dlp

Responsible for:

- Searching music sources
- Extracting metadata
- Resolving playable URLs


---

## SQLite

Responsible for:

- History
- Favorites
- Playlists
- Settings


---

# 8. User Experience Flow


## Starting Application


System boots.


↓

systemd starts PiPlayer service.


↓

Backend starts.


↓

mpv starts in idle mode.


↓

Browser can connect.


---

# Playing Music Flow


User:

Searches song.


↓

Frontend:

Sends search request.


↓

Backend:

Uses yt-dlp.


↓

Results returned.


↓

User clicks play.


↓

Backend sends command to mpv.


↓

mpv loads audio.


↓

Raspberry Pi outputs sound.


↓

Frontend receives update.


↓

Player UI updates.


---

# 9. Feature Scope


## Version 1 (MVP)


Required:


Playback:

- Play
- Pause
- Resume
- Stop
- Next
- Previous


Search:

- Search songs
- Display results
- Play result


Queue:

- Add songs
- Remove songs
- View queue


Player:

- Volume
- Progress
- Current song


---

# Version 2


Add:

- Album artwork
- Better queue controls
- History
- Favorites
- Playlists
- Mobile UI


---

# Version 3


Add:

- Multi-user support
- Lyrics
- Themes
- Equalizer
- Local music library


---

# 10. Design Principles


## Simple

Avoid unnecessary complexity.


## Modular

Each component should have a clear responsibility.


Example:

Bad:

```
app.py handles everything
```


Good:

```
player.py
youtube.py
database.py
queue.py
```


---

## Lightweight

Every dependency should have a purpose.


---

## Reliable

The system should recover from:

- mpv crashes
- Network failures
- Invalid URLs
- Missing files


---

# 11. Development Principles


Code should follow:


- Python best practices
- Clear naming
- Type hints
- Documentation
- Small functions
- Error handling


---

# 12. Security Model


Initial version:

LAN only.


Example:

```
Home WiFi
    |
    |
Raspberry Pi
    |
    |
Browser devices
```


No public internet exposure.


Future:

- Authentication
- HTTPS
- User permissions


---

# 13. Success Criteria


PiPlayer is successful when:


A user can:


1. Turn on Raspberry Pi.

2. Open:

```
http://192.168.18.159
```

3. See a beautiful music interface.

4. Search a song.

5. Press play.

6. Hear music from Raspberry Pi.

7. Control playback completely from browser.


The Raspberry Pi becomes a dedicated personal music system.