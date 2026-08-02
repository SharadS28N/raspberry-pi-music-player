# PiPlayer - System Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
01-system-architecture.md
```

Purpose:

Define the complete technical architecture of PiPlayer, including system components, communication flow, data flow, and design decisions.

---

# 1. Architecture Overview

PiPlayer follows a client-server architecture.

The Raspberry Pi acts as the central server and playback machine.

Users interact through a browser connected to the Raspberry Pi over a local network.

The system is divided into five major layers:

```
+------------------------------------------------+
|                 User Layer                     |
|                                                |
|              Browser Interface                 |
+------------------------------------------------+

                     |
                     |
                     HTTP/WebSocket

                     |

+------------------------------------------------+
|              Application Layer                 |
|                                                |
|              FastAPI Backend                   |
+------------------------------------------------+

          |              |              |

          |              |              |

+----------------+ +------------+ +-------------+
| Media Search   | | Database   | | Player      |
| yt-dlp         | | SQLite     | | Controller  |
+----------------+ +------------+ +-------------+

                     |

                     |

+------------------------------------------------+
|              Playback Layer                    |
|                                                |
|                    mpv                         |
+------------------------------------------------+

                     |

                     |

+------------------------------------------------+
|              Hardware Layer                    |
|                                                |
|      ALSA / PulseAudio / Bluetooth             |
|                                                |
|      Raspberry Pi Audio Output                 |
+------------------------------------------------+
```

---

# 2. System Components

PiPlayer consists of the following services:


## 2.1 Browser Client

Role:

User interface.


Responsibilities:

- Display application UI
- Send user commands
- Display search results
- Display current playback state
- Receive live updates


The browser does NOT:

- Play the audio
- Download music
- Control hardware directly


---

## 2.2 FastAPI Backend

Role:

Main application controller.


Responsibilities:

- Handle HTTP requests
- Manage WebSocket connections
- Control mpv
- Manage queue
- Coordinate services
- Handle application state


The backend is the central communication point.

---

## 2.3 Player Controller

Role:

Interface between PiPlayer and mpv.


Responsibilities:

- Start playback
- Pause playback
- Resume playback
- Change volume
- Seek
- Read playback state


Communication:

```
FastAPI
   |
   |
JSON IPC
   |
   |
mpv
```

---

## 2.4 mpv

Role:

Actual audio playback engine.


mpv handles:

- Audio decoding
- Buffering
- Playback
- Audio output


PiPlayer does not decode audio itself.

---

## 2.5 yt-dlp Service

Role:

Media discovery and URL extraction.


Responsibilities:

- Search online sources
- Extract metadata
- Resolve playable streams


Example:

User searches:

```
Daft Punk Get Lucky
```


Flow:

```
Frontend

   |

FastAPI

   |

yt-dlp

   |

Search Results

   |

Frontend
```

---

## 2.6 SQLite Database

Role:

Persistent storage.


Stores:

- Song history
- Favorites
- Playlists
- User settings
- Queue state


SQLite is chosen because:

- Lightweight
- No database server required
- Perfect for Raspberry Pi


---

# 3. Complete Data Flow

## 3.1 Application Startup


Boot sequence:


```
Raspberry Pi Starts

        |

Linux Starts

        |

systemd starts PiPlayer

        |

FastAPI starts

        |

mpv starts:

--idle=yes
--input-ipc-server=/tmp/mpv.sock

        |

Application Ready

        |

Browser Can Connect
```

---

# 4. Playback Architecture


## User Plays Song


Sequence:


```
User

 |

 | Click Play

 |

Browser

 |

 | POST /api/play

 |

FastAPI

 |

 | Request media URL

 |

yt-dlp

 |

 | Return playable URL

 |

Player Controller

 |

 | loadfile command

 |

mpv

 |

 | Decode Audio

 |

ALSA

 |

