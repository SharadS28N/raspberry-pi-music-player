import os

# Server configuration
PROJECT_NAME = "pi-aamps"
HOST = "0.0.0.0"
DEFAULT_PORT = 8000
PORT = int(os.environ.get("PORT", str(DEFAULT_PORT)))
DEBUG = False

# Base Directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(os.path.dirname(BASE_DIR), "frontend")
DATABASE_PATH = os.path.join(BASE_DIR, "pi_aamps.db")

# MPV IPC Socket configuration
MPV_SOCKET = "/tmp/pi-aamps-mpv.sock" if os.name != "nt" else r"\\.\pipe\pi-aamps-mpv-pipe"
AUTO_START_MPV = True
MPV_COMMAND = "mpv"

# Default hardware audio output mapping & HAT DACs
AUDIO_OUTPUT_DEVICES = {
    "jack": {
        "name": "3.5mm Headphone Jack (Analog)",
        "alsa_device": "alsa/plughw:CARD=Headphones,DEV=0",
        "icon": "fa-headphones",
        "type": "analog"
    },
    "hdmi": {
        "name": "HDMI High-Def Audio",
        "alsa_device": "alsa/plughw:CARD=vc4hdmi,DEV=0",
        "icon": "fa-tv",
        "type": "hdmi"
    },
    "hifiberry_dac": {
        "name": "HiFiBerry DAC / DAC+ / DAC2 HD",
        "alsa_device": "alsa/plughw:CARD=sndrpihifiberry,DEV=0",
        "icon": "fa-microchip",
        "type": "hat_dac"
    },
    "allo_boss": {
        "name": "Allo Boss Master DAC",
        "alsa_device": "alsa/plughw:CARD=BossDAC,DEV=0",
        "icon": "fa-microchip",
        "type": "hat_dac"
    },
    "iqaudio_dac": {
        "name": "IQaudio DAC+ / Codec Zero",
        "alsa_device": "alsa/plughw:CARD=IQaudioDAC,DEV=0",
        "icon": "fa-microchip",
        "type": "hat_dac"
    },
    "usb_dac": {
        "name": "High-Res USB DAC / Asynchronous",
        "alsa_device": "alsa/sysdefault:CARD=DAC",
        "icon": "fa-plug",
        "type": "usb_dac"
    },
    "bluetooth": {
        "name": "Bluetooth Wireless Audio Sink",
        "alsa_device": "pulse",
        "icon": "fa-bluetooth",
        "type": "bluetooth"
    }
}

