from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone, timedelta
import uuid

from database import get_db
from models import AIRecommendation, Device, User, IrrigationCommand
from schemas import AIRecommendationResponse
from routes_auth import get_current_user

router = APIRouter(prefix="/ai", tags=["ai"])

@router.get("/recommendation/{device_id}", response_model=AIRecommendationResponse)
async def get_ai_recommendation(
    device_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI recommendation for a device"""
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

    # Get latest recommendation (valid until its valid_until time)
    recommendation = db.query(AIRecommendation).filter(
        AIRecommendation.device_id == device.id,
        AIRecommendation.valid_until > datetime.now(timezone.utc)
    ).order_by(AIRecommendation.created_at.desc()).first()

    if not recommendation:
        # Return default recommendation if none exists
        return AIRecommendationResponse(
            recommended_duration=30,
            recommended_time="18:00",
            confidence_score=0.0,
            water_savings_percent=0.0,
            reason="No historical data available yet. Please monitor soil conditions."
        )

    return AIRecommendationResponse(
        recommended_duration=recommendation.recommended_duration_minutes,
        recommended_time=recommendation.recommended_time,
        confidence_score=recommendation.confidence_score,
        water_savings_percent=recommendation.water_savings_percent,
        reason=recommendation.reason
    )

@router.post("/recommendation/{device_id}/apply")
async def apply_ai_recommendation(
    device_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Apply AI recommendation (queue irrigation command)"""
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

    # Get latest valid recommendation
    recommendation = db.query(AIRecommendation).filter(
        AIRecommendation.device_id == device.id,
        AIRecommendation.valid_until > datetime.now(timezone.utc)
    ).order_by(AIRecommendation.created_at.desc()).first()

    if not recommendation:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid recommendation available"
        )

    # Create irrigation command from recommendation
    command = IrrigationCommand(
        id=uuid.uuid4(),
        device_id=device.id,
        duration_minutes=recommendation.recommended_duration_minutes,
        mode="automation",
        status="queued"
    )
    db.add(command)
    db.commit()
    db.refresh(command)

    return {
        "command_id": str(command.id),
        "status": command.status
    }
