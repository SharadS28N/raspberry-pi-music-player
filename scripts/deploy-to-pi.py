import paramiko
import os
import sys
import zipfile
import time

# Configuration for Raspberry Pi Target
PI_HOST = "192.168.18.159"
PI_USER = "aamps"
PI_PASS = "aamps"
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZIP_PATH = os.path.join(PROJECT_DIR, "piplayer.zip")
PI_REMOTE_ZIP = "/home/aamps/piplayer.zip"
PI_TARGET_DIR = "/home/aamps/piplayer"


def create_project_zip():
    print("[1/5] Creating project archive (piplayer.zip)...")
    if os.path.exists(ZIP_PATH):
        os.remove(ZIP_PATH)

    exclude_dirs = {".git", "venv", "__pycache__", ".pytest_cache", ".gemini", ".agents"}

    with zipfile.ZipFile(ZIP_PATH, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(PROJECT_DIR):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            for file in files:
                if file.endswith(".zip") or file.endswith(".pyc") or file.endswith(".db"):
                    continue
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, PROJECT_DIR)
                zipf.write(file_path, rel_path)

    print(f"      Zip file created successfully ({os.path.getsize(ZIP_PATH)} bytes).")


def run_ssh_command(ssh, cmd, sudo_pass=None):
    print(f"   --> {cmd[:90]}...")
    if cmd.startswith("sudo ") and sudo_pass:
        stdin, stdout, stderr = ssh.exec_command(cmd, get_pty=True)
        stdin.write(sudo_pass + "\n")
        stdin.flush()
    else:
        stdin, stdout, stderr = ssh.exec_command(cmd)

    exit_status = stdout.channel.recv_exit_status()
    out = stdout.read().decode("utf-8", errors="ignore")
    err = stderr.read().decode("utf-8", errors="ignore")

    if exit_status != 0:
        print(f"       Warning/Error (Exit Code {exit_status}): {err.strip() or out.strip()[:200]}")
    else:
        print("       [OK]")
    return exit_status, out, err


def main():
    print("=" * 60)
    print("   Deploying Spotify-Style Bluetooth Receiver PiPlayer (192.168.18.159)")
    print("=" * 60)

    create_project_zip()

    print("\n[2/5] Connecting via SSH to Raspberry Pi (aamps@192.168.18.159)...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(PI_HOST, username=PI_USER, password=PI_PASS, timeout=15)
        print("      SSH Connection established successfully!")

        print("\n[3/5] Uploading project archive to Raspberry Pi...")
        sftp = ssh.open_sftp()
        sftp.put(ZIP_PATH, PI_REMOTE_ZIP)
        sftp.close()
        print("      Archive uploaded to /home/aamps/piplayer.zip.")

        print("\n[4/5] Updating packages, Python virtual environment & mpv player daemon...")
        commands = [
            "sudo pkill -f python3 || true",
            "sudo pkill -f mpv || true",
            "sudo apt-get update -y",
            "sudo apt-get install -y python3 python3-pip python3-venv mpv bluetooth bluez rfkill alsa-utils bluez-tools pulseaudio-module-bluetooth unzip",
            f"mkdir -p {PI_TARGET_DIR}",
            f"unzip -o {PI_REMOTE_ZIP} -d {PI_TARGET_DIR}",
            f"rm -f {PI_REMOTE_ZIP}",
            f"cd {PI_TARGET_DIR} && python3 -m venv venv",
            f"cd {PI_TARGET_DIR} && {PI_TARGET_DIR}/venv/bin/pip install --upgrade pip",
            f"cd {PI_TARGET_DIR} && {PI_TARGET_DIR}/venv/bin/pip install -r requirements.txt",
            # Set ALSA Master volume to 85% for loud clear sound
            "amixer sset Master on && amixer sset Master 85%",
            # Bluetooth A2DP Receiver Mode (Phone Discoverable)
            "sudo rfkill unblock bluetooth",
            "sudo bluetoothctl power on",
            "sudo bluetoothctl discoverable on",
            "sudo bluetoothctl pairable on",
            # Ensure standalone yt-dlp is present
            "sudo wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp",
            # Create mpv background daemon service targeting direct 3.5mm card alsa/plughw:CARD=Headphones,DEV=0
            f'''sudo bash -c 'cat > /etc/systemd/system/mpv.service << "EOF"
[Unit]
Description=MPV Player Daemon for PiPlayer
After=sound.target network.target bluetooth.target

[Service]
Type=simple
User=aamps
ExecStart=/usr/bin/mpv --idle=yes --ytdl=yes --ytdl-format=bestaudio/best --audio-device=alsa/plughw:CARD=Headphones,DEV=0 --cache=yes --demuxer-max-bytes=8M --demuxer-readahead-secs=8 --network-timeout=5 --input-ipc-server=/tmp/mpv.sock --no-video
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF' ''',
            # Create piplayer web service
            f'''sudo bash -c 'cat > /etc/systemd/system/piplayer.service << "EOF"
[Unit]
Description=PiPlayer Web Server & Sound Controller
After=network-online.target sound.target bluetooth.target mpv.service
Wants=network-online.target mpv.service

[Service]
Type=simple
User=aamps
WorkingDirectory={PI_TARGET_DIR}/backend
ExecStart={PI_TARGET_DIR}/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF' ''',
            # Enable and start services
            "sudo systemctl daemon-reload",
            "sudo systemctl enable mpv.service",
            "sudo systemctl enable piplayer.service",
            "sudo systemctl restart mpv.service",
            "sudo systemctl restart piplayer.service",
            "sudo systemctl status piplayer.service --no-pager"
        ]

        for cmd in commands:
            run_ssh_command(ssh, cmd, sudo_pass=PI_PASS)

        print("\n[5/5] Service Status & Connectivity Check...")
        time.sleep(3)
        status, out, err = run_ssh_command(ssh, "sudo systemctl is-active piplayer.service", sudo_pass=PI_PASS)
        if "active" in out:
            print("\n" + "=" * 60)
            print("  SUCCESS: Spotify-Style PiPlayer is running live on your Raspberry Pi!")
            print(f"  Open in your browser:  http://{PI_HOST}:8000")
            print("=" * 60 + "\n")
        else:
            print("\n[!] Service status:", out.strip())

    except Exception as e:
        print(f"\n[!] Deployment error: {e}")
        sys.exit(1)
    finally:
        ssh.close()
        if os.path.exists(ZIP_PATH):
            try:
                os.remove(ZIP_PATH)
            except Exception:
                pass


if __name__ == "__main__":
    main()
