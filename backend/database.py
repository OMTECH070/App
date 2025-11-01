from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool
from config import get_settings

settings = get_settings()

# Create engine with connection pooling
engine = create_engine(
    settings.database_url,
    poolclass=NullPool,  # Disable pooling for serverless/variable loads
    echo=settings.environment == "development"
)

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for all models
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Initialize TimescaleDB hypertable for sensor_readings
@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    """Enable TimescaleDB extension and create hypertables"""
    try:
        cursor = dbapi_conn.cursor()
        # Enable TimescaleDB extension
        cursor.execute("CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;")
        cursor.close()
    except Exception as e:
        print(f"Error enabling TimescaleDB: {e}")
