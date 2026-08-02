from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from pydantic import BaseModel
from typing import List, Optional
import os
import sys
import time
import asyncio
import re
import json
import urllib.request
import urllib.parse

sys.path.insert(0, os.path.dirname(__file__))

from config import BASE_DIR
import database
import youtube
import queue_service as queue_module
from player import player
from bluetooth_service import bluetooth_service
from audio_service import audio_service
from websocket import manager, broadcast_state_update

app = FastAPI(title="PiPlayer")

# Initialize database
database.init_database()

# Mount static files
static_dir = os.path.join(os.path.dirname(BASE_DIR), "frontend")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")


# Pydantic models
class PlayRequest(BaseModel):
    url: str
    title: Optional[str] = None
    artist: Optional[str] = None
    thumbnail: Optional[str] = None
    duration: Optional[int] = None


class VolumeRequest(BaseModel):
    volume: int


class SeekRequest(BaseModel):
    position: float


class BluetoothPowerRequest(BaseModel):
    power: bool


class BluetoothModeRequest(BaseModel):
    mode: str


class BluetoothDeviceRequest(BaseModel):
    mac: str


class AudioOutputRequest(BaseModel):
    output: str


class EqualizerRequest(BaseModel):
    preset: str


class SleepTimerRequest(BaseModel):
    minutes: int


class CreatePlaylistRequest(BaseModel):
    name: str


class PlaylistSongRequest(BaseModel):
    song_id: Optional[int] = None
    url: Optional[str] = None
    title: Optional[str] = None
    artist: Optional[str] = None
    thumbnail: Optional[str] = None
    duration: Optional[int] = None


# Current song & Sleep Timer state
current_song: Optional[dict] = None
sleep_timer_end_time: Optional[float] = None
sleep_timer_task = None


@app.get("/")
async def read_root():
    index_path = os.path.join(os.path.dirname(BASE_DIR), "frontend", "index.html")
    if os.path.exists(index_path):
        return FileResponse(index_path)
    return HTMLResponse("<h1>PiPlayer</h1>")


@app.get("/api/search")
async def search(q: str, limit: int = 12):
    results = youtube.search_songs(q, limit)
    return results


current_play_request_id = 0


@app.post("/api/play")
async def play(request: PlayRequest):
    global current_song, current_play_request_id
    current_play_request_id += 1
    this_request_id = current_play_request_id

    video_url = request.url
    
    # Try resolving audio stream url or pass video_url for mpv native ytdl resolution
    audio_url = await asyncio.to_thread(youtube.get_audio_url, video_url)
    target_play_url = audio_url if (audio_url and audio_url.startswith("http")) else video_url

    # Cancel stale out-of-order request if user clicked another song quickly
    if this_request_id != current_play_request_id:
        return {"status": "cancelled_stale_request"}

    duration = request.duration or 0
    player.play(target_play_url, duration=duration)

    video_id = ""
    if "v=" in video_url:
        video_id = video_url.split("v=")[1].split("&")[0]
    elif request.url:
        video_id = request.url.split("/")[-1]

    thumbnail = request.thumbnail
    if not thumbnail and video_id:
        thumbnail = f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

    current_song = {
        "title": request.title or "Unknown Song",
        "artist": request.artist or "YouTube",
        "url": video_url,
        "thumbnail": thumbnail,
        "duration": duration,
        "id": video_id
    }

    try:
        database.add_to_history(
            title=current_song["title"],
            artist=current_song["artist"],
            url=current_song["url"],
            thumbnail=current_song["thumbnail"],
            duration=current_song["duration"]
        )
    except Exception as e:
        print(f"Error logging to database history: {e}")

    await broadcast_state_update("song_changed", current_song)
    await broadcast_state_update("player_state_changed", player.get_status())
    return {"status": "ok", "current_song": current_song}


@app.post("/api/pause")
async def pause():
    res = player.pause()
    await broadcast_state_update("player_state_changed", player.get_status())
    return res


@app.post("/api/resume")
async def resume():
    res = player.resume()
    await broadcast_state_update("player_state_changed", player.get_status())
    return res


@app.post("/api/toggle")
async def toggle():
    res = player.toggle_pause()
    await broadcast_state_update("player_state_changed", player.get_status())
    return res


@app.post("/api/stop")
async def stop():
    res = player.stop()
    await broadcast_state_update("player_state_changed", player.get_status())
    return res


@app.post("/api/seek")
async def seek(request: SeekRequest):
    res = player.seek(request.position)
    await broadcast_state_update("player_state_changed", player.get_status())
    return res


@app.post("/api/volume")
async def set_volume(request: VolumeRequest):
    res = player.set_volume(request.volume)
    await broadcast_state_update("volume_changed", {"volume": request.volume})
    return res


@app.get("/api/status")
async def status():
    return {
        "player": player.get_status(),
        "current_song": current_song,
        "queue": queue_module.get_queue(),
        "audio": audio_service.get_output_devices(),
        "master_volume": audio_service.get_master_volume(),
        "sleep_timer_remaining": round(sleep_timer_end_time - time.time()) if sleep_timer_end_time and sleep_timer_end_time > time.time() else 0
    }


