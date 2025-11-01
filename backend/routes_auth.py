from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timezone, timedelta
import uuid

from database import get_db
from models import User, RefreshToken
from schemas import UserRegister, UserLogin, TokenRefresh, TokenResponse, UserResponse
from utils_auth import hash_password, verify_password, create_access_token, create_refresh_token, decode_token, get_user_id_from_token
from config import get_settings

router = APIRouter(prefix="/auth", tags=["authentication"])
settings = get_settings()

@router.post("/register", response_model=TokenResponse)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if email already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    try:
        # Create new user
        new_user = User(
            id=uuid.uuid4(),
            email=user_data.email,
            phone=user_data.phone,
            password_hash=hash_password(user_data.password),
            name=user_data.name,
            language=user_data.language
        )
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        # Create tokens
        access_token = create_access_token({"user_id": str(new_user.id)})
        refresh_token_str = create_refresh_token(str(new_user.id))

        # Store refresh token in database
        refresh_token_record = RefreshToken(
            id=uuid.uuid4(),
            user_id=new_user.id,
            token=refresh_token_str,
            expires_at=datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
        )
        db.add(refresh_token_record)
        db.commit()

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token_str
        )
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User registration failed"
        )

@router.post("/login", response_model=TokenResponse)
async def login(user_data: UserLogin, db: Session = Depends(get_db)):
    """Login user"""
    user = db.query(User).filter(User.email == user_data.email).first()

    if not user or not verify_password(user_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

    # Create tokens
    access_token = create_access_token({"user_id": str(user.id)})
    refresh_token_str = create_refresh_token(str(user.id))

    # Store refresh token in database
    refresh_token_record = RefreshToken(
        id=uuid.uuid4(),
        user_id=user.id,
        token=refresh_token_str,
        expires_at=datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    )
    db.add(refresh_token_record)
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token_str
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(token_data: TokenRefresh, db: Session = Depends(get_db)):
    """Refresh access token using refresh token"""
    # Verify refresh token
    refresh_token_record = db.query(RefreshToken).filter(
        RefreshToken.token == token_data.refresh_token
    ).first()

    if not refresh_token_record or refresh_token_record.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token expired or invalid"
        )

    # Create new tokens
    user_id = str(refresh_token_record.user_id)
    access_token = create_access_token({"user_id": user_id})
    new_refresh_token = create_refresh_token(user_id)

    # Update refresh token in database
    refresh_token_record.token = new_refresh_token
    refresh_token_record.expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    db.commit()

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token
    )

@router.post("/logout")
async def logout(token_data: TokenRefresh, db: Session = Depends(get_db)):
    """Logout user by invalidating refresh token"""
    refresh_token_record = db.query(RefreshToken).filter(
        RefreshToken.token == token_data.refresh_token
    ).first()

    if refresh_token_record:
        db.delete(refresh_token_record)
        db.commit()

    return {"success": True, "message": "Logged out successfully"}

# Dependency to get current user
async def get_current_user(authorization: str = None, db: Session = Depends(get_db)) -> User:
    """Get current user from JWT token"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header"
        )

    try:
        token = authorization.split(" ")[1]  # Extract token from "Bearer {token}"
    except IndexError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header"
        )

    user_id = get_user_id_from_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )

    return user
