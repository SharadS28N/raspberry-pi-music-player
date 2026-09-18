from fastapi import WebSocket, WebSocketDisconnect
from typing import List, Dict
import json
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []
        self.room_connections: Dict[str, List[WebSocket]] = {}

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info("New WebSocket connection")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        # Also cleanup from room_connections
        for room_code, connections in list(self.room_connections.items()):
            if websocket in connections:
                connections.remove(websocket)
                if not connections:
                    del self.room_connections[room_code]
        logger.info("WebSocket disconnected")

    async def broadcast(self, message: Dict):
        for connection in list(self.active_connections):
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting message: {e}")
                self.disconnect(connection)

    async def connect_room(self, websocket: WebSocket, room_code: str):
        await websocket.accept()
        code = room_code.upper()
        if code not in self.room_connections:
            self.room_connections[code] = []
        self.room_connections[code].append(websocket)
        logger.info(f"WebSocket connected to party room: {code}")

    def disconnect_room(self, websocket: WebSocket, room_code: str):
        code = room_code.upper()
        if code in self.room_connections and websocket in self.room_connections[code]:
            self.room_connections[code].remove(websocket)
            if not self.room_connections[code]:
                del self.room_connections[code]
        logger.info(f"WebSocket disconnected from party room: {code}")

    async def broadcast_to_room(self, room_code: str, message: Dict):
        code = room_code.upper()
        if code in self.room_connections:
            for connection in list(self.room_connections[code]):
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error broadcasting to party room {code}: {e}")
                    self.disconnect_room(connection, code)


manager = ConnectionManager()


async def broadcast_state_update(state_type: str, data: Dict):
    await manager.broadcast({
        "type": state_type,
        "data": data
    })
