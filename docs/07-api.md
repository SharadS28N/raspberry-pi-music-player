# PiPlayer - API Specification

## Document Information

Project:

```
PiPlayer
```

Document:

```
07-api.md
```

Purpose:

Define the backend API structure, endpoints, request formats, response formats, error handling, and communication rules between the frontend and backend.

---

# 1. API Overview

The PiPlayer API is the communication layer between:

```
Browser Frontend

        |

        |

FastAPI Backend

        |

        |

Internal Services
```

The API provides access to:

- Music search
- Playback control
- Queue management
- Playlists
- Favorites
- History
- Settings

---

# 2. API Design Principles


The API follows:


## REST Architecture

Resources are represented as URLs.


Example:


```
/api/search

/api/player

/api/queue
```


---

## JSON Communication


All requests and responses use:


```
application/json
```


---

## Stateless Requests


Each request should contain enough information to process itself.

---

# 3. Base URL


Development:


```
http://localhost:8000
```


Production:


```
http://192.168.18.159:8000
```


---

# 4. API Versioning


Current:


```
/api/v1/
```


Example:


```
/api/v1/search
```


Future versions:


```
/api/v2/
```


---

# 5. Response Format


Successful response:


```json
{
 "success":true,
 "data":{}
}
```


---

Error response:


```json
{
 "success":false,
 "error":
 {
   "code":"PLAYER_ERROR",
   "message":"Unable to play song"
 }
}
```


---

# 6. Search API


## Search Songs


Endpoint:


```
GET /api/v1/search
```


Parameters:


```
q

query string
```


Example:


```
GET /api/v1/search?q=daft+punk
```


---

Response:


```json
{
 "success":true,

 "data":
 [
  {
   "id":"abc123",

   "title":"One More Time",

   "artist":"Daft Punk",

   "thumbnail":"image_url",

   "duration":320,

   "url":"youtube_url"
  }
 ]
}
```


---

# 7. Player API


## Get Player State


Endpoint:


```
GET /api/v1/player
```


Response:


```json
{
"success":true,

"data":
{
 "state":"playing",

 "title":"Song Name",

 "artist":"Artist",

 "position":120,

 "duration":300,

 "volume":70
}
}
```


---

# 8. Play Song


Endpoint:


```
POST /api/v1/player/play
```


Request:


```json
{
"url":"media_url"
}
```


Response:


```json
{
"success":true,

"message":"Playback started"
}
```


---

# 9. Pause Playback


Endpoint:


```
POST /api/v1/player/pause
```


Response:


```json
{
"success":true
}
```


---

# 10. Resume Playback


Endpoint:


```
POST /api/v1/player/resume
```


---

# 11. Stop Playback


Endpoint:


```
POST /api/v1/player/stop
```


---

# 12. Next Song


Endpoint:


```
POST /api/v1/player/next
```


Purpose:


Skip current song.


---

# 13. Previous Song


Endpoint:


```
POST /api/v1/player/previous
```


---

# 14. Seek


Endpoint:


```
POST /api/v1/player/seek
```


Request:


```json
{
"position":120
}
```


Position:

Seconds.


---

# 15. Volume Control


Endpoint:


```
POST /api/v1/player/volume
```


Request:


```json
{
"volume":80
}
```


Range:


```
0-100
```


---

# 16. Queue API


## Get Queue


Endpoint:


```
GET /api/v1/queue
```


Response:


```json
{
"success":true,

"data":
[
 {
  "id":1,

  "title":"Song",

  "artist":"Artist"
 }
]
}
```


---

# 17. Add To Queue


Endpoint:


```
POST /api/v1/queue/add
```


Request:


```json
{
"title":"Song",

"url":"media_url",

"thumbnail":"image"
}
```


---

# 18. Remove From Queue


Endpoint:


```
DELETE /api/v1/queue/{id}
```


Example:


```
DELETE /api/v1/queue/5
```


---

# 19. Clear Queue


Endpoint:


```
DELETE /api/v1/queue
```


---

# 20. Move Queue Item


Endpoint:


```
PUT /api/v1/queue/move
```


Request:


```json
{
"id":5,

"position":2
}
```


---

# 21. Favorites API


## Get Favorites


```
GET /api/v1/favorites
```


---

## Add Favorite


```
POST /api/v1/favorites
```


Request:


```json
{
"song_id":10
}
```


---

## Remove Favorite


```
DELETE /api/v1/favorites/{id}
```


---

# 22. History API


## Get History


```
GET /api/v1/history
```


Response:


```json
[
 {
"title":"Song",

"played_at":"2026-01-01"
 }
]
```


---

# 23. Playlist API


## Get Playlists


```
GET /api/v1/playlists
```


---

## Create Playlist


```
POST /api/v1/playlists
```


Request:


```json
{
"name":"My Playlist"
}
```


---

## Add Song To Playlist


```
POST /api/v1/playlists/{id}/songs
```


---

# 24. Settings API


## Get Settings


```
GET /api/v1/settings
```


---

## Update Settings


```
PUT /api/v1/settings
```


Example:


```json
{
"volume":70,

"theme":"blue"
}
```


---

# 25. System API


## Health Check


Endpoint:


```
GET /api/v1/health
```


Response:


```json
{
"status":"ok",

"player":"connected",

"database":"connected"
}
```


---

# 26. WebSocket Endpoint


Realtime communication:


```
ws://192.168.18.159/ws
```


Used for:


- Playback updates
- Queue changes
- Player state


---

# 27. API Error Codes


Common errors:


## PLAYER_ERROR


mpv communication failure.


---

## MEDIA_ERROR


Unable to load media.


---

## SEARCH_ERROR


Search failed.


---

## DATABASE_ERROR


Storage failure.


---

## INVALID_REQUEST


Bad input.


---

# 28. Validation Rules


All incoming data must be validated.


Examples:


Volume:


```
0 <= volume <= 100
```


Seek:


```
position >= 0
```


Song URL:

Must be valid.


---

# 29. Security Rules


Never trust browser input.


Backend must:


- Validate parameters
- Sanitize strings
- Limit requests
- Prevent command injection


---

# 30. API Flow Example


User presses play:


```
Browser

 |

POST /player/play

 |

FastAPI

 |

Player Service

 |

mpv IPC

 |

Audio Starts

 |

WebSocket Event

 |

Browser Updates
```


---

# 31. Future API Extensions


Possible additions:


```
/users

/devices

/downloads

/radio

/lyrics

/equalizer
```


---

# 32. Final API Architecture


```
                 Frontend

                    |

                    |

              REST API

                    |

                    |

              FastAPI

                    |

        ---------------------

        |         |         |

     Player    Queue    Database

        |

       mpv
```


The API acts as the stable communication contract between the PiPlayer interface and the internal playback system.