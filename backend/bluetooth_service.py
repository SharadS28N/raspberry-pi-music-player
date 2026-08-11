import subprocess
import sys
import re
import logging
import threading
import time
from typing import Dict, List, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BluetoothService:
    def __init__(self):
        self.is_linux = sys.platform.startswith("linux")
        self.powered = False
        self.discoverable = False
        self.mode = "receiver"  # Dedicated BT Sound Receiver (A2DP Sink)
        self._agent_process: Optional[subprocess.Popen] = None
        if self.is_linux:
            self._start_agent()

    def _run_cmd(self, cmd: List[str], timeout: int = 10) -> str:
        if not self.is_linux:
            return ""
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
            return res.stdout
        except Exception as e:
            logger.error(f"Bluetooth command {' '.join(cmd)} error: {e}")
            return ""

    def _start_agent(self):
        """Starts a persistent background bluetoothctl agent process with NoInputNoOutput capability for automatic pairing."""
        if not self.is_linux:
            return

        if self._agent_process and self._agent_process.poll() is None:
            return

        try:
            # We spawn an interactive bluetoothctl shell session that registers NoInputNoOutput default-agent
            cmd = ["bluetoothctl"]
            self._agent_process = subprocess.Popen(
                cmd,
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1
            )
            if self._agent_process.stdin:
                self._agent_process.stdin.write("power on\n")
                self._agent_process.stdin.write("agent NoInputNoOutput\n")
                self._agent_process.stdin.write("default-agent\n")
                self._agent_process.stdin.write("pairable on\n")
                self._agent_process.stdin.write("discoverable on\n")
                self._agent_process.stdin.flush()
            logger.info("Persistent BlueZ Bluetooth Agent started successfully")
        except Exception as e:
            logger.error(f"Could not start BlueZ Bluetooth Agent process: {e}")

    def _stop_agent(self):
        if self._agent_process:
            try:
                self._agent_process.terminate()
                self._agent_process.wait(timeout=2)
            except Exception:
                pass
            self._agent_process = None

    def get_status(self) -> Dict:
        if not self.is_linux:
            return {
                "powered": self.powered,
                "discoverable": self.discoverable,
                "mode": "receiver",
                "connected_device": {
                    "name": "User Smartphone / PC",
                    "mac": "AA:BB:CC:DD:EE:FF",
                    "connected": True,
                    "rssi": -42,
                    "type": "audio-card"
                } if self.powered else None,
                "adapter": "hci0 (Dedicated BT Audio Receiver)"
            }

        show_out = self._run_cmd(["bluetoothctl", "show"])
        self.powered = "Powered: yes" in show_out
        self.discoverable = "Discoverable: yes" in show_out

        info_out = self._run_cmd(["bluetoothctl", "info"])
        connected_dev = None
        if "Connected: yes" in info_out:
            name_match = re.search(r"Name:\s+(.+)", info_out)
            mac_match = re.search(r"Device\s+([0-9A-FA-F:]+)", info_out)
            connected_dev = {
                "name": name_match.group(1).strip() if name_match else "Connected Device",
                "mac": mac_match.group(1).strip() if mac_match else "",
                "connected": True,
                "type": "audio-card"
            }

        return {
            "powered": self.powered,
            "discoverable": self.discoverable,
            "mode": "receiver",
            "connected_device": connected_dev,
            "adapter": "hci0"
        }

    def set_power(self, power: bool) -> bool:
        logger.info(f"Setting Bluetooth Receiver Power: {power}")
        if not self.is_linux:
            self.powered = power
            self.discoverable = power
            return self.powered

        if power:
            self._run_cmd(["sudo", "rfkill", "unblock", "bluetooth"])
            self._run_cmd(["bluetoothctl", "power", "on"])
            # Hardcode Bluetooth Device Class to Audio Speaker / Receiver (0x20041C)
            self._run_cmd(["sudo", "hciconfig", "hci0", "class", "0x20041C"])
            self._run_cmd(["sudo", "hciconfig", "hci0", "piscan"])
            self._start_agent()
            self._run_cmd(["bluetoothctl", "pairable", "on"])
            self._run_cmd(["bluetoothctl", "discoverable", "on"])
            self.powered = True
            self.discoverable = True
        else:
            self._stop_agent()
            self._run_cmd(["bluetoothctl", "discoverable", "off"])
            self._run_cmd(["bluetoothctl", "power", "off"])
            self.powered = False
            self.discoverable = False

        return self.powered


    def set_mode(self, mode: str) -> str:
        self.mode = "receiver"
        if self.is_linux and self.powered:
            self._run_cmd(["hciconfig", "hci0", "class", "0x20041C"])
            self._run_cmd(["hciconfig", "hci0", "piscan"])
            self._run_cmd(["bluetoothctl", "discoverable", "on"])
        return "receiver"

    def set_discoverable(self, discoverable: bool) -> bool:
        if not self.is_linux:
            self.discoverable = discoverable
            return self.discoverable

        if discoverable and self.powered:
            self._run_cmd(["hciconfig", "hci0", "piscan"])
            self._run_cmd(["bluetoothctl", "discoverable", "on"])
            self._run_cmd(["bluetoothctl", "pairable", "on"])
        else:
            self._run_cmd(["bluetoothctl", "discoverable", "off"])

        self.discoverable = discoverable
        return self.discoverable

    def scan_devices(self) -> List[Dict]:
        if not self.is_linux:
            return [
                {"mac": "AA:BB:CC:DD:EE:FF", "name": "User Smartphone / PC", "connected": self.powered, "rssi": -55},
                {"mac": "11:22:33:44:55:66", "name": "Wireless Audio Player", "connected": False, "rssi": -70}
            ]

        logger.info("Scanning for Bluetooth devices...")
        self._run_cmd(["hciconfig", "hci0", "class", "0x20041C"])
        # Perform scan with timeout
        self._run_cmd(["bluetoothctl", "--timeout", "4", "scan", "on"], timeout=6)

        devices_out = self._run_cmd(["bluetoothctl", "devices"])
        devices = []
        for line in devices_out.strip().split("\n"):
            match = re.search(r"Device\s+([0-9A-FA-F:]+)\s+(.+)", line)
            if match:
                mac = match.group(1)
                name = match.group(2)
                dev_info = self._run_cmd(["bluetoothctl", "info", mac])
                connected = "Connected: yes" in dev_info
                devices.append({
                    "mac": mac,
                    "name": name,
                    "connected": connected
                })

        return devices

    def connect_device(self, mac: str) -> bool:
        logger.info(f"Connecting to Bluetooth device: {mac}")
        if not self.is_linux:
            return True

        self._start_agent()
        self._run_cmd(["bluetoothctl", "trust", mac])
        self._run_cmd(["bluetoothctl", "pair", mac])
        res = self._run_cmd(["bluetoothctl", "connect", mac])
        return "Connection successful" in res or "Connected: yes" in res

    def disconnect_device(self, mac: str) -> bool:
        logger.info(f"Disconnecting Bluetooth device: {mac}")
        if not self.is_linux:
            return True

        self._run_cmd(["bluetoothctl", "disconnect", mac])
        return True


bluetooth_service = BluetoothService()

