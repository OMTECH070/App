from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timezone, timedelta

from database import get_db
from models import Notification, User
from schemas import NotificationListResponse
from routes_auth import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/", response_model=NotificationListResponse)
async def get_notifications(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    type: str = Query("all"),  # all, critical, warning, info, success
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get notifications for current user"""
    query = db.query(Notification).filter(Notification.user_id == current_user.id)

    # Filter by type
    if type != "all":
        query = query.filter(Notification.type == type)

    # Get total count
    total = query.count()

    # Get paginated results
    notifications = query.order_by(desc(Notification.created_at)).offset(offset).limit(limit).all()

    return NotificationListResponse(
        notifications=[
            {
                "id": str(notif.id),
                "type": notif.type,
                "title": notif.title,
                "message": notif.message,
                "is_read": notif.is_read,
                "created_at": notif.created_at
            }
            for notif in notifications
        ],
        total=total
    )

@router.put("/{notification_id}/read")
async def mark_as_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark notification as read"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )

    notification.is_read = True
    notification.updated_at = datetime.now(timezone.utc)
    db.commit()

    return {"success": True, "message": "Marked as read"}

@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a notification"""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()

    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )

    db.delete(notification)
    db.commit()

    return {"success": True, "message": "Notification deleted"}

@router.delete("/")
async def delete_notifications_bulk(
    older_than_days: int = Query(30, ge=1),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete old notifications"""
    cutoff_date = datetime.now(timezone.utc) - timedelta(days=older_than_days)

    deleted_count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.created_at < cutoff_date,
        Notification.is_read == True
    ).delete()

    db.commit()

    return {"deleted_count": deleted_count}
