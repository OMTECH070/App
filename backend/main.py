from fastapi import FastAPI, WebSocket, Depends, WebSocketDisconnect, status
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
from typing import Set

from database import engine, Base
from config import get_settings
from routes_auth import router as auth_router
from routes_devices import router as devices_router
from routes_sensors import router as sensors_router
from routes_irrigation import router as irrigation_router
from routes_notifications import router as notifications_router
from routes_settings import router as settings_router
from routes_ai import router as ai_router
from utils_auth import get_user_id_from_token

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

settings = get_settings()

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Set[WebSocket] = set()
        self.user_connections: dict = {}  # user_id -> Set[WebSocket]

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections.add(websocket)
        if user_id not in self.user_connections:
            self.user_connections[user_id] = set()
        self.user_connections[user_id].add(websocket)
        logger.info(f"Client {user_id} connected")

    def disconnect(self, websocket: WebSocket, user_id: str):
        self.active_connections.discard(websocket)
        if user_id in self.user_connections:
            self.user_connections[user_id].discard(websocket)
            if not self.user_connections[user_id]:
                del self.user_connections[user_id]
        logger.info(f"Client {user_id} disconnected")

    async def broadcast_to_user(self, user_id: str, message: dict):
        """Send message to all connections of a specific user"""
        if user_id in self.user_connections:
            for connection in self.user_connections[user_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending message to {user_id}: {e}")

    async def broadcast_to_all(self, message: dict):
        """Broadcast message to all connected users"""
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting message: {e}")

manager = ConnectionManager()

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting up application")
    # Create database tables
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created/verified")
    yield
    # Shutdown
    logger.info("Shutting down application")

# Create FastAPI app
app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(devices_router)
app.include_router(sensors_router)
app.include_router(irrigation_router)
app.include_router(notifications_router)
app.include_router(settings_router)
app.include_router(ai_router)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.api_version}

# WebSocket endpoint for real-time updates
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time updates
    Expected query param: token=JWT_TOKEN
    """
    # Get token from query params
    token = websocket.query_params.get("token")

    if not token:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="No token provided")
        return

    # Verify token and get user_id
    user_id = get_user_id_from_token(token)
    if not user_id:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
        return

    await manager.connect(websocket, user_id)

    try:
        while True:
            data = await websocket.receive_json()

            # Handle subscription messages
            if data.get("action") == "subscribe":
                device_id = data.get("device_id")
                # In a production system, you'd validate that user owns this device
                await websocket.send_json({
                    "type": "subscription_confirmed",
                    "device_id": device_id
                })

            # Handle ping/pong (keep-alive)
            elif data.get("action") == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, user_id)

# Broadcast helper function
async def broadcast_sensor_update(user_id: str, device_id: str, sensor_data: dict):
    """Broadcast sensor update to connected clients"""
    await manager.broadcast_to_user(user_id, {
        "type": "sensor_update",
        "device_id": device_id,
        "data": sensor_data,
        "timestamp": datetime.now(timezone.utc).isoformat()
    })

async def broadcast_device_status(user_id: str, device_id: str, status: str, last_sync: str):
    """Broadcast device status update to connected clients"""
    await manager.broadcast_to_user(user_id, {
        "type": "device_status",
        "device_id": device_id,
        "status": status,
        "last_sync": last_sync
    })

async def broadcast_notification(user_id: str, notification: dict):
    """Broadcast notification to connected clients"""
    await manager.broadcast_to_user(user_id, {
        "type": "notification",
        "data": notification
    })

# Import datetime for timestamp
from datetime import datetime, timezone

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        env_file=".env"
    )
