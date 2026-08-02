# PiPlayer - Development Context

## Project Name

PiPlayer

A lightweight, self-hosted Spotify-style music player running on a Raspberry Pi.

The Raspberry Pi acts as the music server and playback device. Users control it through a browser-based interface.

---

# Main Goal

Create a web application where a user can open:

```
http://192.168.18.159
```

and get a modern music player UI.

The browser should allow:

- Searching songs
- Playing music
- Managing queue
- Controlling volume
- Controlling playback
- Viewing current song
- Managing playlists

The audio should physically play from the Raspberry Pi.

The browser is only a controller.

---

# Hardware Target

Device:

Raspberry Pi 3 Model B+

Specifications:

- CPU: Quad-core ARM Cortex-A53
- RAM: 1GB
- Storage: 10GB available
- Network: Local LAN
- OS: Raspberry Pi OS Linux

Expected audio outputs:

- HDMI
- 3.5mm jack
- USB DAC
- Bluetooth speaker

---

# Core Architecture

```
                 Browser
                    |
                    |
              HTTP/WebSocket
                    |
                    |
              FastAPI Server
                    |
        ---------------------------
        |            |            |
        |            |            |
    yt-dlp       Queue       mpv IPC
        |            |            |
        |            |            |
   YouTube       SQLite        mpv
                                |
                                |
                          Audio Output
                                |
                                |
                         Raspberry Pi Speaker
```

---

# Technology Stack

## Backend

Language:

Python 3

Framework:

FastAPI

Server:

Uvicorn


Responsibilities:

- Handle browser requests
- Control mpv
- Search YouTube
- Manage queue
- Store data
- Broadcast updates


---

## Frontend

Technologies:

- HTML
- CSS
- JavaScript
- HTMX
- Alpine.js
- Tailwind CSS

Reason:

Keep memory usage low.

Avoid heavy frameworks because Raspberry Pi 3B+ has only 1GB RAM.

---

## Player Engine

Player:

mpv


Start command:

```
mpv \
--idle=yes \
--input-ipc-server=/tmp/mpv.sock
```


Communication:

mpv JSON IPC


Examples:

Play:

```json
{
 "command":
 [
  "loadfile",
  "youtube_url",
  "append-play"
 ]
}
```


Pause:

```json
{
 "command":
 [
  "set_property",
  "pause",
  true
 ]
}
```

---

# YouTube Integration

Tool:

yt-dlp


Purpose:

- Search YouTube
- Extract video information
- Provide playable URLs


Example:

```
yt-dlp "ytsearch5:daft punk"
```


Search result should provide:

- Title
- Artist/channel
- Thumbnail
- Duration
- URL


---

# User Interface Design

Style:

Spotify-inspired.

Do not copy Spotify branding.

Theme:

Blue dark mode.

Colors:

```
Background:
#08111F

Sidebar:
#0F172A

Cards:
#16243B

Primary Blue:
#3B82F6

Light Blue:
#60A5FA

Text:
#F8FAFC
```

---

# UI Layout

```
------------------------------------------------
| Sidebar | Search                              |
|         |-------------------------------------|
| Home    |                                     |
| Search  |        Current Song                 |
| Queue   |                                     |
| Songs   |        Album Image                  |
| Fav     |                                     |
|         |        Controls                     |
|         |                                     |
------------------------------------------------
|              Player Controls                  |
------------------------------------------------
```

---

# Main Features

## Playback

Required:

- Play
- Pause
- Resume
- Stop
- Next
- Previous
- Seek
- Volume


---

## Queue

Required:

- Add song
- Remove song
- Reorder songs
- Clear queue
- Play next
- Save queue


---

## Search

User can:

1. Enter song name
2. Backend searches YouTube
3. Results appear
4. User clicks play
5. mpv starts playback


---

## Player Information

Display:

- Current song
- Artist
- Thumbnail
- Duration
- Progress
- Volume


---

# Backend Structure

Recommended:

```
piplayer/

├── app.py
├── player.py
├── youtube.py
├── queue.py
├── database.py
├── websocket.py
├── config.py
│
├── templates/
│   └── index.html
│
├── static/
│   ├── css/
│   └── js/
│
├── database.db
│
└── requirements.txt
```

---

# Module Responsibilities

## app.py

Main FastAPI application.

Handles:

- Routes
- Server startup
- WebSocket connection


---

## player.py

Handles mpv.

Functions:

- play()
- pause()
- resume()
- volume()
- seek()
- get_status()


---

## youtube.py

Handles:

- Search
- Metadata extraction
- URL resolving


---

## queue.py

Handles:

- Queue storage
- Adding songs
- Removing songs
- Ordering


---

## database.py

Handles SQLite.

Stores:

- History
- Favorites
- Playlists
- Settings


---

# API Design

## Search

```
GET /api/search?q=song_name
```


Response:

```json
[
 {
  "title":"Song",
  "artist":"Artist",
  "thumbnail":"url",
  "url":"youtube_url"
 }
]
```


---

## Play

```
POST /api/play
```


---

## Pause

```
POST /api/pause
```


---

## Volume

```
POST /api/volume
```

Example:

```json
{
"volume":70
}
```

---

# WebSocket

Endpoint:

```
/ws
```


Used for live updates.

Events:

```
song_changed

queue_updated

volume_changed

position_changed

player_state_changed
```


Example:

```json
{
"type":"song_changed",
"title":"Example Song"
}
```

---

# Database

Use:

SQLite


Tables:


## songs

Stores played songs.

Fields:

```
id
title
artist
url
thumbnail
duration
created_at
```


## favorites

```
id
song_id
created_at
```


## history

```
id
song_id
played_at
```


## playlists

```
id
name
created_at
```


---

# Deployment

Application runs as a Linux service.


Service:

```
piplayer.service
```


Starts automatically:

```
systemctl enable piplayer
```


Access:

```
http://raspberrypi-ip-address
```


---

# Performance Goals

Target:

RAM:

<200MB


CPU idle:

<5%


Fast startup:

<10 seconds


Must run comfortably on Raspberry Pi 3B+.

---

# Development Rules

- Keep code modular
- Avoid unnecessary dependencies
- Use Python type hints
- Use clear naming
- Handle errors gracefully
- Log important events
- Never control mpv using keyboard simulation
- Always use mpv JSON IPC

---

# Future Features

Possible additions:

- Mobile UI
- Lyrics
- Playlists
- Favorites
- History
- Multiple users
- Bluetooth management
- Local music library
- Equalizer
- Themes
- Offline mode

---

# Final Objective

The finished system should allow:

1. User opens browser.
2. User visits:

```
http://192.168.18.159
```

3. User searches a song.
4. User clicks play.
5. Raspberry Pi plays the audio.
6. User controls everything from the browser.

The Raspberry Pi becomes a dedicated self-hosted music appliance.