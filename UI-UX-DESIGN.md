# PiPlayer UI/UX Design Specification

## Overview

PiPlayer is a modern music application interface inspired by popular music streaming platforms.

The goal is to provide a familiar, high-quality music experience while maintaining an original visual identity.

The design focuses on:

- Fast navigation
- Minimal clicks
- Large visual hierarchy
- Smooth playback control
- Desktop and mobile usability

---

# Design Identity

## Brand

Name:

PiPlayer

Personality:

- Modern
- Clean
- Fast
- Minimal
- Premium
- Technical but friendly


---

# Theme

## Main Style

Dark blue music application.

The interface should feel:

- Immersive
- Comfortable for long listening sessions
- Easy on the eyes


---

# Color System

## Background

Main:

```
#07111F
```

Used for:

- Main application background
- Player area


---

## Sidebar

```
#0B1628
```

Used for:

- Navigation panel
- Library section


---

## Cards

```
#13243A
```

Used for:

- Albums
- Songs
- Playlists
- Search results


---

## Primary Accent

```
#2563EB
```

Used for:

- Buttons
- Active states
- Progress bars


---

## Secondary Accent

```
#60A5FA
```

Used for:

- Hover effects
- Highlights


---

## Text

Primary:

```
#F8FAFC
```


Secondary:

```
#94A3B8
```


Disabled:

```
#64748B
```

---

# Application Layout

Desktop layout:

```
+-------------------------------------------------------+
| Sidebar          | Main Content                        |
|                  |                                     |
| Logo             | Search                              |
|                  |                                     |
| Home             | Featured Content                    |
| Search           |                                     |
| Library          | Albums                              |
|                  | Songs                               |
| Playlists        |                                     |
|                  |                                     |
+-------------------------------------------------------+
|                Bottom Player Bar                      |
+-------------------------------------------------------+
```


---

# Sidebar

Width:

```
260px
```


Fixed position.

Contains:


## Logo

Top area.

Example:

```
🎵 PiPlayer
```


Size:

24px


---

# Navigation

Items:

```
Home

Search

Library
```


Each item contains:

- Icon
- Text
- Active state


Example:


Inactive:

```
○ Home
```


Active:

```
🔵 Home
```


---

# Library Section


Contains:

```
Recently Played

Favorites

Playlists

Local Music
```


---

# Main Content Area

Scrollable.

Padding:

```
32px
```


---

# Search Interface


Location:

Top center.


Design:

Large rounded search bar.


Example:

```
+--------------------------------------+
| 🔍 Search songs, artists, albums     |
+--------------------------------------+
```


Properties:

Height:

```
48px
```


Border radius:

```
24px
```


---

# Home Screen


Sections:


## Recently Played

Horizontal cards.


Example:

```
+-------+ +-------+ +-------+
| Image | | Image | | Image |
| Song  | | Song  | | Song  |
+-------+ +-------+ +-------+
```


---

## Recommended

Large cards.


Card:

Width:

200px


Height:

280px


Contains:

- Image
- Title
- Artist
- Hover play button


---

# Search Results


Layout:

Vertical list.


Example:

```
------------------------------------------------
Image | Song Name
      | Artist
      | Duration
------------------------------------------------
```


Each result:

Height:

72px


Hover:

Background becomes:

```
#1E3352
```


Actions:

```
▶ Play

＋ Queue

♥ Favorite
```


---

# Album / Playlist View


Header:


Large image:

```
300x300
```


Information:

```
Playlist Name

Created by

Number of songs
```


Buttons:


Primary:

```
▶ Play
```


Secondary:

```
＋ Add Queue
```


---

# Song Cards


Component:


```
+----------------+
|                |
|    Artwork     |
|                |
+----------------+

Song Name

Artist
```


Hover:

Show:

```
▶
```


---

# Bottom Player


Always visible.


Height:

```
90px
```


Position:

Fixed bottom.


Layout:


```
+------------------------------------------------+
| Song Info | Controls              | Volume     |
+------------------------------------------------+
```


---

# Current Song Section


Left side.


Contains:


Artwork:

```
56x56
```


Text:

```
Song Title

Artist
```


---

# Playback Controls


Center.


Buttons:


```
Previous

Play/Pause

Next

Shuffle

Repeat
```


Main button:

Circle.

Size:

56px.


---

# Progress Bar


Full width center section.


Example:

```
00:42  ========●--------- 03:20
```


Properties:

Height:

```
4px
```


Hover:

```
8px
```


---

# Volume Control


Right side.


Contains:

```
🔊 =======●====
```


Range:

0-100


---

# Queue Panel


Right drawer.


Width:

```
350px
```


Contains:

```
Queue

Current Song

Next Songs
```


Actions:

- Remove
- Move
- Play next


---

# Animations


All transitions:

```
150-250ms
```


Examples:


Button hover:

Scale:

```
1.05
```


Cards:

Lift:

```
translateY(-4px)
```


---

# Responsive Design


## Desktop

Width:

>1200px


Full sidebar.


---

## Tablet


800-1200px


Sidebar collapses.


---

## Mobile


<800px


Layout:

Bottom navigation.


Sidebar hidden.


Player becomes:

compact bottom sheet.


---

# Icons

Use:

Lucide Icons


Style:

Outline


Size:

20-24px


---

# Typography


Font:

Inter


Weights:


Normal:

400


Medium:

500


Bold:

700


---

# Accessibility


Required:

- Keyboard navigation
- Visible focus states
- Screen reader labels
- Proper contrast
- Large touch targets


---

# User Flow


## Play Song

1. User searches.
2. Results appear.
3. User clicks play.
4. Song loads.
5. Player updates.
6. Audio starts on Raspberry Pi.


---

## Add To Queue

1. User clicks queue button.
2. Song added.
3. Queue updates instantly.
4. All connected browsers receive update.


---

# Component List


Frontend components:


```
App

├── Sidebar

├── Header

├── SearchBar

├── Home

├── SearchResults

├── SongCard

├── PlaylistCard

├── QueuePanel

├── PlayerBar

└── VolumeControl
```


---

# Design Goal

The final UI should feel like a premium music application:

- Fast
- Smooth
- Beautiful
- Familiar
- Original

while being lightweight enough to run alongside the PiPlayer backend on a Raspberry Pi 3B+.