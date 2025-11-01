from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
import logging

logger = logging.getLogger(__name__)

class APIException(Exception):
    """Custom exception for API errors"""
    def __init__(
        self,
        status_code: int,
        detail: str,
        error_code: str = "UNKNOWN_ERROR"
    ):
        self.status_code = status_code
        self.detail = detail
        self.error_code = error_code

class ValidationException(APIException):
    """Validation errors"""
    def __init__(self, detail: str, error_code: str = "VALIDATION_ERROR"):
        super().__init__(status.HTTP_400_BAD_REQUEST, detail, error_code)

class AuthenticationException(APIException):
    """Authentication errors"""
    def __init__(self, detail: str = "Authentication failed"):
        super().__init__(status.HTTP_401_UNAUTHORIZED, detail, "AUTH_ERROR")

class AuthorizationException(APIException):
    """Authorization errors"""
    def __init__(self, detail: str = "Not authorized"):
        super().__init__(status.HTTP_403_FORBIDDEN, detail, "AUTH_ERROR")

class ResourceNotFoundException(APIException):
    """Resource not found"""
    def __init__(self, resource: str):
        super().__init__(
            status.HTTP_404_NOT_FOUND,
            f"{resource} not found",
            "NOT_FOUND"
        )

class ConflictException(APIException):
    """Resource conflict"""
    def __init__(self, detail: str):
        super().__init__(
            status.HTTP_409_CONFLICT,
            detail,
            "CONFLICT"
        )

class RateLimitException(APIException):
    """Rate limit exceeded"""
    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(
            status.HTTP_429_TOO_MANY_REQUESTS,
            detail,
            "RATE_LIMIT"
        )

class ServerException(APIException):
    """Server error"""
    def __init__(self, detail: str = "Internal server error"):
        super().__init__(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail,
            "SERVER_ERROR"
        )

# Exception handlers

async def api_exception_handler(request: Request, exc: APIException):
    """Handle custom API exceptions"""
    logger.error(f"{exc.error_code}: {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "error_code": exc.error_code,
            "status": "error"
        }
    )

async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic validation errors"""
    logger.error(f"Validation error: {exc}")
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(x) for x in error["loc"][1:]),
            "message": error["msg"]
        })

    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "detail": "Validation error",
            "error_code": "VALIDATION_ERROR",
            "errors": errors,
            "status": "error"
        }
    )

async def general_exception_handler(request: Request, exc: Exception):
    """Handle unhandled exceptions"""
    logger.exception(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "error_code": "INTERNAL_ERROR",
            "status": "error"
        }
    )

# User-friendly error messages
ERROR_MESSAGES = {
    "EMAIL_ALREADY_EXISTS": "Email already registered",
    "INVALID_CREDENTIALS": "Invalid email or password",
    "INVALID_PHONE": "Phone must be 10 digits",
    "WEAK_PASSWORD": "Password must be 8+ chars with uppercase and number",
    "DEVICE_OFFLINE": "Device is offline",
    "DEVICE_NOT_FOUND": "Device not found",
    "INVALID_DURATION": "Duration must be between 5 and 180 minutes",
    "TOO_MANY_COMMANDS": "Too many commands. Please wait.",
    "TOKEN_EXPIRED": "Session expired. Please login again",
    "INVALID_TOKEN": "Invalid token",
    "NO_PERMISSION": "You don't have permission for this action",
    "SENSOR_ERROR": "Sensor not responding. Check device power and WiFi.",
    "MQTT_ERROR": "Device communication error. Retrying...",
}

def get_error_message(error_code: str, default: str = None) -> str:
    """Get user-friendly error message"""
    return ERROR_MESSAGES.get(error_code, default or "An error occurred")
