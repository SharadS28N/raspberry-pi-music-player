import time
from party_service import PartyManager, PartyTrack

def test_party_manager():
    mgr = PartyManager()
    
    # 1. Create Room
    room = mgr.create_room("host_1", "Host User", "Phone A", "https://avatar/1")
    assert any(room.room_code.startswith(p) for p in ["JAM", "SYNC", "PLAY", "BEAT"])
    assert room.host_id == "host_1"
    assert len(room.members) == 1
    assert room.members["host_1"].role == "host"
    print("[PASS] Room Creation Verified:", room.room_code)
    
    # 2. Join Room
    room = mgr.join_room(room.room_code, "user_2", "Listener Two", "Phone B", "https://avatar/2")
    assert room is not None
    assert room.members["user_2"].role in ("dj", "listener")
    assert len(room.members) == 2
    print("[PASS] Join Room Verified")
    
    # 3. Update Playback & Drift Sync Timestamps
    track_data = {
        "id": "track_123",
        "title": "Yellow",
        "artist": "Coldplay",
        "duration_ms": 269000
    }
    room = mgr.update_playback(room.room_code, "host_1", is_playing=True, position_ms=15000, track_dict=track_data)
    assert room is not None
    assert room.is_playing is True
    assert room.position_ms == 15000
    assert room.server_timestamp_ms > 0
    print("[PASS] Playback Sync & Server Epoch Timestamp Verified")
    
    # 4. Queue Operations & Upvoting
    mgr.add_to_queue(room.room_code, "user_2", {
        "id": "q_1",
        "title": "Song 1",
        "artist": "Artist 1"
    })
    mgr.add_to_queue(room.room_code, "host_1", {
        "id": "q_2",
        "title": "Song 2",
        "artist": "Artist 2"
    })
    assert len(room.queue) == 2
    
    # Upvote Song 2 so it rises to position 0
    mgr.vote_queue_track(room.room_code, "user_2", "q_2")
    assert room.queue[0].id == "q_2"
    assert room.queue[0].votes == 2
    print("[PASS] Queue Voting & Ranking Verified")
    
    # 5. Host Auto-Migration on Disconnect
    mgr.leave_room(room.room_code, "host_1")
    assert room.host_id == "user_2"
    assert room.members["user_2"].role == "host"
    print("[PASS] Host Failover Migration Verified")
    
    print("\nALL BACKEND PARTY SERVICE TESTS PASSED 100%!")

if __name__ == "__main__":
    test_party_manager()
