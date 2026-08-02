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


if __name__ == "__main__":
    unittest.main()
