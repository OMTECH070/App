from datetime import datetime, timedelta, timezone
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from config import get_settings

settings = get_settings()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    """Hash a password using bcrypt"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against its hash"""
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)

    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm="HS256")
    return encoded_jwt

def create_refresh_token(user_id: str) -> str:
    """Create a JWT refresh token"""
    to_encode = {"user_id": str(user_id), "type": "refresh"}
    expire = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.secret_key, algorithm="HS256")
    return encoded_jwt

def decode_token(token: str) -> Optional[dict]:
    """Decode and validate a JWT token"""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=["HS256"])
        return payload
    except JWTError:
        return None

def get_user_id_from_token(token: str) -> Optional[str]:
    """Extract user ID from token"""
    payload = decode_token(token)
    if payload:
        return payload.get("user_id")
    return None
