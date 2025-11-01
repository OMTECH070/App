from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from datetime import datetime, timezone, timedelta

from database import get_db
from models import SensorReading, Device, User
from schemas import SensorReadingResponse, SensorHistoryResponse
from routes_auth import get_current_user

router = APIRouter(prefix="/sensors", tags=["sensors"])

@router.get("/{device_id}/latest", response_model=SensorReadingResponse)
async def get_latest_sensor_reading(
    device_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get latest sensor reading for a device"""
    # Verify device belongs to user
    device = db.query(Device).filter(
        Device.device_id == device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    # Get latest reading
    latest_reading = db.query(SensorReading).filter(
        SensorReading.device_id == device.id
    ).order_by(desc(SensorReading.time)).first()

    if not latest_reading:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No sensor readings available"
        )

    return SensorReadingResponse(
        moisture=latest_reading.moisture,
        temperature=latest_reading.temperature,
        humidity=latest_reading.humidity,
        signal_strength=latest_reading.signal_strength,
        timestamp=latest_reading.time
    )

@router.get("/{device_id}/history", response_model=SensorHistoryResponse)
async def get_sensor_history(
    device_id: str,
    hours: int = Query(24, ge=1, le=720),  # Default 24h, max 30 days
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get sensor history for a device"""
    # Verify device belongs to user
    device = db.query(Device).filter(
        Device.device_id == device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    # Calculate time range
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(hours=hours)

    # Get readings (max 288 points = one per 5 mins for 24 hours)
    # For larger time ranges, we'll fetch and downsample
    readings = db.query(SensorReading).filter(
        SensorReading.device_id == device.id,
        SensorReading.time >= start_time,
        SensorReading.time <= end_time
    ).order_by(SensorReading.time).all()

    # Downsample if too many points
    max_points = 288
    if len(readings) > max_points:
        step = len(readings) // max_points
        readings = readings[::step]

    return SensorHistoryResponse(
        readings=[
            SensorReadingResponse(
                moisture=r.moisture,
                temperature=r.temperature,
                humidity=r.humidity,
                signal_strength=r.signal_strength,
                timestamp=r.time
            )
            for r in readings
        ]
    )
