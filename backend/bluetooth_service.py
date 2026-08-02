import subprocess
import sys
import re
import logging
from typing import Dict, List

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BluetoothService:
    def __init__(self):
        self.is_linux = sys.platform.startswith("linux")
        self.powered = False
        self.discoverable = False
        if self.is_linux:
            self.init_bluetooth()

    def _run_cmd(self, cmd: List[str]) -> str:
        if not self.is_linux:
            return ""
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            return res.stdout
        except Exception as e:
            logger.error(f"Bluetooth command {' '.join(cmd)} error: {e}")
            return ""

    def init_bluetooth(self):
        self._run_cmd(["rfkill", "unblock", "bluetooth"])
        self._run_cmd(["bluetoothctl", "power", "on"])
        self._run_cmd(["bluetoothctl", "discoverable", "on"])
        self._run_cmd(["bluetoothctl", "pairable", "on"])
        self._run_cmd(["bluetoothctl", "agent", "NoInputNoOutput"])
        self._run_cmd(["bluetoothctl", "default-agent"])
        self._run_cmd(["hciconfig", "hci0", "piscan"])
        self.powered = True
        self.discoverable = True

    def get_status(self) -> Dict:
        if not self.is_linux:
            return {
                "powered": self.powered,
                "discoverable": self.discoverable,
                "connected_device": None,
                "adapter": "hci0 (Mock)"
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
                "mac": mac_match.group(1).strip() if mac_match else ""
            }

        return {
            "powered": self.powered,
            "discoverable": self.discoverable,
            "connected_device": connected_dev,
            "adapter": "hci0"
        }

    def set_power(self, power: bool) -> bool:
        if not self.is_linux:
            self.powered = power
            return self.powered

        if power:
            self._run_cmd(["rfkill", "unblock", "bluetooth"])
            self._run_cmd(["bluetoothctl", "power", "on"])
            self._run_cmd(["bluetoothctl", "discoverable", "on"])
            self._run_cmd(["bluetoothctl", "pairable", "on"])
            self._run_cmd(["bluetoothctl", "agent", "NoInputNoOutput"])
            self._run_cmd(["bluetoothctl", "default-agent"])
        else:
            self._run_cmd(["bluetoothctl", "power", "off"])

        self.powered = power
        return self.powered

    def set_discoverable(self, discoverable: bool) -> bool:
        if not self.is_linux:
            self.discoverable = discoverable
            return self.discoverable

        if discoverable:
            self._run_cmd(["bluetoothctl", "discoverable", "on"])
            self._run_cmd(["bluetoothctl", "pairable", "on"])
        else:
            self._run_cmd(["bluetoothctl", "discoverable", "off"])

        self.discoverable = discoverable
        return self.discoverable

    def scan_devices(self) -> List[Dict]:
        if not self.is_linux:
            return [
                {"mac": "AA:BB:CC:DD:EE:FF", "name": "Phone / Bluetooth Speaker", "connected": False}
            ]

        logger.info("Scanning for Bluetooth devices...")
        self._run_cmd(["bluetoothctl", "scan", "on"])
        self._run_cmd(["sleep", "3"])
        self._run_cmd(["bluetoothctl", "scan", "off"])

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

        self._run_cmd(["bluetoothctl", "trust", mac])
        res = self._run_cmd(["bluetoothctl", "connect", mac])
        return "Connection successful" in res or "Connected: yes" in res

    def disconnect_device(self, mac: str) -> bool:
        logger.info(f"Disconnecting Bluetooth device: {mac}")
        if not self.is_linux:
            return True

        res = self._run_cmd(["bluetoothctl", "disconnect", mac])
        return True


bluetooth_service = BluetoothService()
