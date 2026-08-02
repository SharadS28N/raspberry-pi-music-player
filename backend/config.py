import os

# Server configuration
HOST = "0.0.0.0"
PORT = 8000
DEBUG = False

# Base Directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(os.path.dirname(BASE_DIR), "frontend")
DATABASE_PATH = os.path.join(BASE_DIR, "piplayer.db")

# MPV IPC Socket configuration
MPV_SOCKET = "/tmp/mpv.sock" if os.name != "nt" else r"\\.\pipe\mpv-pipe"
AUTO_START_MPV = True
MPV_COMMAND = "mpv"

# Default hardware audio output mapping
AUDIO_OUTPUT_DEVICES = {
    "jack": {
        "name": "3.5mm Headphone Jack",
        "alsa_device": "alsa/plughw:CARD=Headphones,DEV=0",
        "icon": "fa-headphones"
    },
    "hdmi": {
        "name": "HDMI Audio",
        "alsa_device": "alsa/plughw:CARD=vc4hdmi,DEV=0",
        "icon": "fa-tv"
    },
    "bluetooth": {
        "name": "Bluetooth Speaker",
        "alsa_device": "pulse",
        "icon": "fa-bluetooth"
    },
    "usb": {
        "name": "USB DAC / Audio",
        "alsa_device": "alsa/sysdefault:CARD=DAC",
        "icon": "fa-plug"
    }
}
