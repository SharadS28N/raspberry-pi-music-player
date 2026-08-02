
import paramiko

# Configuration
PI_HOST = "192.168.18.159"
PI_USER = "aamps"
PI_PASS = "aamps"

print("=== Checking PiPlayer Status ===")

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    ssh.connect(PI_HOST, username=PI_USER, password=PI_PASS)
    print("Connected to Raspberry Pi!")
    
    # Check mpv status
    print("\n--- mpv Service Status ---")
    stdin, stdout, stderr = ssh.exec_command("sudo systemctl status mpv.service", get_pty=True)
    stdin.write(PI_PASS + "\n")
    stdin.flush()
    print(stdout.read().decode())
    
    # Check piplayer status
    print("\n--- PiPlayer Service Status ---")
    stdin, stdout, stderr = ssh.exec_command("sudo systemctl status piplayer.service", get_pty=True)
    stdin.write(PI_PASS + "\n")
    stdin.flush()
    print(stdout.read().decode())
    
    # Check piplayer logs
    print("\n--- PiPlayer Logs ---")
    stdin, stdout, stderr = ssh.exec_command("sudo journalctl -u piplayer.service -n 50", get_pty=True)
    stdin.write(PI_PASS + "\n")
    stdin.flush()
    print(stdout.read().decode())
    
finally:
    ssh.close()
