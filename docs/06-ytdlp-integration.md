# PiPlayer - yt-dlp Integration Architecture

## Document Information

Project:

```
PiPlayer
```

Document:

```
06-ytdlp-integration.md
```

Purpose:

Define how PiPlayer uses yt-dlp for searching, extracting metadata, resolving playable media URLs, and integrating online music sources with the playback system.

---

# 1. Overview

yt-dlp is the media discovery and extraction engine used by PiPlayer.

It provides the connection between:

- User search requests
- Online music sources
- mpv playback


Architecture:

```
Browser

   |

FastAPI Backend

   |

YouTube Service

   |

yt-dlp

   |

Online Source

   |

Playable Audio URL

   |

mpv
```

---

# 2. Why yt-dlp?

yt-dlp is used because it provides:

- YouTube search
- Metadata extraction
- Stream URL extraction
- Playlist support
- Wide website compatibility
- Active development


PiPlayer does not download videos by default.

It resolves playable streams and passes them to mpv.

---

# 3. yt-dlp Responsibilities

yt-dlp handles:


## Search

Example:

```
Daft Punk Get Lucky
```


Returns:

- Title
- Artist
- Thumbnail
- Duration
- Video ID
- URL


---

## Metadata Extraction


Information:

```
Title

Uploader

Channel

Duration

Thumbnail

Description

Upload date
```


---

## Stream Resolution


Converts:


```
YouTube URL

        |

Playable audio stream URL
```


---

# 4. Backend Responsibility


The backend manages:

- Search requests
- Result formatting
- Caching
- Error handling
- Sending URLs to mpv


yt-dlp should never be called directly from frontend.

---

# 5. Python Integration


Package:


```
yt-dlp
```


Installation:


```bash
pip install yt-dlp
```


---

# 6. Service Structure


File:


```
services/youtube_service.py
```


Responsibilities:


```
search()

extract()

resolve()

get_metadata()
```


---

# 7. Search Flow


Complete process:


```
User

 |

Types:

"Coldplay Yellow"

 |

Browser

 |

GET /api/search

 |

FastAPI

 |

YouTube Service

 |

yt-dlp

 |

Search Results

 |

Backend Formats Data

 |

Browser Displays Results
```

---

# 8. Search Command


Example:


```bash
yt-dlp "ytsearch10:coldplay yellow"
```


Meaning:


```
ytsearch10

Return first 10 results
```


---

# 9. Search Result Format


Backend should convert yt-dlp output into:


```json
[
 {
   "id":"abc123",

   "title":"Yellow",

   "artist":"Coldplay",

   "thumbnail":"image_url",

   "duration":266,

   "url":"youtube_url"
 }
]
```


---

# 10. Result Cleaning


Raw yt-dlp data may contain:

- Missing thumbnails
- Missing artist names
- Long titles


Backend should normalize:


Example:


Before:


```
Coldplay - Yellow (Official Video) [HD]
```


After:


```
Title:
Yellow


Artist:
Coldplay
```


---

# 11. URL Resolution


When user presses play:


Flow:


```
Song ID

 |

Backend

 |

yt-dlp extract

 |

Audio URL

 |

mpv loadfile

```


---

# 12. Extract Command


Example:


```bash
yt-dlp -f bestaudio URL
```


Purpose:


Get best available audio stream.


---

# 13. Audio Selection


Priority:


1. Best audio quality
2. Lowest latency
3. Compatible format


Preferred formats:


```
opus

aac

mp3
```


---

# 14. Metadata Model


Song object:


```
Song

|

├── id

├── title

├── artist

├── url

├── thumbnail

├── duration

├── source

└── created_at
```


---

# 15. Caching Strategy


yt-dlp operations can be slow.

Cache:


## Search Cache


Example:


```
Query:

"lofi"


Results:

stored for 10 minutes
```


---

## Metadata Cache


Store:


- Title
- Thumbnail
- Duration


Avoid repeated extraction.


---

# 16. Queue Integration


The queue should store resolved songs.


Example:


User adds:


```
Song A
```


Backend:


```
Search Result

      |

Queue Item

      |

Playback
```


---

# 17. Playback Integration


Final flow:


```
yt-dlp

 |

Audio URL

 |

Queue Manager

 |

Player Service

 |

mpv

 |

Speaker
```


---

# 18. Error Handling


## Video Removed


Example:


```
Video unavailable
```


Action:


```
Return error

Remove item

Continue queue
```


---

## Network Failure


Example:


```
Connection timeout
```


Action:


```
Retry

Show message
```


---

## Rate Limiting


Possible issue:


Too many requests.


Solution:


- Cache searches
- Limit requests
- Add delay if needed


---

# 19. Background Processing


Long yt-dlp operations should not block the server.


Example:


Bad:


```
Search request

 |

Wait 20 seconds

 |

Return
```


Good:


```
Search request

 |

Background task

 |

Return updates
```


---

# 20. Playlist Support


Future feature.


yt-dlp can handle:


- YouTube playlists
- Albums
- Mixes


Flow:


```
Playlist URL

 |

yt-dlp

 |

Multiple songs

 |

PiPlayer Queue
```


---

# 21. Security Considerations


Never execute user input directly.


Bad:


```python
os.system(user_input)
```


Good:


Use yt-dlp Python API.


---

# 22. Rate Control


Recommended:


Maximum:

```
5 searches / second
```


Prevent abuse.


---

# 23. Storage


yt-dlp cache location:


Example:


```
~/.cache/yt-dlp/
```


Should be monitored because SD cards have limited storage.


---

# 24. Offline Behavior


If internet unavailable:


The system should still:

- Show local playlists
- Show history
- Play cached/local files


Online search will display:

```
No connection
```


---

# 25. Performance Goals


Search:

```
<3 seconds
```


Metadata extraction:

```
<5 seconds
```


Memory:

```
Temporary only
```


yt-dlp should not stay running permanently.

---

# 26. Recommended Configuration


Example:


```
quiet=true

no_warnings=true

extract_flat=true
```


---

# 27. Future Extensions


Possible:


- Spotify URL support
- SoundCloud support
- Internet radio
- Local music scanning
- Podcast support


---

# 28. Complete yt-dlp Architecture


```
                 Browser

                    |

                FastAPI

                    |

            YouTube Service

                    |

                  yt-dlp

                    |

             Online Sources

                    |

              Audio Stream

                    |

                   mpv

                    |

                Speakers
```


---

# 29. Final Objective


yt-dlp should provide PiPlayer with a reliable bridge between online music discovery and local Raspberry Pi playback.

The user should experience a seamless search-and-play workflow without knowing that yt-dlp exists internally.