import sys
import os
import unittest
from fastapi.testclient import TestClient

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(PROJECT_ROOT, "backend"))
sys.path.insert(0, PROJECT_ROOT)

from backend.main import app

class TestPiPlayerAPI(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_root(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)

    def test_bluetooth_status(self):
        response = self.client.get("/api/bluetooth/status")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("powered", data)
        self.assertIn("adapter", data)

    def test_bluetooth_power_toggle(self):
        response = self.client.post("/api/bluetooth/power", json={"power": True})
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["powered"])

    def test_bluetooth_mode_toggle(self):
        response = self.client.post("/api/bluetooth/mode", json={"mode": "receiver"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["mode"], "receiver")

    def test_lyrics_api(self):
        response = self.client.get("/api/lyrics?title=Bohemian%20Rhapsody&artist=Queen")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("status", data)
        self.assertIn("track", data)

    def test_audio_outputs(self):
        response = self.client.get("/api/audio/outputs")
        self.assertEqual(response.status_code, 200)
        outputs = response.json()
        self.assertTrue(len(outputs) > 0)

    def test_audio_output_switch(self):
        response = self.client.post("/api/audio/output", json={"output": "hdmi"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["active_output"], "hdmi")

    def test_master_volume(self):
        response = self.client.post("/api/audio/master-volume", json={"volume": 75})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["volume"], 75)

    def test_playlists_api(self):
        # Create playlist
        res = self.client.post("/api/playlists", json={"name": "Test Party Mix"})
        self.assertEqual(res.status_code, 200)
        playlist = res.json()
        playlist_id = playlist["id"]
        self.assertEqual(playlist["name"], "Test Party Mix")

        # List playlists
        res = self.client.get("/api/playlists")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(any(p["id"] == playlist_id for p in res.json()))

        # Add song to playlist
        res = self.client.post(f"/api/playlists/{playlist_id}/songs", json={
            "url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "title": "Never Gonna Give You Up",
            "artist": "Rick Astley"
        })
        self.assertEqual(res.status_code, 200)

        # Get playlist details with songs
        res = self.client.get(f"/api/playlists/{playlist_id}")
        self.assertEqual(res.status_code, 200)
        p_data = res.json()
        self.assertEqual(len(p_data["songs"]), 1)
        self.assertEqual(p_data["songs"][0]["title"], "Never Gonna Give You Up")

        # Delete playlist
        res = self.client.delete(f"/api/playlists/{playlist_id}")
        self.assertEqual(res.status_code, 200)

    def test_autoplay_api(self):
        res = self.client.get("/api/autoplay/status")
        self.assertEqual(res.status_code, 200)
        self.assertIn("enabled", res.json())

        res = self.client.post("/api/autoplay/toggle", json={"enabled": False})
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.json()["enabled"])

        res = self.client.post("/api/autoplay/toggle", json={"enabled": True})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.json()["enabled"])

    def test_sleep_timer_api(self):
        res = self.client.post("/api/sleep-timer", json={"minutes": 15, "mode": "duration"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["sleep_timer"], 15)

        res = self.client.post("/api/sleep-timer", json={"minutes": 0, "mode": "end_of_track"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["mode"], "end_of_track")

    def test_settings_and_port_api(self):
        res = self.client.get("/api/settings")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("port", data)
        self.assertIn("version", data)

        res = self.client.post("/api/settings/port", json={"port": 8080})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["port"], 8080)

        res = self.client.post("/api/settings/port", json={"port": 8000})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["port"], 8000)

    def test_updates_api(self):
        res = self.client.get("/api/updates/check")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("current_version", data)
        self.assertIn("changelog", data)

    def test_system_metrics_api(self):
        res = self.client.get("/api/system/metrics")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("cpu_usage_percent", data)
        self.assertIn("memory", data)
        self.assertIn("dacs", data)

    def test_system_customization_api(self):
        res = self.client.post("/api/system/customize", json={
            "bluetooth_name": "pi-aamps Hi-Fi Speaker",
            "hostname": "pi-aamps-studio"
        })
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["customization"]["bluetooth_name"], "pi-aamps Hi-Fi Speaker")
        self.assertEqual(res.json()["customization"]["hostname"], "pi-aamps-studio")

    def test_custom_equalizer_api(self):
        res = self.client.post("/api/equalizer/bands", json={
            "bands": {"62": 3, "250": -1, "1000": 2, "4000": 4}
        })
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["equalizer"], "custom")

    def test_hifi_status_and_toggle_api(self):
        res = self.client.get("/api/hifi/status")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("roon", data)
        self.assertIn("airplay", data)

        res = self.client.post("/api/hifi/toggle", json={"service": "roon", "enable": True})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["service"], "roon")

    def test_reset_database_api(self):
        res = self.client.post("/api/system/reset-db")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.json()["status"], "ok")


if __name__ == "__main__":
    unittest.main()


