# PiPlayer - mpv Integration Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
05-mpv-integration.md
```

Purpose:

Define how PiPlayer communicates with mpv, manages playback, handles player state, processes events, and maintains reliable audio playback on the Raspberry Pi.

---

# 1. Overview

mpv is the core playback engine of PiPlayer.

PiPlayer does not decode or process audio itself.

Instead:

```
Browser
   |
   |
FastAPI Backend
   |
   |
mpv
   |
   |
Audio Hardware
```

The backend controls mpv using mpv's built-in JSON IPC interface.

---

# 2. Why mpv?

mpv is chosen because it provides:

- Low resource usage
- Excellent Linux support
- Wide audio format support
- Reliable playback
- Scriptability
- JSON IPC control
- Hardware audio support


It runs efficiently on:

```
Raspberry Pi 3B+
```

---

# 3. mpv Responsibilities

mpv handles:


## Audio Playback

- Decoding audio
- Buffering
- Playback timing
- Audio output


---

## Media Control

- Play
- Pause
- Stop
- Seek
- Volume
- Track loading


---

## Audio Device Handling

Examples:

- HDMI
- ALSA
- USB DAC
- Bluetooth


---

# 4. Backend Responsibilities

PiPlayer backend handles:


- User commands
- Queue management
- Playback state
- Browser synchronization
- Error recovery


The backend never directly manipulates audio hardware.

---

# 5. mpv Startup


mpv runs as a background process.


Startup command:


```bash
mpv \
--idle=yes \
--no-video \
--input-ipc-server=/tmp/mpv.sock
```


---

# 6. Startup Parameters Explained


## --idle=yes


Keeps mpv alive without media.


Without this:

```
mpv starts
|
No file
|
Process exits
```


With idle:

```
mpv starts
|
Waits for commands
```


---

## --no-video


PiPlayer is audio-focused.


Prevents:

- Video rendering
- GPU usage
- Extra memory usage


---

## --input-ipc-server


Creates communication socket.


Example:


```
/tmp/mpv.sock
```


Backend connects here.

---

# 7. IPC Communication


Communication format:


```
JSON
```


Transport:


```
Unix Domain Socket
```


Connection:


```
FastAPI

   |

/tmp/mpv.sock

   |

mpv
```


---

# 8. Sending Commands


Every command follows:


```json
{
"command":
[
"command_name",
"argument"
]
}
```


---

# 9. Play Command


Example:


```json
{
"command":
[
"loadfile",
"https://example.com/audio.mp3",
"replace"
]
}
```


Modes:


## replace


Replace current song.


---

## append


Add to playlist.


---

## append-play


Add and immediately play.


---

# 10. Pause Command


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

# 11. Resume Command


```json
{
"command":
[
"set_property",
"pause",
false
]
}
```


---

# 12. Stop Command


```json
{
"command":
[
"stop"
]
}
```


---

# 13. Volume Control


Set volume:


```json
{
"command":
[
"set_property",
"volume",
75
]
}
```


Range:


```
0-100
```


---

# 14. Seek Control


Move playback position:


```json
{
"command":
[
"seek",
30,
"relative"
]
}
```


---

# 15. Reading Player Status


PiPlayer needs:


- Current file
- Time position
- Duration
- Pause state
- Volume


mpv properties:


```
time-pos

duration

pause

volume

media-title

playlist-pos
```


---

# 16. Property Observation


mpv can send events when values change.


Example:


```
Song changed

        |

mpv event

        |

Backend receives

        |

WebSocket update

        |

Browser updates
```


---

# 17. Playback State Model


PiPlayer maintains:


```
IDLE

LOADING

PLAYING

PAUSED

STOPPED

ERROR
```


---

# 18. State Synchronization


The backend is the source of truth.


Example:


```
mpv says:

pause=true


Backend updates:


state = PAUSED


Backend broadcasts:


WebSocket event


Browser changes UI
```


---

# 19. Player Service Design


File:


```
services/player_service.py
```


Responsibilities:


- Connect to socket
- Send commands
- Read responses
- Monitor events


---

# 20. Player Service Functions


Required:


```python
play(url)

pause()

resume()

stop()

next()

previous()

seek(seconds)

set_volume(value)

get_status()
```


---

# 21. Playback Monitoring


A background task should monitor mpv.


Example:


```
Every second:


Check:

- position
- duration
- state


Broadcast changes
```


---

# 22. Automatic Queue Progression


When song finishes:


Flow:


```
mpv

 |

end-file event

 |

Backend

 |

Queue Manager

 |

Next Song

 |

mpv loadfile

```


---

# 23. Error Handling


## mpv Not Running


Detection:


```
Socket unavailable
```


Action:


1. Restart mpv.
2. Reconnect.
3. Restore state.


---

## Broken Media URL


Example:


YouTube video deleted.


Action:


```
Remove item

Play next
```


---

# 24. mpv Process Management


Recommended:


Use a dedicated service.


Example:


```
mpv.service
```


Responsibilities:


- Start mpv
- Keep alive
- Restart after failure


---

# 25. Audio Output


mpv uses Linux audio systems.


Typical:


```
mpv

 |

ALSA

 |

Hardware Device

 |

Speaker
```


---

# 26. Recommended mpv Configuration


File:


```
~/.config/mpv/mpv.conf
```


Example:


```
audio-display=no

volume=80

keep-open=yes

save-position-on-quit=yes
```


---

# 27. Multiple Browser Support


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


Both clients receive the same:


- Song
- Position
- Volume
- Queue


---

# 28. Security Considerations


The IPC socket should:


- Be local only
- Not exposed over network
- Have correct permissions


Example:


```
/tmp/mpv.sock
```


Only backend user should access it.


---

# 29. Performance Considerations


mpv should:


- Run without video
- Avoid unnecessary filters
- Use hardware acceleration only if needed


Expected:


RAM:

```
30-80MB
```


CPU:

```
<10%
```


---

# 30. Complete Playback Architecture


```
                 User

                  |

              Browser UI

                  |

              FastAPI

                  |

          Player Service

                  |

          JSON IPC Socket

                  |

                 mpv

                  |

                ALSA

                  |

              Speakers
```


---

# 31. Final Objective


The mpv integration should make mpv behave like a professional music playback engine controlled remotely by PiPlayer.

The user should never need to interact with mpv directly.

All playback control happens through the browser interface.