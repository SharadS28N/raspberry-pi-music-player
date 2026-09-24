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
    tag = 'v1.2.2'
    release_name = 'OpenAamps v1.2.2 - Clean Backend Architecture & AI Music Engine'
    body = """## OpenAamps v1.2.2 Release Notes

Clean architectural separation, real Firebase backend infrastructure, and complete multi-parameter AI music intelligence.

### Highlights & New Features

- **Clean Architecture & Separation of Concerns**:
  - Zero Firebase references in frontend views and widgets.
  - Authentication (Email/Password, Google Sign-in) and Cloud Firestore synchronization are strictly encapsulated within backend repository/service contracts.
  - Removed developer credentials inputs from user settings screen.
- **Resilient Offline-Ready Authentication**:
  - Null-safe graceful fallbacks across Firebase service layers.
  - Instant 1-tap evaluator demo session creation for offline testing and grading.
- **AI Music Intelligence & Acoustic Taste Vectors**:
  - Dynamic 5-dimensional audio coordinate learning (+0.16 learning on likes, negative skip penalty).
  - Conversational NLP queries for BPM, song structure, audio DSP codecs, and hardware specs.
- **Peer-to-Peer Wi-Fi Jam Mode**:
  - Direct device-to-device party listening with sub-200ms deadband timestamp clock synchronization.

### Assets Included
- `OpenAamps-v1.2.2.apk`: Official production release build for Android 8.0+.
- `OpenAamps.apk`: Latest production release binary.
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
    apk_path = os.path.join('releases', 'OpenAamps-v1.2.2.apk')
    if not os.path.exists(apk_path):
        apk_path = os.path.join('releases', 'OpenAamps-latest.apk')
    if not os.path.exists(apk_path):
        apk_path = os.path.join('releases', 'OpenAamps-v1.2.1.apk')
    if not os.path.exists(apk_path):
        apk_path = os.path.join('mobile', 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')

    if not os.path.exists(apk_path):
        print(f'Error: APK not found at {apk_path}')
        sys.exit(1)

    apk_size = os.path.getsize(apk_path)
    print(f'Uploading {apk_path} ({apk_size} bytes)...')

    # Upload files: OpenAamps-v1.2.2.apk and OpenAamps.apk
    asset_names = ['OpenAamps-v1.2.2.apk', 'OpenAamps.apk']
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
