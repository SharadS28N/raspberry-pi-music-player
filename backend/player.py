import socket
import json
import sys
import os
import time
import subprocess
from typing import Dict, Optional
from config import MPV_SOCKET, AUTO_START_MPV, MPV_COMMAND
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Audio Equalizer Filter Presets for MPV
EQ_PRESETS = {
    "normal": "",
    "bass": "lavfi=[equalizer=f=60:width_type=h:width=50:g=7,equalizer=f=150:width_type=h:width=100:g=4]",
    "vocal": "lavfi=[highpass=f=80,lowpass=f=12000,equalizer=f=1000:width_type=h:width=500:g=4]",
    "treble": "lavfi=[equalizer=f=8000:width_type=h:width=2000:g=6,equalizer=f=12000:width_type=h:width=3000:g=4]",
    "party": "lavfi=[equalizer=f=60:width_type=h:width=50:g=6,equalizer=f=10000:width_type=h:width=3000:g=5]"
}


class MPVPlayer:
    def __init__(self):
        self.socket_path = MPV_SOCKET
        self.sock = None
        self.pipe_file = None
        self.process = None
        self.current_audio_device = "alsa/plughw:CARD=Headphones,DEV=0"
        self.sim_paused = True
        self.sim_position = 0.0
        self.sim_duration = 0.0
        self.sim_volume = 85
        self.sim_last_update = time.time()
        self.current_eq = "normal"
        self._connect()

    def _spawn_mpv(self):
        if self.process and self.process.poll() is None:
            return

        try:
            cmd = [
                MPV_COMMAND,
                "--idle=yes",
                "--ytdl=yes",
                "--ytdl-format=bestaudio/best",
                "--audio-device=alsa/plughw:CARD=Headphones,DEV=0",
                "--cache=yes",
                "--demuxer-max-bytes=8M",
                "--demuxer-readahead-secs=8",
                "--network-timeout=5",
                f"--input-ipc-server={self.socket_path}",
                "--no-video"
            ]
            logger.info(f"Auto-starting mpv process: {' '.join(cmd)}")
            creationflags = 0
            if sys.platform == "win32":
                creationflags = subprocess.CREATE_NO_WINDOW

            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=creationflags
            )
            time.sleep(1.2)
        except Exception as e:
            logger.warning(f"Could not spawn mpv binary ({e}). Using integrated software player state.")

    def _connect(self):
        if self.sock or self.pipe_file:
            return

        attempts = 2 if AUTO_START_MPV else 1
        for attempt in range(attempts):
            try:
                if sys.platform == "win32":
                    if os.path.exists(self.socket_path) or self.socket_path.startswith("\\\\"):
                        self.pipe_file = open(self.socket_path, "r+b", buffering=0)
                        logger.info("Connected to mpv IPC named pipe (Windows)")
                        return
                else:
                    if os.path.exists(self.socket_path):
                        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                        self.sock.connect(self.socket_path)
                        self.sock.settimeout(5.0)
                        logger.info(f"Connected to mpv IPC socket at {self.socket_path}")
                        return
            except Exception as e:
                logger.debug(f"Connect attempt {attempt + 1} failed: {e}")

            if attempt == 0 and AUTO_START_MPV:
                self._spawn_mpv()

    def _send_command(self, command: list) -> Optional[Dict]:
        self._connect()
        if not self.sock and not self.pipe_file:
            return None

        msg = json.dumps({"command": command}) + "\n"
        data_bytes = msg.encode("utf-8")

        try:
            if sys.platform == "win32" and self.pipe_file:
                self.pipe_file.write(data_bytes)
                response = self.pipe_file.readline()
                if response:
                    return json.loads(response.decode("utf-8").strip())
            elif self.sock:
                self.sock.sendall(data_bytes)
                response = b""
                while True:
                    chunk = self.sock.recv(4096)
                    if not chunk:
                        break
                    response += chunk
                    if b"\n" in chunk:
                        break
                if response:
                    line = response.decode("utf-8", errors="ignore").split("\n")[0]
                    return json.loads(line)
        except Exception as e:
            logger.error(f"Error sending command {command} to mpv: {e}")
            self.sock = None
            self.pipe_file = None
            return None

        return None

    def play(self, url: str, duration: Optional[int] = None):
        logger.info(f"Playing media stream: {url}")
        self.sim_paused = False
        self.sim_position = 0.0
        if duration and duration > 0:
            self.sim_duration = float(duration)
        self.sim_last_update = time.time()
        
        res = self._send_command(["loadfile", url, "replace"])
        self._send_command(["set_property", "pause", False])
        return res or {"status": "ok"}

    def pause(self):
        self._update_sim_pos()
        self.sim_paused = True
        res = self._send_command(["set_property", "pause", True])
        return res or {"status": "ok"}

    def resume(self):
        self.sim_paused = False
        self.sim_last_update = time.time()
        res = self._send_command(["set_property", "pause", False])
        return res or {"status": "ok"}

    def toggle_pause(self):
        if self.sim_paused:
            return self.resume()
        else:
            return self.pause()

    def stop(self):
        self.sim_paused = True
        self.sim_position = 0.0
        res = self._send_command(["stop"])
        return res or {"status": "ok"}

    def seek(self, seconds: float):
        self.sim_position = max(0.0, seconds)
        self.sim_last_update = time.time()
        return self._send_command(["seek", seconds, "absolute"])

    def set_position(self, seconds: float):
        return self.seek(seconds)

    def set_volume(self, volume: int):
        volume = max(0, min(100, volume))
        self.sim_volume = volume
        return self._send_command(["set_property", "volume", volume])

    def get_volume(self) -> int:
        resp = self._send_command(["get_property", "volume"])
        if resp and "data" in resp and resp["data"] is not None:
            self.sim_volume = int(resp["data"])
            return self.sim_volume
        return self.sim_volume

    def set_audio_device(self, device_name: str):
        logger.info(f"Setting mpv audio output device to: {device_name}")
        self.current_audio_device = device_name
        return self._send_command(["set_property", "audio-device", device_name])

    def set_equalizer(self, preset_name: str) -> str:
        if preset_name not in EQ_PRESETS:
            preset_name = "normal"
        self.current_eq = preset_name
        filter_str = EQ_PRESETS[preset_name]
        logger.info(f"Applying Equalizer Preset: {preset_name}")
        self._send_command(["set_property", "af", filter_str])
        return self.current_eq

    def _update_sim_pos(self):
        if not self.sim_paused:
            now = time.time()
            elapsed = now - self.sim_last_update
            self.sim_last_update = now
            self.sim_position += elapsed
            if self.sim_duration > 0 and self.sim_position >= self.sim_duration:
                self.sim_position = self.sim_duration
                self.sim_paused = True

    def get_status(self) -> Dict:
        self._update_sim_pos()

        status = {
            "paused": self.sim_paused,
            "position": round(self.sim_position, 1),
            "duration": round(self.sim_duration, 1),
            "volume": self.sim_volume,
            "audio_device": self.current_audio_device,
            "equalizer": self.current_eq,
            "connected": bool(self.sock or self.pipe_file)
        }

        if self.sock or self.pipe_file:
            paused_resp = self._send_command(["get_property", "pause"])
            if paused_resp and "data" in paused_resp and paused_resp["data"] is not None:
                status["paused"] = paused_resp["data"]
                self.sim_paused = paused_resp["data"]

            pos_resp = self._send_command(["get_property", "time-pos"])
            if pos_resp and "data" in pos_resp and pos_resp["data"] is not None:
                val = float(pos_resp["data"])
                if val >= 0:
                    status["position"] = round(val, 1)
                    self.sim_position = status["position"]

            dur_resp = self._send_command(["get_property", "duration"])
            if dur_resp and "data" in dur_resp and dur_resp["data"] is not None and float(dur_resp["data"]) > 0:
                status["duration"] = round(float(dur_resp["data"]), 1)
                self.sim_duration = status["duration"]

            idle_resp = self._send_command(["get_property", "idle-active"])
            if idle_resp and "data" in idle_resp and idle_resp["data"] is True:
                status["paused"] = True
                self.sim_paused = True

        return status


player = MPVPlayer()
