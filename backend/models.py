from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text, Index
from sqlalchemy.dialects.postgresql import UUID, TIMESTAMP
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=False)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(255), nullable=False)
    language = Column(String(5), default="en", nullable=False)  # en, hi, mr
    timezone = Column(String(50), default="UTC", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    devices = relationship("Device", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")


class Device(Base):
    __tablename__ = "devices"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    device_id = Column(String(50), unique=True, nullable=False, index=True)
    field_name = Column(String(255), nullable=False)
    device_type = Column(String(50), default="ESP32-V1")
    status = Column(String(20), default="offline")  # connected, offline, error
    last_sync = Column(DateTime(timezone=True), nullable=True)
    battery_level = Column(Integer, default=100)  # 0-100
    wifi_signal = Column(Integer, default=-50)  # 0 to -100 dBm
    automation_enabled = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="devices")
    sensor_readings = relationship("SensorReading", back_populates="device", cascade="all, delete-orphan")
    irrigation_commands = relationship("IrrigationCommand", back_populates="device", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="device", cascade="all, delete-orphan")
    ai_recommendations = relationship("AIRecommendation", back_populates="device", cascade="all, delete-orphan")


class SensorReading(Base):
    __tablename__ = "sensor_readings"
    __table_args__ = (
        Index("idx_device_time", "device_id", "time"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    time = Column(DateTime(timezone=True), nullable=False, index=True)  # For TimescaleDB hypertable
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=False, index=True)
    moisture = Column(Float, nullable=False)  # 0-100%
    temperature = Column(Float, nullable=False)  # Celsius
    humidity = Column(Float, nullable=False)  # 0-100%
    signal_strength = Column(Integer, nullable=False)  # -100 to 0 dBm

    # Relationships
    device = relationship("Device", back_populates="sensor_readings")


class IrrigationCommand(Base):
    __tablename__ = "irrigation_commands"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=False, index=True)
    duration_minutes = Column(Integer, nullable=False)
    start_time = Column(DateTime(timezone=True), nullable=True)
    end_time = Column(DateTime(timezone=True), nullable=True)
    mode = Column(String(20), nullable=False)  # manual, automation, emergency_stop
    status = Column(String(20), default="queued")  # queued, sent, executing, completed, failed
    water_used_liters = Column(Float, nullable=True)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    device = relationship("Device", back_populates="irrigation_commands")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=True, index=True)
    type = Column(String(20), nullable=False)  # critical, warning, info, success
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    action_type = Column(String(50), nullable=True)  # water_now, check_device, view_recommendation
    is_read = Column(Boolean, default=False)
    is_dismissed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="notifications")
    device = relationship("Device", back_populates="notifications")


class AIRecommendation(Base):
    __tablename__ = "ai_recommendations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    device_id = Column(UUID(as_uuid=True), ForeignKey("devices.id"), nullable=False, index=True)
    recommended_moisture_level = Column(Integer, nullable=False)  # e.g., 50-70
    recommended_duration_minutes = Column(Integer, nullable=False)
    recommended_time = Column(String(5), nullable=True)  # HH:MM format
    confidence_score = Column(Float, nullable=False)  # 0-100
    water_savings_percent = Column(Float, nullable=False)
    reason = Column(Text, nullable=False)  # Explanation in user's language
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    valid_until = Column(DateTime(timezone=True), nullable=False)

    # Relationships
    device = relationship("Device", back_populates="ai_recommendations")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    token = Column(String(500), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="refresh_tokens")
