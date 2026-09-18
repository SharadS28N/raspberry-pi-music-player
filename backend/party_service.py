import time
import random
import string
from typing import Dict, List, Optional, Any
from pydantic import BaseModel


class PartyMember(BaseModel):
    id: str
    name: str
    avatar_url: str
    device_name: str
    role: str = "listener"  # "host", "dj", "listener"
    is_online: bool = True
    joined_at: float = 0.0


class PartyTrack(BaseModel):
    id: str
    title: str
    artist: str
    thumbnail: str = ""
    duration: int = 0
    added_by: str = ""
    added_by_name: str = ""
    votes: int = 0
    voted_members: List[str] = []


class PartyRoom(BaseModel):
    room_code: str
    host_id: str
    host_name: str
    allow_collaborative_dj: bool = True
    current_track: Optional[PartyTrack] = None
    is_playing: bool = False
    position_ms: int = 0
    server_timestamp_ms: int = 0
    version: int = 1
    members: Dict[str, PartyMember] = {}
    queue: List[PartyTrack] = []
    created_at: float = 0.0


class PartyManager:
    def __init__(self):
        self.rooms: Dict[str, PartyRoom] = {}

    def _generate_room_code(self) -> str:
        chars = string.ascii_uppercase + string.digits
        # e.g., JAM-4821 or 6-digit room code
        digits = ''.join(random.choices(string.digits, k=4))
        prefix = random.choice(["JAM", "SYNC", "PLAY", "BEAT"])
        return f"{prefix}-{digits}"

    def create_room(
        self,
        host_id: str,
        host_name: str,
        device_name: str = "Android Device",
        avatar_url: str = "",
        initial_track: Optional[Dict[str, Any]] = None,
    ) -> PartyRoom:
        room_code = self._generate_room_code()
        while room_code in self.rooms:
            room_code = self._generate_room_code()

        now = time.time()
        now_ms = int(now * 1000)

        host_member = PartyMember(
            id=host_id,
            name=host_name,
            avatar_url=avatar_url or "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
            device_name=device_name,
            role="host",
            is_online=True,
            joined_at=now,
        )

        track_obj = None
        if initial_track:
            track_obj = PartyTrack(
                id=initial_track.get("id", ""),
                title=initial_track.get("title", "Unknown Track"),
                artist=initial_track.get("artist", "Unknown Artist"),
                thumbnail=initial_track.get("thumbnail", ""),
                duration=int(initial_track.get("duration", 0)),
                added_by=host_id,
                added_by_name=host_name,
            )

        room = PartyRoom(
            room_code=room_code,
            host_id=host_id,
            host_name=host_name,
            allow_collaborative_dj=True,
            current_track=track_obj,
            is_playing=track_obj is not None,
            position_ms=0,
            server_timestamp_ms=now_ms,
            version=1,
            members={host_id: host_member},
            queue=[],
            created_at=now,
        )

        self.rooms[room_code] = room
        return room

    def get_room(self, room_code: str) -> Optional[PartyRoom]:
        return self.rooms.get(room_code.upper())

    def join_room(
        self,
        room_code: str,
        member_id: str,
        member_name: str,
        device_name: str = "Android Device",
        avatar_url: str = "",
    ) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        now = time.time()
        if member_id in room.members:
            # Reconnect existing member
            m = room.members[member_id]
            m.is_online = True
            m.name = member_name
            m.device_name = device_name
            if avatar_url:
                m.avatar_url = avatar_url
        else:
            role = "dj" if room.allow_collaborative_dj else "listener"
            room.members[member_id] = PartyMember(
                id=member_id,
                name=member_name,
                avatar_url=avatar_url or "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150",
                device_name=device_name,
                role=role,
                is_online=True,
                joined_at=now,
            )

        return room

    def leave_room(self, room_code: str, member_id: str) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        if member_id in room.members:
            del room.members[member_id]

        # If room is now empty, cleanup
        if not room.members:
            del self.rooms[room.room_code]
            return None

        # If host left, transfer host to next active member
        if room.host_id == member_id:
            next_host = next(iter(room.members.values()))
            next_host.role = "host"
            room.host_id = next_host.id
            room.host_name = next_host.name

        return room

    def update_playback(
        self,
        room_code: str,
        sender_id: str,
        is_playing: bool,
        position_ms: int,
        track_dict: Optional[Dict[str, Any]] = None,
    ) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        # Check permissions: host or collaborative dj
        sender = room.members.get(sender_id)
        if not sender:
            return None

        if not (sender.role in ["host", "dj"] or room.allow_collaborative_dj):
            return None

        now_ms = int(time.time() * 1000)
        room.is_playing = is_playing
        room.position_ms = max(0, position_ms)
        room.server_timestamp_ms = now_ms
        room.version += 1

        if track_dict:
            room.current_track = PartyTrack(
                id=track_dict.get("id", ""),
                title=track_dict.get("title", "Unknown Track"),
                artist=track_dict.get("artist", "Unknown Artist"),
                thumbnail=track_dict.get("thumbnail", ""),
                duration=int(track_dict.get("duration", 0)),
                added_by=sender_id,
                added_by_name=sender.name,
            )

        return room

    def add_to_queue(
        self,
        room_code: str,
        sender_id: str,
        track_dict: Dict[str, Any],
    ) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        sender = room.members.get(sender_id)
        sender_name = sender.name if sender else "Party Member"

        track = PartyTrack(
            id=track_dict.get("id", ""),
            title=track_dict.get("title", "Unknown Track"),
            artist=track_dict.get("artist", "Unknown Artist"),
            thumbnail=track_dict.get("thumbnail", ""),
            duration=int(track_dict.get("duration", 0)),
            added_by=sender_id,
            added_by_name=sender_name,
            votes=1,
            voted_members=[sender_id],
        )

        # If no track currently playing, immediately play it
        if room.current_track is None:
            room.current_track = track
            room.is_playing = True
            room.position_ms = 0
            room.server_timestamp_ms = int(time.time() * 1000)
            room.version += 1
        else:
            # Append to queue
            room.queue.append(track)
            self._sort_queue_by_votes(room)

        return room

    def vote_queue_track(
        self,
        room_code: str,
        sender_id: str,
        track_id: str,
    ) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        for t in room.queue:
            if t.id == track_id:
                if sender_id in t.voted_members:
                    t.voted_members.remove(sender_id)
                    t.votes = max(0, t.votes - 1)
                else:
                    t.voted_members.append(sender_id)
                    t.votes += 1
                break

        self._sort_queue_by_votes(room)
        return room

    def skip_to_next(self, room_code: str, sender_id: str) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room:
            return None

        if room.queue:
            next_track = room.queue.pop(0)
            room.current_track = next_track
            room.is_playing = True
            room.position_ms = 0
            room.server_timestamp_ms = int(time.time() * 1000)
            room.version += 1
        else:
            room.is_playing = False
            room.position_ms = 0
            room.server_timestamp_ms = int(time.time() * 1000)
            room.version += 1

        return room

    def _sort_queue_by_votes(self, room: PartyRoom):
        # High votes first, preserving addition order
        room.queue.sort(key=lambda t: t.votes, reverse=True)

    def set_dj_mode(self, room_code: str, sender_id: str, allow_collaborative_dj: bool) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room or room.host_id != sender_id:
            return None

        room.allow_collaborative_dj = allow_collaborative_dj
        for m in room.members.values():
            if m.role != "host":
                m.role = "dj" if allow_collaborative_dj else "listener"
        return room

    def transfer_host(self, room_code: str, sender_id: str, new_host_id: str) -> Optional[PartyRoom]:
        room = self.get_room(room_code)
        if not room or room.host_id != sender_id:
            return None

        if new_host_id in room.members:
            old_host = room.members[sender_id]
            old_host.role = "dj"
            new_host = room.members[new_host_id]
            new_host.role = "host"
            room.host_id = new_host.id
            room.host_name = new_host.name
            return room
        return None


party_manager = PartyManager()
