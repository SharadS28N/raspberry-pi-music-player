import yt_dlp
from typing import List, Dict, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


import time

_search_cache: Dict[str, Dict] = {}
CACHE_TTL = 600  # 10 minutes cache TTL


def search_songs(query: str, limit: int = 12) -> List[Dict]:
    global _search_cache
    query_key = f"{query.lower().strip()}_{limit}"
    now = time.time()

    if query_key in _search_cache:
        cached_entry = _search_cache[query_key]
        if now - cached_entry["time"] < CACHE_TTL:
            return cached_entry["data"]

    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "extract_flat": "in_playlist",
        "skip_download": True,
        "nocheckcertificate": True,
        "youtube_include_dash_manifest": False,
        "youtube_include_hls_manifest": False,
        "ignoreerrors": True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            results = ydl.extract_info(f"ytsearch{limit}:{query}", download=False)
            entries = results.get("entries", []) if results else []
            songs = []

            for entry in entries:
                if entry:
                    video_id = entry.get("id")
                    title = entry.get("title") or "Unknown Title"
                    artist = entry.get("channel") or entry.get("uploader") or "YouTube"
                    url = entry.get("url")
                    if video_id and (not url or not url.startswith("http")):
                        url = f"https://www.youtube.com/watch?v={video_id}"

                    thumbnail = entry.get("thumbnail")
                    if not thumbnail and video_id:
                        thumbnail = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

                    songs.append({
                        "id": video_id,
                        "title": title,
                        "artist": artist,
                        "url": url,
                        "thumbnail": thumbnail,
                        "duration": entry.get("duration") or 0,
                    })

            _search_cache[query_key] = {"time": now, "data": songs}
            return songs
        except Exception as e:
            logger.error(f"Error searching YouTube: {e}")
            return []



def get_audio_url(youtube_url: str) -> str:
    # Extract direct audio stream URL (.googlevideo.com) for MPV native playback
    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "extract_flat": False,
        "nocheckcertificate": True,
        "noplaylist": True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            info = ydl.extract_info(youtube_url, download=False)
            if not info:
                return youtube_url

            formats = info.get("formats", [])
            audio_formats = [f for f in formats if f.get("acodec") != "none" and f.get("vcodec") == "none"]
            if audio_formats:
                stream_url = audio_formats[-1].get("url")
                if stream_url:
                    return stream_url

            return info.get("url") or youtube_url
        except Exception as e:
            logger.error(f"Error extracting direct audio URL: {e}")
            return youtube_url


def get_related_songs(title: str, artist: Optional[str] = "", limit: int = 5) -> List[Dict]:
    """Fetch related/recommended songs based on current track for YouTube-style autoplay"""
    clean_title = title.replace("Official Video", "").replace("MV", "").strip()
    query = f"{clean_title} {artist or ''} mix recommendations".strip()
    results = search_songs(query, limit=limit+3)
    # Filter out exact current song title if returned
    filtered = [s for s in results if s["title"].lower() != title.lower()][:limit]
    return filtered if filtered else results[:limit]

