# PiPlayer - Frontend Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
04-frontend.md
```

Purpose:

Define the frontend architecture, user interface structure, components, communication methods, styling system, and browser-side behavior.

---

# 1. Frontend Overview

The PiPlayer frontend is the user-facing application.

It provides a modern music player interface that runs inside a web browser.

The frontend is responsible for:

- Displaying the music interface
- Receiving user input
- Sending commands to the backend
- Displaying playback state
- Updating the UI in real time


The frontend does NOT:

- Play audio
- Search YouTube directly
- Communicate with mpv
- Access hardware


All important operations are handled by the backend.

---

# 2. Frontend Goals

The interface should feel like a premium music application.

Main goals:

- Fast loading
- Smooth animations
- Simple navigation
- Responsive design
- Low resource usage
- Works on desktop and mobile


The frontend must run smoothly even on low-powered devices accessing the Pi.

---

# 3. Frontend Technology


## Core Technologies


HTML5

Purpose:

Application structure.


---

CSS3

Purpose:

Styling and animations.


---

JavaScript

Purpose:

Client-side interaction.


---

HTMX

Purpose:

Server communication without heavy frameworks.


---

Alpine.js

Purpose:

Lightweight UI state management.


---

Tailwind CSS

Purpose:

Consistent styling system.


---

# 4. Why Not React?


React is intentionally avoided.


Reasons:


## Memory Usage

A React application requires:

- Build tools
- Node runtime during development
- Larger JavaScript bundles


---

## Simplicity

PiPlayer does not require a complex client-side application.

Most operations are server-driven.


---

## Raspberry Pi Optimization

The goal is keeping the system lightweight.


---

# 5. Frontend Directory Structure


```
frontend/

├── templates/

│   ├── base.html

│   ├── index.html

│   ├── search.html

│   ├── queue.html

│   ├── playlist.html

│   └── settings.html


├── static/

│
├── css/

│   ├── main.css

│   ├── theme.css

│   └── components.css


├── js/

│   ├── app.js

│   ├── player.js

│   ├── websocket.js

│   └── queue.js


├── icons/

└── images/
```

---

# 6. Application Layout


The main layout contains:


```
+------------------------------------------------+
| Sidebar                                        |
|                                                |
| Home                                           |
| Search                                         |
| Library                                        |
| Playlists                                      |
|                                                |
+----------------------+-------------------------+
                       |
                       |
                 Main Content
                       |
                       |
+------------------------------------------------+
|               Bottom Player                    |
+------------------------------------------------+
```


---

# 7. Main Components


Frontend components:


```
Application

├── Sidebar

├── Header

├── SearchBar

├── HomeView

├── SearchResults

├── SongCard

├── AlbumCard

├── QueuePanel

├── PlayerBar

├── VolumeControl

└── NotificationSystem
```


---

# 8. Sidebar Component


Purpose:

Main navigation.


Contains:


```
PiPlayer Logo


Home

Search

Library

Favorites

History

Playlists


Settings
```


---

States:


Normal:

```
Dark background
White text
```


Active:

```
Blue highlight
Blue icon
```


---

# 9. Header Component


Contains:


## Search


Large search input.


Example:


```
-----------------------------------
| 🔍 Search songs, artists        |
-----------------------------------
```


---

## User Controls


Future:


- Profile
- Settings
- Device selection


---

# 10. Home Page


Purpose:

Music discovery.


Sections:


## Recently Played


Displays previously played songs.


---

## Favorites


Displays liked songs.


---

## Playlists


Displays user playlists.


---

## Recommendations


Future feature.


---

# 11. Search Page


Flow:


```
User enters query

        |

Frontend sends request

        |

Backend searches

        |

Results displayed
```


---

Search result card:


```
+--------------------------------+
| Image                          |
|                                |
| Song Title                     |
| Artist                         |
|                                |
| ▶ Play     + Queue     ♥       |
+--------------------------------+
```


---

# 12. Player Bar


The player bar is always visible.


Position:


```
fixed bottom
```


Height:


```
90px
```


---

Contains:


## Song Information


Left side.


```
Artwork

Title

Artist
```


---

## Controls


Center.


```
Previous

Play/Pause

Next

Shuffle

Repeat
```


---

## Volume


Right side.


```
🔊 --------●----
```


---

# 13. Queue Panel


Purpose:

Show upcoming songs.


Contains:


```
Current Queue

Playing Next

Remove Buttons

Reorder Controls
```


---

# 14. State Management


Frontend state:


```
Current Song

Playback Status

Volume

Progress

Queue

Connection Status
```


---

State source:


The backend is the source of truth.


Example:


```
Backend

     |

WebSocket

     |

Frontend State

     |

UI Update
```


---

# 15. API Communication


Frontend communicates through:


## REST API


Used for commands:


Examples:


```
GET /api/search


POST /api/player/play


POST /api/player/pause


POST /api/queue/add
```


---

## WebSocket


Used for live changes.


Connection:


```
ws://192.168.18.159/ws
```


---

# 16. WebSocket Events


Frontend listens for:


## Song Changed


Example:


```json
{
"type":"song_changed",
"title":"Song Name"
}
```


Update:

- Artwork
- Title
- Artist


---

## Playback Update


Example:


```json
{
"type":"position",
"value":120
}
```


Update:

Progress bar.


---

## Queue Update


Update:

Queue display.


---

# 17. CSS Design System


## Spacing


Base unit:


```
4px
```


Examples:


```
small:

8px


medium:

16px


large:

32px
```


---

# 18. Component Styling


All components should have:


- Rounded corners
- Smooth transitions
- Consistent spacing


---

Card:


```
background:
#13243A


border-radius:
12px
```


---

Button:


```
height:
40px


border-radius:
20px
```


---

# 19. Animation Rules


Animations should be subtle.


Duration:


```
150-250ms
```


Examples:


Hover:

```
scale(1.05)
```


Card:


```
translateY(-4px)
```


---

# 20. Responsive Design


## Desktop


Width:

```
1200px+
```


Layout:

Full sidebar.


---

## Tablet


Width:

```
768px-1200px
```


Changes:

- Smaller sidebar
- Reduced spacing


---

## Mobile


Width:

```
<768px
```


Changes:


Sidebar:

Hidden.


Navigation:

Bottom navigation.


Player:

Compact mode.


---

# 21. Browser Support


Target:


Modern browsers:


- Chrome
- Firefox
- Safari
- Edge


---

# 22. Accessibility


Requirements:


- Keyboard navigation
- ARIA labels
- High contrast
- Visible focus states


---

# 23. Error States


Examples:


## Backend Offline


Display:


```
Connection lost

Retrying...
```


---

## Search Failed


Display:


```
No results found
```


---

## Playback Error


Display:


```
Unable to play song
```


---

# 24. Loading States


Use skeleton loaders.


Example:


Before:


```
[########]
```


After:


```
Song Title
Artist
```


---

# 25. Frontend Performance Rules


Avoid:


- Large libraries
- Heavy animations
- Large images
- Unnecessary requests


Optimize:


- Lazy loading
- Cached assets
- Minimal JavaScript


---

# 26. Final Frontend Architecture


```
                  Browser


                    |

              HTML Templates


                    |

             JavaScript Layer


          ---------------------

          |                   |

       REST API          WebSocket


          |                   |


              FastAPI Backend

```


The frontend provides a premium music experience while remaining lightweight enough for a Raspberry Pi-powered application.