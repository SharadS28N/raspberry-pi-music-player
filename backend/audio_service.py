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
        self.master_volume = 85
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
        logger.info("Initializing Raspberry Pi 3.5mm hardware audio output...")
        self._set_alsa_hardware_volume(85)
        player.set_volume(85)
        
        dev_info = AUDIO_OUTPUT_DEVICES.get("jack", {})
        if "alsa_device" in dev_info:
            player.set_audio_device(dev_info["alsa_device"])

    def _set_alsa_hardware_volume(self, volume: int):
        if not self.is_linux:
            return
        # Try PCM first (standard RPi 3.5mm jack ALSA control), fallback to Master
        out_pcm = self._run_cmd(["amixer", "sset", "PCM", "on"])
        out_pcm_vol = self._run_cmd(["amixer", "sset", "PCM", f"{volume}%"])
        if "Unable to find simple control" in out_pcm_vol or not out_pcm_vol.strip():
            self._run_cmd(["amixer", "sset", "Master", "on"])
            self._run_cmd(["amixer", "sset", "Master", f"{volume}%"])

    def get_output_devices(self) -> List[Dict]:
        devices = []
        for key, val in AUDIO_OUTPUT_DEVICES.items():
            devices.append({
                "id": key,
                "name": val["name"],
                "active": (key == self.current_output),
                "icon": val.get("icon", "fa-volume-up")
            })
        return devices

    def set_output_device(self, device_id: str) -> Dict:
        if device_id not in AUDIO_OUTPUT_DEVICES:
            raise ValueError(f"Invalid audio device id: {device_id}")

        logger.info(f"Switching audio output device to: {device_id}")
        self.current_output = device_id
        dev_info = AUDIO_OUTPUT_DEVICES[device_id]

        alsa_target = dev_info["alsa_device"]
        player.set_audio_device(alsa_target)

        if self.is_linux:
            self._set_alsa_hardware_volume(self.master_volume)

        return {
            "status": "success",
            "active_output": device_id,
            "name": dev_info["name"]
        }

    def get_master_volume(self) -> int:
        if not self.is_linux:
            return self.master_volume

        out = self._run_cmd(["amixer", "sget", "PCM"])
        if "Unable to find simple control" in out or not out.strip():
            out = self._run_cmd(["amixer", "sget", "Master"])

        if "%" in out:
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
