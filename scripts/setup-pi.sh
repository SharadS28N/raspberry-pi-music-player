
#!/bin/bash

# PiPlayer setup script for Raspberry Pi

set -e

echo "=== PiPlayer Setup ==="

# Update packages
echo "1. Updating package lists..."
sudo apt-get update -y

# Install dependencies
echo "2. Installing dependencies..."
sudo apt-get install -y python3 python3-pip python3-venv mpv git

# Create project directory (if not exists)
PROJECT_DIR="$HOME/piplayer"
echo "3. Setting up project in $PROJECT_DIR..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create virtual environment
echo "4. Creating virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "5. Installing Python dependencies..."
pip install --upgrade pip
pip install fastapi uvicorn yt-dlp

# Create systemd services
echo "6. Setting up systemd services..."

# mpv service
cat > /tmp/mpv.service << 'EOF'
[Unit]
Description=MPV Music Player for PiPlayer
After=network.target

[Service]
Type=simple
User=%USER%
ExecStart=/usr/bin/mpv --idle=yes --input-ipc-server=/tmp/mpv.sock
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# PiPlayer service
cat > /tmp/piplayer.service << 'EOF'
[Unit]
Description=PiPlayer Web Interface
After=network.target mpv.service

[Service]
Type=simple
User=%USER%
WorkingDirectory=%PROJECT_DIR%
ExecStart=%PROJECT_DIR%/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment="PATH=%PROJECT_DIR%/venv/bin"

[Install]
WantedBy=multi-user.target
EOF

# Replace placeholders
sed -i "s|%USER%|$USER|g" /tmp/mpv.service /tmp/piplayer.service
sed -i "s|%PROJECT_DIR%|$PROJECT_DIR|g" /tmp/piplayer.service

# Install services
sudo cp /tmp/mpv.service /etc/systemd/system/
sudo cp /tmp/piplayer.service /etc/systemd/system/

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable mpv.service
sudo systemctl enable piplayer.service

# Clean up
rm /tmp/mpv.service /tmp/piplayer.service

echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Transfer your project files to $PROJECT_DIR/backend"
echo "2. Start services with:"
echo "   sudo systemctl start mpv.service"
echo "   sudo systemctl start piplayer.service"
echo "3. Access PiPlayer at http://$(hostname -I | awk '{print $1}'):8000"
