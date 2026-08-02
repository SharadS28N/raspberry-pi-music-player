#!/usr/bin/env python3
"""
PiPlayer Launcher with HTTPS & HTTP Support
Runs the PiPlayer web server with optional SSL/HTTPS and manages mpv background player automatically.
"""

import os
import sys
import socket
import subprocess

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.join(PROJECT_ROOT, "backend")
CERT_FILE = os.path.join(PROJECT_ROOT, "cert.pem")
KEY_FILE = os.path.join(PROJECT_ROOT, "key.pem")


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "192.168.18.159"


import shutil


def ensure_ssl_certs(ip):
    if os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE):
        return True

    if not shutil.which("openssl"):
        return False

    print("[+] Generating self-signed SSL certificates for HTTPS...")
    try:
        cmd = [
            "openssl", "req", "-x509", "-nodes", "-days", "365",
            "-newkey", "rsa:2048",
            "-keyout", KEY_FILE,
            "-out", CERT_FILE,
            "-subj", f"/CN={ip}"
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            print("[+] SSL certificates created successfully (cert.pem & key.pem).")
            return True
    except Exception:
        pass
    return False


def main():
    print("=" * 60)
    print("           PiPlayer Music System & Controller")
    print("=" * 60)

    local_ip = get_local_ip()
    use_ssl = ensure_ssl_certs(local_ip)

    # Determine port: 443 for HTTPS if root/setcap available, else 8443 / 8000
    port = int(os.environ.get("PORT", "8000"))
    if use_ssl and os.environ.get("USE_DEFAULT_HTTPS_PORT") == "1":
        port = 443

    protocol = "https" if (use_ssl and os.path.exists(CERT_FILE)) else "http"

    print(f"\n[+] Local Access URL:    {protocol}://localhost:{port}")
    print(f"[+] Network Access URL:  {protocol}://{local_ip}:{port}")
    if port != 443 and port != 80:
        print(f"[+] Direct Browser URL:  {protocol}://{local_ip}:{port}")
    print(f"[+] IP Web Interface:    {protocol}://192.168.18.159:{port}\n")

    sys.path.insert(0, BACKEND_DIR)
    sys.path.insert(0, PROJECT_ROOT)
    from backend.main import app

    kwargs = {
        "host": "0.0.0.0",
        "port": port,
        "reload": False
    }

    if use_ssl and os.path.exists(CERT_FILE) and os.path.exists(KEY_FILE):
        kwargs["ssl_keyfile"] = KEY_FILE
        kwargs["ssl_certfile"] = CERT_FILE
        print("[+] HTTPS SSL Enabled!")

    try:
        import uvicorn
        uvicorn.run(app, **kwargs)
    except KeyboardInterrupt:
        print("\n[*] Stopping PiPlayer...")
    except Exception as e:
        print(f"\n[!] Error starting server: {e}")


if __name__ == "__main__":
    main()