# Equalizer endpoint
@app.post("/api/equalizer")
async def set_equalizer(req: EqualizerRequest):
    preset = player.set_equalizer(req.preset)
    await broadcast_state_update("player_state_changed", player.get_status())
    return {"status": "ok", "equalizer": preset}


# Sleep Timer Endpoint
@app.post("/api/sleep-timer")
async def set_sleep_timer(req: SleepTimerRequest):
    global sleep_timer_end_time, sleep_timer_task

    if req.minutes <= 0:
        sleep_timer_end_time = None
        return {"status": "ok", "sleep_timer": 0}

    sleep_timer_end_time = time.time() + (req.minutes * 60)

    async def run_sleep_timer():
        global sleep_timer_end_time
        await asyncio.sleep(req.minutes * 60)
        if sleep_timer_end_time and time.time() >= sleep_timer_end_time:
            # Smooth fade-out in last 5 seconds
            vol = player.get_volume()
            for v in range(vol, -1, -10):
                player.set_volume(max(0, v))
                await asyncio.sleep(0.5)
            player.pause()
            sleep_timer_end_time = None
            await broadcast_state_update("player_state_changed", player.get_status())

    if sleep_timer_task and not sleep_timer_task.done():
        sleep_timer_task.cancel()

    sleep_timer_task = asyncio.create_task(run_sleep_timer())
    return {"status": "ok", "sleep_timer": req.minutes}


# --- Queue Management Endpoints ---

@app.get("/api/queue")
async def get_queue():
    return queue_module.get_queue()


@app.post("/api/queue/add")
async def add_to_queue(song: PlayRequest):
    song_dict = {
        "title": song.title or "Unknown Song",
        "artist": song.artist or "YouTube",
        "url": song.url,
        "thumbnail": song.thumbnail,
        "duration": song.duration
    }
    item = queue_module.add_to_queue(song_dict)
    await broadcast_state_update("queue_updated", queue_module.get_queue())
    return item


@app.delete("/api/queue/{queue_id}")
async def remove_from_queue(queue_id: str):
    success = queue_module.remove_from_queue(queue_id)
    if success:
        await broadcast_state_update("queue_updated", queue_module.get_queue())
        return {"status": "ok"}
    raise HTTPException(status_code=404, detail="Item not found in queue")


@app.post("/api/queue/clear")
async def clear_queue():
    queue_module.clear_queue()
    await broadcast_state_update("queue_updated", queue_module.get_queue())
    return {"status": "ok"}


@app.get("/api/history")
async def get_history(limit: int = 20):
    return database.get_history(limit)


@app.get("/api/favorites")
async def get_favorites():
    return database.get_favorites()


@app.post("/api/favorites/toggle")
async def toggle_favorite(song_id: int):
    is_fav = database.toggle_favorite(song_id)
    return {"is_favorite": is_fav}


@app.get("/api/favorites/{song_id}")
async def check_favorite(song_id: int):
    return {"is_favorite": database.is_favorite(song_id)}


# --- Bluetooth & Audio Management Endpoints ---

@app.get("/api/bluetooth/status")
async def get_bluetooth_status():
    return bluetooth_service.get_status()


@app.post("/api/bluetooth/power")
async def set_bluetooth_power(req: BluetoothPowerRequest):
    success = bluetooth_service.set_power(req.power)
    status = bluetooth_service.get_status()
    await broadcast_state_update("bluetooth_status_changed", status)
    return {"status": "ok", "powered": status["powered"], "success": success}


@app.post("/api/bluetooth/mode")
async def set_bluetooth_mode(req: BluetoothModeRequest):
    try:
        new_mode = bluetooth_service.set_mode(req.mode)
        status = bluetooth_service.get_status()
        await broadcast_state_update("bluetooth_status_changed", status)
        return {"status": "ok", "mode": new_mode}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/bluetooth/devices")
async def scan_bluetooth_devices():
    devices = bluetooth_service.scan_devices()
    return devices


@app.post("/api/bluetooth/connect")
async def connect_bluetooth(req: BluetoothDeviceRequest):
    res = bluetooth_service.connect_device(req.mac)
    status = bluetooth_service.get_status()
    await broadcast_state_update("bluetooth_status_changed", status)
    return res


@app.post("/api/bluetooth/disconnect")
async def disconnect_bluetooth(req: BluetoothDeviceRequest):
    res = bluetooth_service.disconnect_device(req.mac)
    status = bluetooth_service.get_status()
    await broadcast_state_update("bluetooth_status_changed", status)
    return res


