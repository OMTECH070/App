from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone
import uuid

from database import get_db
from models import Device, User
from schemas import DevicePairRequest, DeviceResponse
from routes_auth import get_current_user

router = APIRouter(prefix="/devices", tags=["devices"])

@router.post("/pair", response_model=dict)
async def pair_device(
    device_data: DevicePairRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Pair a new device to user account"""
    # Check if device already paired
    existing_device = db.query(Device).filter(Device.device_id == device_data.device_id).first()
    if existing_device:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Device already paired to another user"
        )

    # Validate device_id format (e.g., ESP32-XXXX)
    if not device_data.device_id or len(device_data.device_id) < 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid device ID format"
        )

    # Create pairing code (6 digits)
    pairing_code = str(uuid.uuid4())[:6].upper()

    # Create new device
    new_device = Device(
        id=uuid.uuid4(),
        user_id=current_user.id,
        device_id=device_data.device_id,
        field_name=device_data.field_name,
        status="offline"
    )
    db.add(new_device)
    db.commit()

    return {
        "device_id": new_device.device_id,
        "pairing_code": pairing_code,
        "pairing_code_expires_in_seconds": 300
    }

@router.get("/", response_model=dict)
async def get_devices(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all devices for current user"""
    devices = db.query(Device).filter(Device.user_id == current_user.id).all()

    return {
        "devices": [
            {
                "id": str(device.id),
                "device_id": device.device_id,
                "field_name": device.field_name,
                "status": device.status,
                "last_sync": device.last_sync,
                "battery_level": device.battery_level,
                "automation_enabled": device.automation_enabled
            }
            for device in devices
        ]
    }

@router.get("/{device_id}/status", response_model=DeviceResponse)
async def get_device_status(
    device_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get device status"""
    device = db.query(Device).filter(
        Device.device_id == device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    return DeviceResponse(
        id=str(device.id),
        device_id=device.device_id,
        field_name=device.field_name,
        device_type=device.device_type,
        status=device.status,
        last_sync=device.last_sync,
        battery_level=device.battery_level,
        wifi_signal=device.wifi_signal,
        automation_enabled=device.automation_enabled
    )

@router.delete("/{device_id}")
async def delete_device(
    device_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete/unpair a device"""
    device = db.query(Device).filter(
        Device.device_id == device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    # Delete device (cascade will delete related data)
    db.delete(device)
    db.commit()

    return {"success": True, "message": "Device unpaired successfully"}
