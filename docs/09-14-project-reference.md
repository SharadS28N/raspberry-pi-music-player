# PiPlayer - Database, UI Design, Deployment, Development, Testing & Roadmap

## Document Information

Project:

```
PiPlayer
```

Combined Documents:

```
09-database.md
10-ui-design.md
11-deployment.md
12-development-guide.md
13-testing.md
14-roadmap.md
```

Purpose:

Define the remaining technical documentation required for building, deploying, maintaining, and improving PiPlayer.

---

# 09 - Database Architecture

# 1. Database Overview

PiPlayer uses SQLite as its primary database.

Reasons:

- Lightweight
- No database server required
- Low RAM usage
- Reliable
- Perfect for Raspberry Pi


Architecture:


```
FastAPI Backend

        |

        |

Database Service

        |

        |

SQLite Database
```


---

# 2. Database Location


Recommended:


```
/home/aamps/piplayer/database/piplayer.db
```


---

# 3. Database Responsibilities


The database stores:


- Song history
- Favorites
- Playlists
- Queue state
- Application settings


---

# 4. Database Tables


Main tables:


```
songs

history

favorites

playlists

playlist_songs

queue

settings
```


---

# 5. Songs Table


Purpose:

Store known songs.


Schema:


```
songs

id

title

artist

url

thumbnail

duration

source

created_at
```


---

# 6. History Table


Stores playback history.


Schema:


```
history

id

song_id

played_at
```


Example:


```
Song played:

2026-01-01 12:00
```


---

# 7. Favorites Table


Stores liked songs.


Schema:


```
favorites

id

song_id

created_at
```


---

# 8. Playlists Table


Schema:


```
playlists

id

name

created_at
```


---

# 9. Playlist Songs Table


Relationship:


```
Playlist

 |

Many Songs
```


Schema:


```
playlist_songs

id

playlist_id

song_id

position
```


---

# 10. Queue Table


Stores current queue.


Schema:


```
queue

id

song_id

position

added_at
```


---

# 11. Settings Table


Stores configuration.


Schema:


```
settings

key

value
```


Examples:


```
theme=blue

volume=80
```


---

# 12. Database Rules


Always:


- Use migrations
- Validate input
- Use prepared queries
- Avoid unnecessary writes


---

# 10 - UI Design Specification


# 1. Design Philosophy


PiPlayer should feel like a premium music application.


Design goals:


- Modern
- Minimal
- Smooth
- Dark interface
- Blue accent theme


---

# 2. Visual Identity


Theme:


```
Dark Spotify-inspired interface
```


Main colors:


Background:


```
#07111F
```


Surface:


```
#10243A
```


Primary Blue:


```
#1E90FF
```


Highlight:


```
#4DA3FF
```


Text:


```
#FFFFFF
```


Secondary text:


```
#9CA3AF
```


---

# 3. Layout


Desktop:


```
+--------------------------------+
| Sidebar                        |
|                                |
| Home                           |
| Search                         |
| Library                        |
|                                |
+--------------+-----------------+
               |
               |
          Content Area

---------------------------------
        Player Bar
---------------------------------
```


---

# 4. Player Bar


Always visible.


Contains:


```
Artwork

Song Name

Artist

Previous

Play/Pause

Next

Progress

Volume
```


---

# 5. UI Components


Components:


```
Sidebar

Navbar

Song Card

Album Card

Search Result

Queue Panel

Player Controls

Volume Slider
```


---

# 6. Animation Rules


Use:


```
150-300ms transitions
```


Examples:


- Hover effects
- Button scaling
- Smooth panels


Avoid:


- Heavy animations
- GPU intensive effects


---

# 7. Mobile Design


Mobile changes:


Desktop sidebar:


```
hidden
```


Navigation:


```
bottom navigation
```


Player:


```
compact player
```


---

# 11 - Deployment Guide


# 1. Deployment Overview


Deployment target:


```
Raspberry Pi 3B+
```


The system should start automatically after boot.


---

# 2. Production Structure


```
/home/aamps/piplayer/


backend/

frontend/

database/

logs/

venv/
```


---

# 3. Required Services


Two system services:


```
mpv.service


piplayer.service
```


---

# 4. mpv Service


Purpose:


Keep player running.


Starts:


```
mpv --idle=yes
```


---

# 5. PiPlayer Service


Starts:


```
FastAPI server
```


Example:


```
uvicorn main:app
```


---

# 6. Boot Sequence


```
Power On

 |

Linux

 |

Network

 |

mpv

 |

Backend

 |

Browser Access
```


---

# 7. Updating Application


Steps:


```
git pull

activate venv

install updates

restart service
```


---

# 8. Backup


Backup:


```
database

configuration

playlists
```


---

# 12 - Development Guide


# 1. Development Environment


Required:


```
Python 3

Git

VS Code

Linux environment
```


---

# 2. Development Setup


Clone:


```
git clone repository
```


Create environment:


```
python3 -m venv venv
```


Install:


```
pip install -r requirements.txt
```


---

# 3. Coding Structure


Follow:


```
Routes

↓

Services

↓

Database / External Systems
```


---

# 4. Development Rules


Always:


- Write clean code
- Document functions
- Handle errors
- Avoid duplicate logic


---

# 5. Feature Development Flow


```
Idea

 |

Design

 |

Backend

 |

API

 |

Frontend

 |

Testing

 |

Deployment
```


---

# 6. Git Workflow


Branches:


```
main

development

feature/*
```


Commit style:


```
feat:
fix:
docs:
refactor:
```


---

# 13 - Testing Guide


# 1. Testing Goals


Ensure:


- Stable playback
- Reliable API
- Correct queue behavior
- UI consistency


---

# 2. Backend Tests


Test:


```
API routes

Services

Database

Queue logic
```


---

# 3. Player Tests


Verify:


```
mpv starts

IPC works

Commands execute

Events arrive
```


---

# 4. Frontend Tests


Check:


```
Buttons

Search

Queue

Player controls

Responsive layout
```


---

# 5. Integration Testing


Complete workflow:


```
Search song

 |

Add queue

 |

Play

 |

Pause

 |

Next

 |

Update UI
```


---

# 6. Hardware Testing


Test:


- HDMI audio
- USB DAC
- Bluetooth
- Network reliability


---

# 7. Performance Testing


Targets:


RAM:


```
<200MB
```


CPU:


```
Low usage
```


Boot:


```
<60 seconds
```


---

# 14 - Development Roadmap


# Phase 1 - Core Player


Features:


- mpv integration
- Browser UI
- Search
- Queue
- Playback controls


Status:


```
MVP
```


---

# Phase 2 - Music Library


Add:


- History
- Favorites
- Playlists
- Local music


---

# Phase 3 - UI Enhancement


Add:


- Better animations
- Album artwork
- Themes
- Mobile optimization


---

# Phase 4 - Advanced Features


Add:


- Lyrics
- Equalizer
- Radio
- Multi-user support


---

# Phase 5 - Smart Features


Future:


- Recommendations
- Voice control
- AI playlist generation


---

# Final Project Vision


PiPlayer evolves into a complete self-hosted music ecosystem.


The final system should provide:


```
Spotify-like experience

+

Raspberry Pi ownership

+

Local control

+

Privacy

+

Low power usage
```


Architecture remains:


```
Browser

   |

FastAPI

   |

Services

   |

mpv

   |

Audio Hardware
```


The Raspberry Pi becomes a dedicated personal music server controlled entirely from a beautiful web interface.