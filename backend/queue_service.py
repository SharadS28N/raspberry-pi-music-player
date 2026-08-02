
from typing import List, Dict, Optional
import database
import sqlite3


_queue_cache: List[Dict] = []


def get_queue() -> List[Dict]:
    global _queue_cache
    conn = database.get_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT q.id, q.position, q.added_at, s.*
        FROM queue q
        JOIN songs s ON q.song_id = s.id
        ORDER BY q.position ASC
    """)
    rows = cursor.fetchall()
    _queue_cache = [dict(row) for row in rows]
    conn.close()
    return _queue_cache


def add_to_queue(song: Dict) -> Dict:
    conn = database.get_connection()
    cursor = conn.cursor()

    db_song = database.get_or_create_song(
        title=song.get("title"),
        artist=song.get("artist"),
        url=song.get("url"),
        thumbnail=song.get("thumbnail"),
        duration=song.get("duration"),
    )

    cursor.execute("SELECT MAX(position) FROM queue")
    max_pos = cursor.fetchone()[0]
    new_position = (max_pos or -1) + 1

    cursor.execute(
        "INSERT INTO queue (song_id, position) VALUES (?, ?)",
        (db_song["id"], new_position)
    )
    conn.commit()
    queue_id = cursor.lastrowid
    conn.close()

    return {**db_song, "queue_id": queue_id, "position": new_position}


def remove_from_queue(queue_id: int):
    conn = database.get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM queue WHERE id = ?", (queue_id,))
    conn.commit()
    conn.close()


def clear_queue():
    conn = database.get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM queue")
    conn.commit()
    conn.close()


def reorder_queue(queue_id: int, new_position: int):
    conn = database.get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT position FROM queue WHERE id = ?", (queue_id,))
    old_pos_row = cursor.fetchone()
    if not old_pos_row:
        conn.close()
        return
    old_position = old_pos_row[0]

    if old_position < new_position:
        cursor.execute("""
            UPDATE queue 
            SET position = position - 1 
            WHERE position > ? AND position <= ?
        """, (old_position, new_position))
    elif old_position > new_position:
        cursor.execute("""
            UPDATE queue 
            SET position = position + 1 
            WHERE position >= ? AND position < ?
        """, (new_position, old_position))

    cursor.execute("UPDATE queue SET position = ? WHERE id = ?", (new_position, queue_id))
    conn.commit()
    conn.close()


def pop_next_song() -> Optional[Dict]:
    queue = get_queue()
    if queue:
        first_song = queue[0]
        remove_from_queue(first_song["id"])
        return first_song
    return None
