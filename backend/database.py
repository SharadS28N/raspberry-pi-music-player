
import sqlite3
from typing import List, Dict, Optional
from config import DATABASE_PATH
import datetime


def get_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_database():
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT,
            url TEXT NOT NULL,
            thumbnail TEXT,
            duration INTEGER,
            source TEXT DEFAULT 'youtube',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            played_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (song_id) REFERENCES songs (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (song_id) REFERENCES songs (id),
            UNIQUE(song_id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS playlist_songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            song_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id),
            FOREIGN KEY (song_id) REFERENCES songs (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (song_id) REFERENCES songs (id)
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    """)

    conn.commit()
    conn.close()


def get_or_create_song(title: str, artist: Optional[str], url: str,
                       thumbnail: Optional[str], duration: Optional[int],
                       source: str = "youtube") -> Dict:
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM songs WHERE url = ?", (url,))
    song = cursor.fetchone()

    if song:
        conn.close()
        return dict(song)

    cursor.execute(
        "INSERT INTO songs (title, artist, url, thumbnail, duration, source) VALUES (?, ?, ?, ?, ?, ?)",
        (title, artist, url, thumbnail, duration, source)
    )
    conn.commit()
    song_id = cursor.lastrowid
    cursor.execute("SELECT * FROM songs WHERE id = ?", (song_id,))
    song = cursor.fetchone()
    conn.close()
    return dict(song)


def add_to_history(song_id: Optional[int] = None, title: Optional[str] = None,
                   artist: Optional[str] = None, url: Optional[str] = None,
                   thumbnail: Optional[str] = None, duration: Optional[int] = None):
    conn = get_connection()
    cursor = conn.cursor()

    if not song_id and url:
        song = get_or_create_song(
            title=title or "Unknown Title",
            artist=artist or "YouTube",
            url=url,
            thumbnail=thumbnail,
            duration=duration
        )
        song_id = song["id"]

    if song_id:
        cursor.execute("INSERT INTO history (song_id) VALUES (?)", (song_id,))
        conn.commit()
    conn.close()


def get_history(limit: int = 20) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT s.*, h.played_at 
        FROM history h 
        JOIN songs s ON h.song_id = s.id 
        ORDER BY h.played_at DESC 
        LIMIT ?
    """, (limit,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


def toggle_favorite(song_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM favorites WHERE song_id = ?", (song_id,))
    favorite = cursor.fetchone()

    if favorite:
        cursor.execute("DELETE FROM favorites WHERE song_id = ?", (song_id,))
        is_favorite = False
    else:
        cursor.execute("INSERT INTO favorites (song_id) VALUES (?)", (song_id,))
        is_favorite = True

    conn.commit()
    conn.close()
    return is_favorite


def is_favorite(song_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM favorites WHERE song_id = ?", (song_id,))
    favorite = cursor.fetchone()
    conn.close()
    return favorite is not None


def get_favorites() -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT s.* 
        FROM favorites f 
        JOIN songs s ON f.song_id = s.id 
        ORDER BY f.created_at DESC
    """)
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


# Playlist Helper Functions
def create_playlist(name: str) -> Dict:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO playlists (name) VALUES (?)", (name,))
    conn.commit()
    playlist_id = cursor.lastrowid
    cursor.execute("SELECT * FROM playlists WHERE id = ?", (playlist_id,))
    playlist = cursor.fetchone()
    conn.close()
    return dict(playlist)


def get_playlists() -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT p.*, COUNT(ps.id) as song_count 
        FROM playlists p 
        LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id 
        GROUP BY p.id 
        ORDER BY p.created_at DESC
    """)
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_playlist_by_id(playlist_id: int) -> Optional[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM playlists WHERE id = ?", (playlist_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None


def delete_playlist(playlist_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM playlist_songs WHERE playlist_id = ?", (playlist_id,))
    cursor.execute("DELETE FROM playlists WHERE id = ?", (playlist_id,))
    conn.commit()
    conn.close()
    return True


def add_song_to_playlist(playlist_id: int, song_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT MAX(position) as max_pos FROM playlist_songs WHERE playlist_id = ?",
        (playlist_id,)
    )
    res = cursor.fetchone()
    next_pos = (res["max_pos"] + 1) if res and res["max_pos"] is not None else 0

    cursor.execute(
        "INSERT INTO playlist_songs (playlist_id, song_id, position) VALUES (?, ?, ?)",
        (playlist_id, song_id, next_pos)
    )
    conn.commit()
    conn.close()
    return True


def remove_song_from_playlist(playlist_id: int, song_id: int) -> bool:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(
        "DELETE FROM playlist_songs WHERE playlist_id = ? AND song_id = ?",
        (playlist_id, song_id)
    )
    conn.commit()
    conn.close()
    return True


def get_playlist_songs(playlist_id: int) -> List[Dict]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT s.*, ps.position 
        FROM playlist_songs ps 
        JOIN songs s ON ps.song_id = s.id 
        WHERE ps.playlist_id = ? 
        ORDER BY ps.position ASC
    """, (playlist_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]


def get_setting(key: str, default: Optional[str] = None) -> Optional[str]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
    row = cursor.fetchone()
    conn.close()
    if row and row["value"] is not None:
        return row["value"]
    return default


def set_setting(key: str, value: str):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value", (key, str(value)))
    conn.commit()
    conn.close()