Speaker
```

---

# 5. Communication Methods


PiPlayer uses three communication methods.


## HTTP REST API


Used for:

- Commands
- Search
- Settings
- Queue operations


Example:


```
POST /api/play
```


---

## WebSocket


Used for:

- Live updates
- Playback state
- Queue changes


Example:


When song changes:

```
mpv

 |

FastAPI

 |

WebSocket

 |

All browsers
```


---

## mpv JSON IPC


Used internally.


Example:


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

# 6. Process Architecture


Running processes:


```
Linux
 |
 |
 +-- FastAPI Process
 |
 |
 +-- mpv Process
 |
 |
 +-- Browser Connections
```


Optional temporary processes:


```
FastAPI

 |
 |
 +-- yt-dlp process
```

yt-dlp only runs during searches.

---

# 7. Internal Module Architecture


Backend structure:


```
backend/

├── app.py

├── routes/

│   ├── player.py

│   ├── search.py

│   ├── queue.py

│   └── settings.py


├── services/

│   ├── mpv_service.py

│   ├── youtube_service.py

│   ├── queue_service.py

│   └── websocket_service.py


├── database/

│   ├── models.py

│   └── database.py


└── config.py
```


---

# 8. Dependency Direction


Rules:


```
Routes

  ↓

Services

  ↓

Database / External Systems
```


A module should not skip layers.


Example:


Correct:


```
API Route

↓

Player Service

↓

mpv
```


Incorrect:


```
API Route

↓

Direct mpv command
```


---

# 9. Playback State Machine


The player exists in one of these states:


```
              +-------+
              | Idle  |
              +-------+
                  |
                  |
               Loading
                  |
                  |
          +---------------+
          |               |
          v               v

       Playing        Error

          |
          |
       Paused

          |
          |
       Playing
```


States:


## Idle

No song loaded.


---

## Loading

mpv is preparing media.


---

## Playing

Audio actively playing.


---

## Paused

Audio stopped temporarily.


---

## Error

Playback failed.


---

# 10. Queue Architecture


Queue exists separately from mpv playlist.


Reason:

PiPlayer needs additional control.


Queue stores:


```
Song ID

Title

Artist

URL

Thumbnail

Duration

Position
```


Flow:


```
User Queue

      |

Queue Manager

      |

mpv Playlist
```


---

# 11. Multi Browser Support


Multiple devices can connect.


Example:


```
Phone

    |

    |

       Raspberry Pi

    |

    |

Laptop
```


Both receive:

- Current song
- Volume
- Queue
- Playback state


The Raspberry Pi is the source of truth.

---

# 12. Failure Handling


## mpv crashes


System should:

1. Detect process failure.
2. Restart mpv.
3. Restore queue.
4. Continue operation.


---

## Network failure


Browser:

Shows disconnected state.


When reconnecting:

Request current state.

---

## Invalid media


Example:

Deleted YouTube video.


Action:

- Remove failed item.
- Continue next song.
- Notify user.

---

# 13. Performance Architecture


The system is optimized for Raspberry Pi 3B+.


Targets:


RAM:

```
<200MB application usage
```


CPU:

```
Low idle usage
```


Storage:

```
<1GB application footprint
```


---

# 14. Design Decisions


## Why mpv?


Advantages:

- Lightweight
- Reliable
- Supports many formats
- Excellent Linux support
- JSON IPC control


---

## Why FastAPI?


Advantages:

- Fast
- Modern Python framework
- WebSocket support
- Simple API creation


---

## Why SQLite?


Advantages:

- No database server
- Small footprint
- Reliable
- Easy backup


---

## Why WebSockets?


Advantages:

- Instant UI updates
- Low network overhead
- Multiple clients stay synchronized


---

# 15. Final Architecture Summary


PiPlayer is a lightweight distributed application:


```
Browser

   |

FastAPI

   |

+----------------+
|                |
yt-dlp        mpv IPC

                 |

                mpv

                 |

             Audio Device

                 |

          Raspberry Pi Speakers
```


The browser controls the system.

The Raspberry Pi performs all playback.

The architecture is designed to be reliable, lightweight, and expandable.