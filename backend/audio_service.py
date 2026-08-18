import subprocess
import sys
import re
import logging
from typing import Dict, List
from config import AUDIO_OUTPUT_DEVICES
from player import player

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AudioService:
    def __init__(self):
        self.is_linux = sys.platform.startswith("linux")
        self.current_output = "jack"  # Default output: 3.5mm Headphone Jack
        self.master_volume = 60
        if self.is_linux:
            self._init_hardware_audio()

    def _run_cmd(self, cmd: List[str]) -> str:
        if not self.is_linux:
            return ""
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            return res.stdout
        except Exception as e:
            logger.error(f"Error executing audio command {' '.join(cmd)}: {e}")
            return ""

    def _init_hardware_audio(self):
        logger.info("Initializing Raspberry Pi 3.5mm hardware audio output (capped at 60% max)...")
        self._set_alsa_hardware_volume(60)
        player.set_volume(60)
        
        dev_info = AUDIO_OUTPUT_DEVICES.get("jack", {})
        if "alsa_device" in dev_info:
            player.set_audio_device(dev_info["alsa_device"])


    def _set_alsa_hardware_volume(self, volume: int):
        if not self.is_linux:
            return
        vol_str = f"{volume}%"
        self._run_cmd(["amixer", "-c", "0", "sset", "PCM", vol_str, "unmute"])
        self._run_cmd(["amixer", "-c", "Headphones", "sset", "PCM", vol_str, "unmute"])
        self._run_cmd(["amixer", "sset", "Master", vol_str, "unmute"])
        self._run_cmd(["amixer", "sset", "Headphones", vol_str, "unmute"])
        self._run_cmd(["amixer", "sset", "PCM", vol_str, "unmute"])


    def get_output_devices(self) -> List[Dict]:
        devices = []
        for key, val in AUDIO_OUTPUT_DEVICES.items():
            devices.append({
                "id": key,
                "name": val["name"],
                "active": (key == self.current_output),
                "icon": val.get("icon", "fa-volume-up"),
                "type": val.get("type", "analog")
            })
        return devices


    def set_output_device(self, device_id: str) -> Dict:
        if device_id not in AUDIO_OUTPUT_DEVICES:
            raise ValueError(f"Invalid audio device id: {device_id}")

        logger.info(f"Switching audio output device to: {device_id}")
        self.current_output = device_id
        dev_info = AUDIO_OUTPUT_DEVICES[device_id]

        if "alsa_device" in dev_info:
            player.set_audio_device(dev_info["alsa_device"])

        return {
            "status": "success",
            "active_output": self.current_output,
            "device_name": dev_info["name"]
        }

    def get_master_volume(self) -> int:
        if not self.is_linux:
            return self.master_volume

        for ctrl in ["Master", "Headphones", "PCM"]:
            out = self._run_cmd(["amixer", "sget", ctrl])
            match = re.search(r"\[(\d+)%\]", out)
            if match:
                self.master_volume = int(match.group(1))
                return self.master_volume

        return self.master_volume

    def set_master_volume(self, volume: int) -> int:
        volume = max(0, min(100, volume))
        self.master_volume = volume
        logger.info(f"Setting master hardware volume to: {volume}%")

        if self.is_linux:
            self._set_alsa_hardware_volume(volume)

        return self.master_volume




audio_service = AudioService()