@app.get("/api/lyrics")
async def get_lyrics(title: str, artist: Optional[str] = ""):
    """Fetch synchronized (LRC) or plain lyrics from LRCLIB API"""
    clean_title = re.sub(r"[\(\[\{].*?[\)\]\}]", "", title).strip()
    clean_artist = re.sub(r"[\(\[\{].*?[\)\]\}]", "", artist or "").strip()
    
    query = f"{clean_title} {clean_artist}".strip()
    encoded_query = urllib.parse.quote(query)
    
    headers = {"User-Agent": "PiPlayer/2.0 (Raspberry Pi Open Source Music Player)"}
    search_url = f"https://lrclib.net/api/search?q={encoded_query}"
    
    try:
        req = urllib.request.Request(search_url, headers=headers)
        with urllib.request.urlopen(req, timeout=5) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode())
                if data and isinstance(data, list) and len(data) > 0:
                    match = data[0]
                    return {
                        "status": "success",
                        "synced_lyrics": match.get("syncedLyrics"),
                        "plain_lyrics": match.get("plainLyrics"),
                        "track": match.get("trackName", title),
                        "artist": match.get("artistName", artist),
                        "instrumental": match.get("instrumental", False)
                    }
    except Exception as e:
        print(f"Lyrics lookup exception: {e}")

    return {
        "status": "not_found",
        "synced_lyrics": None,
        "plain_lyrics": None,
        "track": title,
        "artist": artist,
        "message": "Synchronized lyrics not available for this track"
    }


@app.get("/api/audio/outputs")
async def get_audio_outputs():
    return audio_service.get_output_devices()


@app.post("/api/audio/output")
async def set_audio_output(req: AudioOutputRequest):
    res = audio_service.set_output_device(req.output)
    outputs = audio_service.get_output_devices()
    await broadcast_state_update("audio_outputs_changed", outputs)
    return res


# Playlist API Endpoints
@app.get("/api/playlists")
async def list_playlists():
    return database.get_playlists()


@app.post("/api/playlists")
async def create_playlist(req: CreatePlaylistRequest):
    if not req.name.strip():
        raise HTTPException(status_code=400, detail="Playlist name cannot be empty")
    return database.create_playlist(req.name.strip())


@app.get("/api/playlists/{playlist_id}")
async def get_playlist(playlist_id: int):
    playlist = database.get_playlist_by_id(playlist_id)
    if not playlist:
        raise HTTPException(status_code=404, detail="Playlist not found")
    songs = database.get_playlist_songs(playlist_id)
    return {**playlist, "songs": songs}


@app.delete("/api/playlists/{playlist_id}")
async def delete_playlist(playlist_id: int):
    database.delete_playlist(playlist_id)
    return {"status": "ok"}


@app.post("/api/playlists/{playlist_id}/songs")
async def add_song_to_playlist(playlist_id: int, req: PlaylistSongRequest):
    song_id = req.song_id
    if not song_id and req.url:
        song = database.get_or_create_song(
            title=req.title or "Unknown Title",
            artist=req.artist or "YouTube",
            url=req.url,
            thumbnail=req.thumbnail,
            duration=req.duration
        )
        song_id = song["id"]
    if not song_id:
        raise HTTPException(status_code=400, detail="Song ID or URL required")
    database.add_song_to_playlist(playlist_id, song_id)
    return {"status": "ok"}


@app.delete("/api/playlists/{playlist_id}/songs/{song_id}")
async def remove_song_from_playlist(playlist_id: int, song_id: int):
    database.remove_song_from_playlist(playlist_id, song_id)
    return {"status": "ok"}


@app.post("/api/playlists/{playlist_id}/play")
async def play_playlist(playlist_id: int):
    songs = database.get_playlist_songs(playlist_id)
    if not songs:
        raise HTTPException(status_code=400, detail="Playlist is empty")
    queue_module.clear_queue()
    for s in songs[1:]:
        queue_module.add_to_queue(s)
    first_song = songs[0]
    return await play(PlayRequest(
        url=first_song["url"],
        title=first_song.get("title"),
        artist=first_song.get("artist"),
        thumbnail=first_song.get("thumbnail"),
        duration=first_song.get("duration")
    ))


@app.get("/api/audio/master-volume")
async def get_master_volume():
    return {"volume": audio_service.get_master_volume()}


@app.post("/api/audio/master-volume")
async def set_master_volume(req: VolumeRequest):
    vol = audio_service.set_master_volume(req.volume)
    await broadcast_state_update("master_volume_changed", {"volume": vol})
    return {"volume": vol}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    poll_task = None
    try:
        await websocket.send_json({
            "type": "init",
            "data": {
                "player_state": player.get_status(),
                "current_song": current_song,
                "queue": queue_module.get_queue(),
                "bluetooth_status": bluetooth_service.get_status(),
                "audio_outputs": audio_service.get_output_devices(),
                "master_volume": audio_service.get_master_volume()
            }
        })

        async def poll_state():
            try:
                while True:
                    await asyncio.sleep(1)
                    status = player.get_status()
                    await websocket.send_json({
                        "type": "player_state_changed",
                        "data": status
                    })
            except (WebSocketDisconnect, RuntimeError, Exception):
                pass

        poll_task = asyncio.create_task(poll_state())

        while True:
            data = await websocket.receive_json()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    finally:
        if poll_task and not poll_task.done():
            poll_task.cancel()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
