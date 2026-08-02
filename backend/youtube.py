import yt_dlp
from typing import List, Dict, Optional
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def search_songs(query: str, limit: int = 12) -> List[Dict]:
    ydl_opts = {
        "format": "bestaudio/best",
        "quiet": True,
        "extract_flat": True,
        "dump_single_json": True,
        "nocheckcertificate": True,
    }

    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        try:
            results = ydl.extract_info(f"ytsearch{limit}:{query}", download=False)
            entries = results.get("entries", [])
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
