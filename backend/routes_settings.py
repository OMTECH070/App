from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timezone

from database import get_db
from models import User
from schemas import SettingsResponse, SettingsUpdate
from routes_auth import get_current_user

router = APIRouter(prefix="/settings", tags=["settings"])

@router.get("/", response_model=SettingsResponse)
async def get_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user settings"""
    # Refresh user from database to get latest data
    user = db.query(User).filter(User.id == current_user.id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    return SettingsResponse(
        language=user.language,
        timezone=user.timezone,
        notification_sounds_enabled=True  # Default for MVP
    )

@router.patch("/", response_model=SettingsResponse)
async def update_settings(
    settings_update: SettingsUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user settings"""
    user = db.query(User).filter(User.id == current_user.id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Update fields that were provided
    if settings_update.language is not None:
        if settings_update.language not in ["en", "hi", "mr"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Language must be one of: en, hi, mr"
            )
        user.language = settings_update.language

    if settings_update.timezone is not None:
        user.timezone = settings_update.timezone

    user.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    return SettingsResponse(
        language=user.language,
        timezone=user.timezone,
        notification_sounds_enabled=True
    )
