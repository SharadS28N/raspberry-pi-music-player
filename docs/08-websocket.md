# PiPlayer - WebSocket Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
08-websocket.md
```

Purpose:

Define the real-time communication system between the PiPlayer backend and connected browser clients using WebSockets.

---

# 1. Overview

WebSockets provide real-time communication between:

```
Browser Clients

        |

        |

FastAPI WebSocket Server

        |

        |

PiPlayer Backend
```

Unlike normal HTTP requests, WebSockets maintain an active connection.

This allows instant updates for:

- Current song changes
- Playback status
- Queue updates
- Volume changes
- Connection state

---

# 2. Why WebSockets?

Normal HTTP:

```
Browser

   |

Request

   |

Server

   |

Response
```

The browser must repeatedly ask:

```
"Anything changed?"
```

This creates unnecessary traffic.


---

WebSocket:

```
Browser

   |

Permanent Connection

   |

Server Pushes Updates
```

The backend immediately sends changes.

---

# 3. WebSocket Responsibilities


The WebSocket system handles:


## Real-Time Playback Updates

Examples:

- Song started
- Song paused
- Song finished
- Position changed


---

## Multiple Client Synchronization


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


Both devices receive identical playback state.

---

## UI Synchronization


When one user changes volume:


```
Phone

 |

Volume +10

 |

Backend

 |

WebSocket Broadcast

 |

Laptop UI Updates
```

---

# 4. WebSocket Endpoint


Main endpoint:


```
ws://192.168.18.159/ws
```


Development:


```
ws://localhost:8000/ws
```


---

# 5. Connection Flow


Browser opens application:


```
Browser

 |

Connect WebSocket

 |

Backend accepts connection

 |

Client added to manager

 |

Initial state sent

 |

Live updates begin
```


---

# 6. WebSocket Manager


File:


```
services/websocket_service.py
```


Responsibilities:


- Maintain connections
- Broadcast events
- Remove disconnected clients


---

# 7. Connection Storage


Example:


```
WebSocket Manager


connections = [

 Browser 1,

 Browser 2,

 Browser 3

]
```


---

# 8. Client Lifecycle


## Connect


Action:


```
Add socket
Send current state
```


---

## Active


Action:


```
Receive events
```


---

## Disconnect


Action:


```
Remove socket
Cleanup resources
```


---

# 9. Event Architecture


All messages follow:


```json
{
"type":"event_name",

"data":{}
}
```


Example:


```json
{
"type":"song_changed",

"data":
{
"title":"Song Name"
}
}
```

---

# 10. Event Types


Supported events:


```
song_changed

playback_started

playback_paused

playback_stopped

position_update

volume_changed

queue_updated

connection_status
```

---

# 11. Song Changed Event


Sent when:


- New song starts
- User skips
- Queue advances


Example:


```json
{
"type":"song_changed",

"data":
{
"title":"Random Access Memories",

"artist":"Daft Punk",

"thumbnail":"image"
}
}
```


Frontend updates:


- Artwork
- Title
- Artist

---

# 12. Playback Started Event


Example:


```json
{
"type":"playback_started",

"data":
{
"position":0
}
}
```


---

# 13. Playback Paused Event


Example:


```json
{
"type":"playback_paused",

"data":
{
"position":120
}
}
```


---

# 14. Position Updates


The player position changes constantly.


Example:


```
Song duration:

300 seconds


Current:

125 seconds
```


Event:


```json
{
"type":"position_update",

"data":
{
"position":125
}
}
```


---

# 15. Update Frequency


Position updates should not overload the network.


Recommended:


```
Every 1 second
```


---

# 16. Volume Event


Example:


```json
{
"type":"volume_changed",

"data":
{
"volume":75
}
}
```


---

# 17. Queue Updated Event


Triggered when:


- Song added
- Song removed
- Order changed


Example:


```json
{
"type":"queue_updated",

"data":
{
"count":10
}
}
```


---

# 18. Backend Event Flow


Example:


Song finishes:


```
mpv

 |

end-file event

 |

Player Service

 |

Queue Service

 |

New Song

 |

WebSocket Manager

 |

All Browsers
```


---

# 19. Frontend Event Handling


JavaScript:


```
Receive event

        |

Check type

        |

Update application state

        |

Refresh UI
```


---

# 20. Reconnection Handling


Network can fail.


Example:


```
Browser

 |

Connection Lost

 |

Retry

 |

Reconnect

 |

Request Current State
```


---

# 21. Heartbeat System


To detect dead connections:


Backend sends:


```
ping
```


Client replies:


```
pong
```


Interval:


```
30 seconds
```


---

# 22. Connection State


Frontend maintains:


```
CONNECTED

CONNECTING

DISCONNECTED
```


UI example:


Connected:


```
● Online
```


Disconnected:


```
● Reconnecting...
```


---

# 23. Multiple Browser Behavior


Example:


```
Browser A:

Press Pause


        |

        |

Backend


        |

        |

Broadcast


        |

        |

Browser B:

Pause button changes
```


---

# 24. Error Handling


## Client Disconnect


Action:


```
Remove connection
```


---

## Failed Broadcast


Action:


```
Remove invalid socket
```


---

## Backend Restart


After restart:


Clients:

```
Reconnect automatically
```


---

# 25. Performance Considerations


Avoid sending:


- Large payloads
- Duplicate events
- Unnecessary updates


Prefer:


Small JSON messages.


---

# 26. Security Considerations


Current:


LAN only.


Future:


Add:


- Authentication
- User sessions
- Encrypted WebSocket
- Permissions


---

# 27. WebSocket Data Models


Playback state:


```json
{
"song":"Song",

"artist":"Artist",

"playing":true,

"position":100,

"volume":80
}
```


---

# 28. Complete Communication Architecture


```
                Browser 1

                    |

                    |

                WebSocket

                    |

                    |

              WebSocket Manager

                    |

                    |

               FastAPI Backend

                    |

          -----------------------

          |                     |

       Player              Queue

          |

         mpv
```


---

# 29. Final Objective


The WebSocket system makes PiPlayer feel like a modern streaming application.

Every connected browser should instantly know:

- What is playing
- Where playback is
- Current volume
- Queue changes
- Player status

The Raspberry Pi remains the single source of truth while every interface stays synchronized.