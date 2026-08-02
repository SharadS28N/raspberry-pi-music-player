# PiPlayer - Backend Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
03-backend.md
```

Purpose:

Define the backend architecture, application structure, services, modules, responsibilities, data flow, and development standards for the PiPlayer server application.

---

# 1. Backend Overview

The PiPlayer backend is the central control system of the application.

It connects:

- Browser frontend
- mpv player
- YouTube search engine
- Database
- Queue system
- WebSocket clients


The backend is responsible for all application logic.

The browser never directly communicates with:

- mpv
- yt-dlp
- SQLite


All communication passes through the backend.

---

# 2. Backend Technology


Language:

```
Python 3.11+
```


Framework:

```
FastAPI
```


Server:

```
Uvicorn
```


Database:

```
SQLite
```


Communication:

```
REST API
WebSockets
mpv JSON IPC
```


---

# 3. Backend Responsibilities


The backend handles:


## Application Control

- Start application
- Load configuration
- Initialize services
- Manage shutdown


---

## Player Control

Communicates with mpv.

Handles:

- Play
- Pause
- Resume
- Stop
- Seek
- Volume
- Current state


---

## Search System

Communicates with yt-dlp.

Handles:

- Search requests
- Metadata extraction
- Result formatting


---

## Queue Management

Handles:

- Adding songs
- Removing songs
- Ordering
- Playback sequence


---

## Database

Stores:

- History
- Favorites
- Playlists
- Settings


---

## Browser Communication

Handles:

- HTTP requests
- WebSocket events


---

# 4. Backend Directory Structure


Recommended:


```
backend/

├── main.py

├── config.py

├── dependencies.py


├── api/

│   ├── player_routes.py

│   ├── search_routes.py

│   ├── queue_routes.py

│   ├── playlist_routes.py

│   └── settings_routes.py


├── services/

│   ├── player_service.py

│   ├── youtube_service.py

│   ├── queue_service.py

│   ├── websocket_service.py

│   └── database_service.py


├── models/

│   ├── song.py

│   ├── playlist.py

│   └── user.py


├── database/

│   ├── connection.py

│   └── migrations.py


├── utils/

│   ├── logger.py

│   └── helpers.py


└── requirements.txt
```

---

# 5. Application Startup


Startup sequence:


```
Linux

 |

systemd

 |

Uvicorn

 |

FastAPI

 |

Load Config

 |

Connect Database

 |

Start Player Service

 |

Create WebSocket Manager

 |

Application Ready

```


---

# 6. Main Application


File:

```
main.py
```


Responsibilities:


- Create FastAPI instance
- Register routes
- Initialize services
- Handle startup/shutdown events


Example:


```
FastAPI Application

        |

        |

Routes

        |

        |

Services
```


---

# 7. Configuration System


File:


```
config.py
```


Stores:


- Server settings
- mpv socket path
- Database location
- Audio settings
- Environment variables


Example:


```
MPV_SOCKET=/tmp/mpv.sock

DATABASE=piplayer.db

PORT=8000

HOST=0.0.0.0
```


---

# 8. Service Architecture


Services contain the main logic.

Routes should not contain business logic.


Example:


Incorrect:


```
Route

   |
   |
   mpv command directly
```


Correct:


```
Route

   |

Player Service

   |

mpv
```


---

# 9. Player Service


File:


```
services/player_service.py
```


Purpose:


Control mpv.


Responsibilities:


- Connect to IPC socket
- Send commands
- Receive events
- Track playback state


Functions:


```
play()

pause()

resume()

stop()

next()

previous()

seek()

set_volume()

get_status()
```


---

# 10. Player Communication Flow


Example:

User presses pause.


```
Browser

 |

POST /api/player/pause

 |

FastAPI Route

 |

Player Service

 |

JSON IPC

 |

mpv

 |

Audio pauses

```


---

# 11. YouTube Service


File:


```
services/youtube_service.py
```


Purpose:


Communicate with yt-dlp.


Functions:


```
search()

get_metadata()

resolve_url()
```


---

# 12. Search Flow


```
User

 |

Search Input

 |

Frontend

 |

GET /api/search

 |

Search Route

 |

YouTube Service

 |

yt-dlp

 |

Results

 |

Frontend
```


---

# 13. Queue Service


File:


```
services/queue_service.py
```


Purpose:


Maintain playback order.


Functions:


```
add_song()

remove_song()

clear()

move()

get_queue()

next_song()
```


---

# 14. Queue Logic


Example:


Queue:


```
1. Song A
2. Song B
3. Song C
```


Current:


```
Song A
```


Next:


```
Song B
```


After completion:


```
Song B starts automatically
```


---

# 15. Database Service


File:


```
services/database_service.py
```


Handles:


- Connections
- Queries
- Transactions


Database:

```
SQLite
```


---

# 16. API Layer


Directory:


```
api/
```


Contains HTTP endpoints.


Example:


```
/api/search

/api/player/play

/api/player/pause

/api/queue

/api/playlists
```


---

# 17. Dependency Injection


FastAPI dependencies should provide:


- Database connections
- Services
- Authentication (future)


Example:


```
Request

 |

Dependency

 |

Service

 |

Response
```


---

# 18. WebSocket Service


File:


```
services/websocket_service.py
```


Responsibilities:


- Track connected clients
- Broadcast events
- Remove disconnected clients


---

# 19. Event System


Backend events:


```
SONG_CHANGED

PLAYBACK_STARTED

PLAYBACK_PAUSED

QUEUE_UPDATED

VOLUME_CHANGED

POSITION_UPDATED
```


Example:


```json
{
"type":"SONG_CHANGED",
"title":"Example Song"
}
```


---

# 20. Error Handling


All services must handle:


## Network errors

Example:

YouTube unavailable.


Action:

Return friendly error.


---

## Player errors

Example:

mpv stopped.


Action:

Restart player.


---

## Invalid media

Example:

Removed video.


Action:

Skip and continue.


---

# 21. Logging


Backend should use structured logging.


Example:


```
INFO:
Player started


WARNING:
Video unavailable


ERROR:
mpv connection failed
```


Log locations:


```
logs/

app.log

player.log

error.log
```


---

# 22. Background Tasks


Some tasks should run separately:


Examples:


- Playback monitoring
- Position updates
- Cleanup jobs


FastAPI background tasks can manage these.


---

# 23. Configuration Management


Never hardcode:


Bad:


```python
socket="/tmp/mpv.sock"
```


Good:


```python
settings.mpv_socket
```


---

# 24. Security


Initial version:


LAN only.


Requirements:


- Validate input
- Sanitize URLs
- Limit requests
- Avoid shell injection


---

# 25. Performance Rules


Backend must:


- Avoid blocking operations
- Use async where useful
- Cache repeated searches
- Avoid unnecessary database writes


---

# 26. Testing Requirements


Backend should support:


Unit tests:


- Queue logic
- Player commands
- Database functions


Integration tests:


- API endpoints
- WebSocket communication


---

# 27. Backend Development Rules


Follow:


- Clear module separation
- Type hints
- Docstrings
- Small functions
- No duplicated logic
- Proper error handling


---

# 28. Final Backend Architecture


```
                 Browser

                    |

              FastAPI Routes

                    |

              Service Layer

        -------------------------

        |          |            |

    Player     YouTube      Database

        |          |            |

       mpv      yt-dlp       SQLite


                    |

              WebSocket Updates

                    |

                 Browser
```


The backend is the brain of PiPlayer.

It connects the user interface, playback engine, and data storage into one reliable system.