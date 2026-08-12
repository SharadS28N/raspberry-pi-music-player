import subprocess
import sys
import os
import re
import time
import logging
from typing import Dict, List, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class HiFiServiceManager:
    """Manages high-fidelity audio background daemons: Roon Endpoint, AirPlay (Shairport-sync), UPnP/DLNA, Spotify Connect (Librespot), and HAT DACs."""

    def __init__(self):
        self.is_linux = sys.platform.startswith("linux")
        self.services_state = {
            "roon": {"enabled": False, "name": "Roon Endpoint (Bridge)", "daemon": "roonbridge.service", "description": "Minimal, bit-perfect Audio Endpoint for USB & HAT DACs"},
            "airplay": {"enabled": True, "name": "AirPlay Receiver (Shairport-Sync)", "daemon": "shairport-sync.service", "description": "Apple AirPlay loss-less streaming receiver"},
            "upnp": {"enabled": True, "name": "UPnP / DLNA Renderer", "daemon": "gmediarender.service", "description": "Open UPnP/DLNA Media Renderer target"},
            "spotify": {"enabled": False, "name": "Spotify Connect (Librespot)", "daemon": "librespot.service", "description": "Spotify Connect hardware player sink"}
        }

    def _run_cmd(self, cmd: List[str], timeout: int = 4) -> str:
        if not self.is_linux:
            return ""
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
            return res.stdout.strip()
        except Exception as e:
            logger.debug(f"Command {' '.join(cmd)} execution error: {e}")
            return ""

    def is_service_active(self, daemon_name: str) -> bool:
        if not self.is_linux:
            return False
        out = self._run_cmd(["systemctl", "is-active", daemon_name])
        return out == "active"

    def get_hifi_status(self) -> Dict:
        status = {}
        for key, svc in self.services_state.items():
            active = self.is_service_active(svc["daemon"])
            status[key] = {
                "name": svc["name"],
                "active": active,
                "description": svc["description"],
                "daemon": svc["daemon"]
            }
        return status

    def toggle_hifi_service(self, service_key: str, enable: bool) -> Dict:
        if service_key not in self.services_state:
            raise ValueError(f"Unknown Hi-Fi service: {service_key}")

        svc = self.services_state[service_key]
        daemon = svc["daemon"]

        if self.is_linux:
            action = "start" if enable else "stop"
            self._run_cmd(["sudo", "systemctl", action, daemon])
            if enable:
                self._run_cmd(["sudo", "systemctl", "enable", daemon])
            else:
                self._run_cmd(["sudo", "systemctl", "disable", daemon])

        svc["enabled"] = enable
        active = self.is_service_active(daemon) if self.is_linux else enable

        return {
            "status": "success",
            "service": service_key,
            "active": active
        }

    def detect_hat_dacs(self) -> List[Dict]:
        """Detect installed Raspberry Pi HAT DACs from ALSA cards & /proc/asound/cards."""
        dacs = [
            {"id": "jack", "name": "3.5mm Headphone Jack (Analog)", "detected": True, "type": "analog"},
            {"id": "hdmi", "name": "HDMI Audio Output", "detected": True, "type": "hdmi"}
        ]

        if not self.is_linux:
            dacs.append({"id": "hifiberry_dac", "name": "HiFiBerry DAC+ / DAC2 HD (Simulated)", "detected": True, "type": "hat_dac"})
            dacs.append({"id": "usb_dac", "name": "High-Res USB DAC (Simulated)", "detected": True, "type": "usb_dac"})
            return dacs

        cards_out = self._run_cmd(["cat", "/proc/asound/cards"])
        
        has_hifiberry = "sndrpihifiberry" in cards_out or "hifiberry" in cards_out.lower()
        has_allo = "bossdac" in cards_out.lower() or "allo" in cards_out.lower()
        has_iqaudio = "iqaudio" in cards_out.lower()
        has_usb = "usb" in cards_out.lower() or "dac" in cards_out.lower()

        dacs.append({"id": "hifiberry_dac", "name": "HiFiBerry DAC / DAC+ / DAC2 HD", "detected": has_hifiberry, "type": "hat_dac"})
        dacs.append({"id": "allo_boss", "name": "Allo Boss Master DAC", "detected": has_allo, "type": "hat_dac"})
        dacs.append({"id": "iqaudio_dac", "name": "IQaudio DAC+ / Codec Zero", "detected": has_iqaudio, "type": "hat_dac"})
        dacs.append({"id": "usb_dac", "name": "High-Res USB DAC / Asynchronous", "detected": has_usb, "type": "usb_dac"})

        return dacs


def get_system_metrics() -> Dict:
    """Collect real-time system hardware performance metrics for pi-aamps Web OS telemetry."""
    is_linux = sys.platform.startswith("linux")

    cpu_usage = 0.0
    mem_used_mb = 120
    mem_total_mb = 1024
    mem_percent = 12.0
    disk_used_gb = 4.2
    disk_total_gb = 32.0
    disk_percent = 13.0
    temp_c = 42.0
    uptime_str = "1h 12m"

    if is_linux:
        try:
            # Read CPU load
            with open("/proc/loadavg", "r") as f:
                load1 = float(f.read().split()[0])
                cpu_usage = round(min(100.0, load1 * 25.0), 1)
        except Exception:
            pass

        try:
            # Read Memory Info
            with open("/proc/meminfo", "r") as f:
                lines = f.readlines()
                mem_total = 0
                mem_avail = 0
                for line in lines:
                    if line.startswith("MemTotal:"):
                        mem_total = int(line.split()[1]) // 1024
                    elif line.startswith("MemAvailable:"):
                        mem_avail = int(line.split()[1]) // 1024
                if mem_total > 0:
                    mem_total_mb = mem_total
                    mem_used_mb = mem_total - mem_avail
                    mem_percent = round((mem_used_mb / mem_total_mb) * 100, 1)
        except Exception:
            pass

        try:
            # Read Disk Info
            stat = os.statvfs("/")
            disk_total_bytes = stat.f_blocks * stat.f_frsize
            disk_free_bytes = stat.f_bavail * stat.f_frsize
            disk_used_bytes = disk_total_bytes - disk_free_bytes
            disk_total_gb = round(disk_total_bytes / (1024**3), 1)
            disk_used_gb = round(disk_used_bytes / (1024**3), 1)
            disk_percent = round((disk_used_gb / max(1.0, disk_total_gb)) * 100, 1)
        except Exception:
            pass

        try:
            # Read RPi CPU Temperature
            if os.path.exists("/sys/class/thermal/thermal_zone0/temp"):
                with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
                    temp_c = round(float(f.read().strip()) / 1000.0, 1)
        except Exception:
            pass

        try:
            with open("/proc/uptime", "r") as f:
                uptime_secs = float(f.read().split()[0])
                hours = int(uptime_secs // 3600)
                mins = int((uptime_secs % 3600) // 60)
                uptime_str = f"{hours}h {mins}m"
        except Exception:
            pass

    return {
        "cpu_usage_percent": cpu_usage,
        "memory": {
            "used_mb": mem_used_mb,
            "total_mb": mem_total_mb,
            "percent": mem_percent
        },
        "storage": {
            "used_gb": disk_used_gb,
            "total_gb": disk_total_gb,
            "percent": disk_percent
        },
        "temperature_celsius": temp_c,
        "uptime": uptime_str
    }


hifi_service_manager = HiFiServiceManager()
