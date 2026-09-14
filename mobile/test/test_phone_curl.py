import subprocess

with open(r'd:\Code\Projects\raspberry-pi-music-player\mobile\test\url.txt') as f:
    url = f.read().strip()

adb = r'C:\Users\shara\AppData\Local\Android\Sdk\platform-tools\adb.exe'

# Test 1: curl with no extra headers
cmd = [adb, 'shell', 'curl', '-s', '-I', url]
res = subprocess.run(cmd, capture_output=True, text=True)
print("1. Phone curl (no headers):\n", res.stdout or res.stderr)

# Test 2: curl with Range
cmd = [adb, 'shell', 'curl', '-s', '-I', '-H', 'Range: bytes=0-1024', url]
res = subprocess.run(cmd, capture_output=True, text=True)
print("2. Phone curl (Range):\n", res.stdout or res.stderr)

# Test 3: curl with Android YouTube UA
cmd = [adb, 'shell', 'curl', '-s', '-I', '-H', 'Range: bytes=0-1024', '-A', 'com.google.android.youtube/19.09.37 (Linux; U; Android 14)', url]
res = subprocess.run(cmd, capture_output=True, text=True)
print("3. Phone curl (Android YouTube UA):\n", res.stdout or res.stderr)
