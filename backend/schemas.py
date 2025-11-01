from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List
from datetime import datetime
from enum import Enum
import re

# Enums
class DeviceStatus(str, Enum):
    connected = "connected"
    offline = "offline"
    error = "error"

class NotificationType(str, Enum):
    critical = "critical"
    warning = "warning"
    info = "info"
    success = "success"

class IrrigationMode(str, Enum):
    manual = "manual"
    automation = "automation"
    emergency_stop = "emergency_stop"

class IrrigationStatus(str, Enum):
    queued = "queued"
    sent = "sent"
    executing = "executing"
    completed = "completed"
    failed = "failed"

# Authentication Schemas
class UserRegister(BaseModel):
    email: EmailStr
    phone: str
    password: str
    name: str
    language: str = "en"

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        # Valid Indian phone: 10 digits
        if not re.match(r"^\d{10}$", v):
            raise ValueError("Phone must be 10 digits")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain an uppercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain a number")
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class TokenRefresh(BaseModel):
    refresh_token: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    language: str
    timezone: str

    class Config:
        from_attributes = True

# Device Schemas
class DevicePairRequest(BaseModel):
    device_id: str
    field_name: str

class DeviceResponse(BaseModel):
    id: str
    device_id: str
    field_name: str
    device_type: str
    status: str
    last_sync: Optional[datetime]
    battery_level: int
    wifi_signal: int
    automation_enabled: bool

    class Config:
        from_attributes = True

class DeviceStatusResponse(BaseModel):
    device_id: str
    status: str
    last_sync: Optional[datetime]
    battery_level: int
    wifi_signal: int
    automation_enabled: bool

    class Config:
        from_attributes = True

# Sensor Data Schemas
class SensorReadingResponse(BaseModel):
    moisture: float
    temperature: float
    humidity: float
    signal_strength: int
    timestamp: datetime

    class Config:
        from_attributes = True

class SensorHistoryResponse(BaseModel):
    readings: List[SensorReadingResponse]

# Irrigation Command Schemas
class IrrigationStartRequest(BaseModel):
    device_id: str
    duration_minutes: int
    mode: str = "manual"

    @field_validator("duration_minutes")
    @classmethod
    def validate_duration(cls, v):
        if v < 5 or v > 180:
            raise ValueError("Duration must be between 5 and 180 minutes")
        return v

class IrrigationStopRequest(BaseModel):
    device_id: str

class IrrigationCommandResponse(BaseModel):
    id: str
    command_id: Optional[str] = None
    status: str
    device_id: str
    start_time: Optional[datetime]
    duration: int
    water_used: Optional[float]

    class Config:
        from_attributes = True

class IrrigationHistoryResponse(BaseModel):
    irrigations: List[IrrigationCommandResponse]

# AI Recommendation Schemas
class AIRecommendationResponse(BaseModel):
    recommended_duration: int
    recommended_time: Optional[str]
    confidence_score: float
    water_savings_percent: float
    reason: str

    class Config:
        from_attributes = True

# Notification Schemas
class NotificationResponse(BaseModel):
    id: str
    type: str
    title: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

class NotificationListResponse(BaseModel):
    notifications: List[NotificationResponse]
    total: int

# Settings Schemas
class SettingsResponse(BaseModel):
    language: str
    timezone: str
    notification_sounds_enabled: bool = True

    class Config:
        from_attributes = True

class SettingsUpdate(BaseModel):
    language: Optional[str] = None
    timezone: Optional[str] = None
    notification_sounds_enabled: Optional[bool] = None

# Generic Response Schema
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None
