
# PiPlayer Deployment Guide for Raspberry Pi

## Prerequisites
- Raspberry Pi running Raspberry Pi OS (Bookworm or Bullseye)
- SSH access to your Pi: `ssh aamps@192.168.18.159` (password: `aamps`)

## Step 1: Transfer Project Files to Raspberry Pi

From your Windows machine, use `scp` or a tool like WinSCP to transfer the files.

### Option A: Using SCP (PowerShell)
```powershell
# First, create a zip of the project (excluding __pycache__ and venv)
Compress-Archive -Path * -DestinationPath piplayer.zip -Force

# Transfer the zip to Pi
scp piplayer.zip aamps@192.168.18.159:~
```

### Option B: Using Git (Recommended)
If you have the project in a Git repo:
1. Push to GitHub/GitLab
2. On the Pi, clone the repo:
   ```bash
   ssh aamps@192.168.18.159
   git clone <your-repo-url> ~/piplayer
   ```

## Step 2: SSH into Raspberry Pi and Set Up

```bash
# SSH into your Pi
ssh aamps@192.168.18.159
# Password: aamps

# If you used SCP, unzip the file
cd ~
unzip piplayer.zip -d piplayer
cd piplayer

# Make the setup script executable
chmod +x scripts/setup-pi.sh

# Run the setup script
./scripts/setup-pi.sh
```

## Step 3: Copy Backend Files to Correct Location

After running the setup script, copy your backend files:
```bash
cd ~/piplayer
cp -r backend/* ~/piplayer/
cp frontend/index.html ~/piplayer/
mkdir -p ~/piplayer/database
mkdir -p ~/piplayer/logs
```

## Step 4: Start the Services

```bash
# Start mpv service
sudo systemctl start mpv.service

# Start PiPlayer service
sudo systemctl start piplayer.service

# Check status
sudo systemctl status mpv.service
sudo systemctl status piplayer.service

# Enable services to start on boot (already done by setup script)
sudo systemctl enable mpv.service
sudo systemctl enable piplayer.service
```

## Step 5: Access PiPlayer

Open a browser and go to:
http://192.168.18.159:8000

## Troubleshooting

### View Logs
```bash
# PiPlayer logs
sudo journalctl -u piplayer.service -f

# mpv logs
sudo journalctl -u mpv.service -f
```

### Restart Services
```bash
sudo systemctl restart mpv.service
sudo systemctl restart piplayer.service
```
