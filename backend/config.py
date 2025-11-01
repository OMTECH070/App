from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql+psycopg2://user:password@localhost/smartfarm"

    # JWT
    secret_key: str = "your-secret-key-change-in-production"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7

    # MQTT
    mqtt_broker: str = "localhost"
    mqtt_port: int = 1883
    mqtt_username: str = ""
    mqtt_password: str = ""

    # API
    api_title: str = "AI Smart Farming Assist API"
    api_version: str = "1.0.0"
    environment: str = "development"

    # Validation
    min_password_length: int = 8

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
