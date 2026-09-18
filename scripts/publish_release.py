import os
import sys
import json
import subprocess
import urllib.request
import urllib.parse

def get_github_token():
    p = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    out, _ = p.communicate('protocol=https\nhost=github.com\n\n')
    creds = dict([line.split('=', 1) for line in out.splitlines() if '=' in line])
    return creds.get('password', '')

def main():
    token = get_github_token()
    if not token:
        print('Error: Could not retrieve GitHub token from git credentials')
        sys.exit(1)

    repo = 'SharadS28N/raspberry-pi-music-player'
    tag = 'v1.2.0'
    release_name = 'OpenAamps v1.2.0 - Android Music Player'
    body = """## OpenAamps v1.2.0 Release Notes

Standalone Android companion music player and Raspberry Pi Hi-Fi streaming controller.

### Highlights & New Features

- **Genuine Spotify & YouTube / Google Account Sync**:
  - Direct public playlist and track scraping via Spotify Embed API.
  - Authentic Google / YouTube account lookup via channel @handle with synchronized channel avatar and metadata.
- **Dynamic Mood & Genre Switching**:
  - Live dynamic track loading when toggling between Energize, Relax, Focus, Party, Workout, and Chill moods.
  - Expanded Quick Picks list with full catalogue browsing toggle.
- **Custom Player Wallpapers & Canvas Styles**:
  - 6 AMOLED presets: Deep Nebula, Cyber Noir, Velvet Night, Pure Black, Album Art Blur, and Dark Gradient.
  - Custom user wallpaper URL input with seamless modern player layout.
- **Live Music Recognition with Humming / Lyrics Fallback**:
  - Reactive state binding for audio recognition with instant single-tap playback.
- **Discord Rich Presence (RPC)**:
  - Integrated native Discord IPC over named pipes to display real-time song title, artist, duration, elapsed timestamps, and album art on active Discord desktop clients.
- **Library Overhaul & Custom Playlists**:
  - Removed placeholder files, connected smart playlists (Liked Tracks, Recently Played, Downloads) to persistent storage, and added custom playlist creation.
- **Audio Engine Stability**:
  - YouTube 403 Forbidden rate-bypass streaming with multi-layer fallback.
  - Full Android 13+ background audio service and media notification session support.

### Assets Included
- `OpenAamps-v1.2.0.apk`: Official production release build for Android 8.0+.
"""

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'OpenAamps-Release-Publisher',
        'Content-Type': 'application/json'
    }

    # Check if release already exists
    check_url = f'https://api.github.com/repos/{repo}/releases/tags/{tag}'
    req = urllib.request.Request(check_url, headers=headers)
    release_data = None
    try:
        with urllib.request.urlopen(req) as resp:
            release_data = json.loads(resp.read().decode('utf-8'))
            print(f'Release {tag} already exists with ID: {release_data.get("id")}')
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f'Release {tag} does not exist yet. Creating...')
        else:
            print(f'Error checking release: {e}')
            sys.exit(1)

    if not release_data:
        payload = {
            'tag_name': tag,
            'target_commitish': 'main',
            'name': release_name,
            'body': body,
            'draft': False,
            'prerelease': False
        }
        create_url = f'https://api.github.com/repos/{repo}/releases'
        req = urllib.request.Request(create_url, data=json.dumps(payload).encode('utf-8'), headers=headers, method='POST')
        try:
            with urllib.request.urlopen(req) as resp:
                release_data = json.loads(resp.read().decode('utf-8'))
                print(f'Created release {tag} with ID: {release_data.get("id")}')
        except Exception as e:
            print(f'Error creating release: {e}')
            sys.exit(1)

    release_id = release_data.get('id')
    apk_path = os.path.join('releases', 'OpenAamps-v1.2.0.apk')
    if not os.path.exists(apk_path):
        apk_path = os.path.join('mobile', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')

    if not os.path.exists(apk_path):
        print(f'Error: APK not found at {apk_path}')
        sys.exit(1)

    apk_size = os.path.getsize(apk_path)
    print(f'Uploading {apk_path} ({apk_size} bytes)...')

    # Upload files: OpenAamps-v1.2.0.apk and OpenAamps.apk
    asset_names = ['OpenAamps-v1.2.0.apk', 'OpenAamps.apk']
    for asset_name in asset_names:
        # Delete existing asset with same name if any
        for a in release_data.get('assets', []):
            if a.get('name') == asset_name:
                print(f'Deleting old asset {asset_name} (ID: {a.get("id")})...')
                del_url = f'https://api.github.com/repos/{repo}/releases/assets/{a.get("id")}'
                del_req = urllib.request.Request(del_url, headers=headers, method='DELETE')
                try:
                    with urllib.request.urlopen(del_req) as del_resp:
                        pass
                except Exception as del_err:
                    print(f'Warning deleting asset: {del_err}')

        upload_url = f'https://uploads.github.com/repos/{repo}/releases/{release_id}/assets?name={asset_name}'
        upload_headers = {
            'Authorization': f'token {token}',
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'OpenAamps-Release-Publisher',
            'Content-Type': 'application/vnd.android.package-archive',
            'Content-Length': str(apk_size)
        }

        print(f'Uploading {asset_name} to GitHub...')
        with open(apk_path, 'rb') as f:
            upload_req = urllib.request.Request(upload_url, data=f.read(), headers=upload_headers, method='POST')
            try:
                with urllib.request.urlopen(upload_req) as up_resp:
                    up_data = json.loads(up_resp.read().decode('utf-8'))
                    print(f'Uploaded {asset_name} successfully: {up_data.get("browser_download_url")}')
            except Exception as up_err:
                print(f'Error uploading {asset_name}: {up_err}')
                sys.exit(1)

    print('All assets published successfully to GitHub release!')

if __name__ == '__main__':
    main()
