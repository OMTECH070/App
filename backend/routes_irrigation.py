from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timezone, timedelta
import uuid

from database import get_db
from models import IrrigationCommand, Device, User
from schemas import IrrigationStartRequest, IrrigationStopRequest, IrrigationCommandResponse, IrrigationHistoryResponse
from routes_auth import get_current_user

router = APIRouter(prefix="/irrigation", tags=["irrigation"])

@router.post("/start", response_model=dict)
async def start_irrigation(
    request: IrrigationStartRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Start irrigation on a device"""
    # Verify device belongs to user
    device = db.query(Device).filter(
        Device.device_id == request.device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    # Check if device is connected
    if device.status != "connected":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Device is offline. Command will be queued for retry."
        )

    # Validate duration
    if request.duration_minutes < 5 or request.duration_minutes > 180:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Duration must be between 5 and 180 minutes"
        )

    # Create irrigation command
    command = IrrigationCommand(
        id=uuid.uuid4(),
        device_id=device.id,
        duration_minutes=request.duration_minutes,
        mode=request.mode,
        status="sent",
        start_time=datetime.now(timezone.utc)
    )
    db.add(command)
    db.commit()
    db.refresh(command)

    return {
        "command_id": str(command.id),
        "status": command.status,
        "device_id": request.device_id
    }

@router.post("/stop", response_model=dict)
async def stop_irrigation(
    request: IrrigationStopRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Stop irrigation on a device (emergency stop)"""
    # Verify device belongs to user
    device = db.query(Device).filter(
        Device.device_id == request.device_id,
        Device.user_id == current_user.id
    ).first()

    if not device:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Device not found"
        )

    # Create emergency stop command
    command = IrrigationCommand(
        id=uuid.uuid4(),
        device_id=device.id,
        duration_minutes=0,
        mode="emergency_stop",
        status="sent",
        start_time=datetime.now(timezone.utc)
    )
    db.add(command)
    db.commit()
    db.refresh(command)

    return {
        "command_id": str(command.id),
        "status": command.status
    }

@router.get("/{device_id}/history", response_model=IrrigationHistoryResponse)
async def get_irrigation_history(
    device_id: str,
    days: int = Query(7, ge=1, le=30),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get irrigation history for a device"""
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
    start_time = end_time - timedelta(days=days)

    # Get irrigation commands
    commands = db.query(IrrigationCommand).filter(
        IrrigationCommand.device_id == device.id,
        IrrigationCommand.created_at >= start_time,
        IrrigationCommand.created_at <= end_time
    ).order_by(desc(IrrigationCommand.created_at)).all()

    return IrrigationHistoryResponse(
        irrigations=[
            {
                "id": str(cmd.id),
                "status": cmd.status,
                "device_id": device_id,
                "start_time": cmd.start_time,
                "duration": cmd.duration_minutes,
                "water_used": cmd.water_used_liters
            }
            for cmd in commands
        ]
    )
