# AI Smart Farming Assist - Implementation

Complete implementation of IoT-based irrigation management platform for small/marginal Indian farmers.

## Overview

**AI Smart Farming Assist** is a mobile-first application designed to automate irrigation scheduling and provide predictive farming insights using real-time IoT sensor data and AI analytics.

**Target Platform:** Flutter (iOS/Android) + Python FastAPI backend
**Target Users:** Small/marginal farmers (age 25-65, limited smartphone experience)
**Key Features:** Real-time sensor monitoring, AI-driven irrigation recommendations, offline mode, multi-language support (EN/HI/MAR)

---

## Project Structure

```
App/
├── backend/                    # Python FastAPI backend
│   ├── main.py                # FastAPI app entry point with WebSocket support
│   ├── models.py              # SQLAlchemy ORM models
│   ├── schemas.py             # Pydantic request/response models
│   ├── config.py              # Configuration management
│   ├── database.py            # Database setup and initialization
│   ├── utils_auth.py          # Authentication utilities
│   ├── routes_auth.py         # Authentication endpoints
│   ├── routes_devices.py      # Device management endpoints
│   ├── routes_sensors.py      # Sensor data endpoints
│   ├── routes_irrigation.py   # Irrigation control endpoints
│   ├── routes_notifications.py # Notification endpoints
│   ├── routes_settings.py     # Settings endpoints
│   ├── routes_ai.py           # AI recommendation endpoints
│   └── requirements.txt       # Python dependencies
│
├── flutter/                    # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── firebase_options.dart # Firebase configuration
│   │   ├── config/
│   │   │   └── app_theme.dart # Light/dark theme configuration
│   │   ├── l10n/
│   │   │   └── app_localizations.dart # Multi-language support (EN/HI/MAR)
│   │   ├── providers/         # State management (Provider pattern)
│   │   │   ├── auth_provider.dart
│   │   │   ├── device_provider.dart
│   │   │   ├── sensor_provider.dart
│   │   │   ├── notification_provider.dart
│   │   │   └── settings_provider.dart
│   │   ├── services/          # Business logic
│   │   │   ├── api_service.dart # HTTP client with auto-retry
│   │   │   ├── websocket_service.dart # Real-time updates
│   │   │   └── offline_service.dart # SQLite offline storage
│   │   └── screens/           # UI screens
│   │       ├── auth/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       ├── dashboard_screen.dart
│   │       ├── device_control_screen.dart
│   │       ├── notifications_screen.dart
│   │       └── settings_screen.dart
│   ├── pubspec.yaml           # Flutter dependencies
│   └── android/               # Android-specific files
│
├── .env.example               # Environment configuration template
└── README_IMPLEMENTATION.md   # This file
```

---

## Backend Setup

### Prerequisites

- Python 3.8+
- PostgreSQL 12+
- TimescaleDB (PostgreSQL extension)
- MQTT broker (Mosquitto)

### Installation

1. **Install Python dependencies:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Create database:**
   ```bash
   createdb smartfarm
   psql smartfarm -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
   ```

4. **Run migrations (automatic on startup):**
   ```bash
   cd backend
   python main.py
   ```

### Running the Backend

```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Backend will be available at `http://localhost:8000`
API docs: `http://localhost:8000/docs`

---

## Frontend (Flutter) Setup

### Prerequisites

- Flutter 3.0+
- Android SDK 21+ or iOS 12.0+
- Dart 3.0+

### Installation

1. **Install Flutter dependencies:**
   ```bash
   cd flutter
   flutter pub get
   ```

2. **Configure Firebase:**
   - Create Firebase project at https://firebase.google.com
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `firebase_options.dart` with your credentials

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## Technology Stack

### Backend
- **Framework:** Python FastAPI
- **Database:** PostgreSQL + TimescaleDB (time-series data)
- **Real-time:** WebSocket (WebSockets library)
- **IoT Communication:** MQTT (Paho-MQTT)
- **Authentication:** JWT with refresh tokens
- **ORM:** SQLAlchemy

### Frontend
- **Framework:** Flutter (Dart)
- **State Management:** Provider pattern
- **HTTP Client:** Dio (with automatic retry)
- **Real-time:** WebSocket (web_socket_channel)
- **Offline Storage:** SQLite (sqflite)
- **Localization:** Flutter i18n (intl package)
- **UI Components:** Material Design 3
- **Charts:** FL Chart

### Database
- **Relational:** PostgreSQL
- **Time-series:** TimescaleDB (hypertables for sensor data)

---

## API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - User logout

### Devices
- `POST /devices/pair` - Pair new ESP32 device
- `GET /devices/` - List user's devices
- `GET /devices/{device_id}/status` - Get device status
- `DELETE /devices/{device_id}` - Unpair device

### Sensors
- `GET /sensors/{device_id}/latest` - Get latest sensor reading
- `GET /sensors/{device_id}/history` - Get sensor history (24h-30d)

### Irrigation
- `POST /irrigation/start` - Start irrigation
- `POST /irrigation/stop` - Stop irrigation (emergency)
- `GET /irrigation/{device_id}/history` - Get irrigation history

### Notifications
- `GET /notifications/` - Get user notifications
- `PUT /notifications/{id}/read` - Mark as read
- `DELETE /notifications/{id}` - Delete notification

### Settings
- `GET /settings/` - Get user settings
- `PATCH /settings/` - Update settings

### AI
- `GET /ai/recommendation/{device_id}` - Get AI recommendation
- `POST /ai/recommendation/{device_id}/apply` - Apply recommendation

### WebSocket
- `wss://localhost:8000/ws?token=JWT_TOKEN` - Real-time updates

---

## Key Features

### 1. **Real-Time Monitoring**
- Live soil moisture, temperature, humidity readings
- Device connection status with last sync timestamp
- Battery level and WiFi signal strength

### 2. **AI-Driven Recommendations**
- Automated irrigation scheduling based on soil moisture
- Predicted water savings percentage
- Confidence scores for recommendations
- Rule-based logic (MVP) → ML models (Phase 2)

### 3. **Manual Control**
- One-click irrigation ("Water Now" button)
- Adjustable irrigation duration (5-180 minutes)
- Emergency stop button (always visible)
- Automation mode toggle

### 4. **Offline-First Architecture**
- Local SQLite cache for last 2 hours of data
- Command queueing for offline actions
- Auto-sync when reconnected (with exponential backoff)
- Optimistic UI updates

### 5. **Multi-Language Support**
- English, Hindi, Marathi
- Instant language switching via Settings
- Applied to all UI text, notifications, and recommendations

### 6. **Accessibility**
- Minimum 16pt font for main text
- High contrast colors (4.5:1 ratio in light and dark modes)
- Maximum 3-step navigation
- Icon + text labels on all buttons
- Voice support hotline button

### 7. **Dark Mode**
- System default or manual toggle
- Maintained accessibility contrast
- Smooth theme switching

### 8. **Notifications**
- Critical alerts (red banner)
- Warnings (orange notification)
- Info & success badges
- Push notifications via Firebase Cloud Messaging
- Local notifications for offline events

---

## Data Models

### Core Entities

**User**
- id, email, phone, password_hash, name, language, timezone
- Created/updated timestamps

**Device**
- id, user_id, device_id, field_name, device_type
- status (connected|offline|error)
- battery_level, wifi_signal, automation_enabled
- last_sync timestamp

**SensorReading** (TimescaleDB hypertable)
- time (index for time-series queries)
- device_id, moisture (0-100), temperature, humidity
- signal_strength (-100 to 0 dBm)
- 90-day retention with compression after 30 days

**IrrigationCommand**
- id, device_id, duration_minutes, mode (manual|automation|emergency_stop)
- status (queued|sent|executing|completed|failed)
- start_time, end_time, water_used_liters

**Notification**
- id, user_id, device_id, type (critical|warning|info|success)
- title, message, action_type, is_read, is_dismissed
- 30-day retention

**AIRecommendation**
- id, device_id
- recommended_moisture_level, recommended_duration_minutes
- confidence_score (0-100), water_savings_percent
- reason (in user's language), valid_until

---

## Authentication Flow

1. **Registration:**
   - User enters email, phone, password, name, language
   - Validation: email format, password strength (8+ chars, uppercase, number), phone (10 digits)
   - Backend creates user, returns JWT access token + refresh token
   - App stores tokens in secure storage (Keychain/Keystore)

2. **Login:**
   - Email + password
   - Backend authenticates, returns tokens
   - App stores tokens, navigates to Dashboard

3. **Token Lifecycle:**
   - Access token: 15 minutes TTL
   - Refresh token: 7 days TTL
   - On 401 response: Auto-refresh access token
   - If refresh fails: Force re-login

---

## Offline Architecture

### Caching Strategy
- Cache last 2 hours of sensor readings locally
- Cache last 50 notifications
- Sync interval: Every 5 minutes (when connected)

### Command Queueing
- Store user commands in SQLite when offline
- Show UI feedback immediately (optimistic update)
- Retry when reconnected (exponential backoff: 5s, 10s, 30s, 60s)
- Max 10 retries before marking failed

### Reconnection Flow
1. App detects internet restored
2. Auto-sync triggered
3. Upload queued commands via REST API
4. Download latest data (sensors, notifications, status)
5. Clear command queue if successful
6. Show success toast

---

## Error Handling

### User-Friendly Messages

**Network Errors:**
- "No internet connection. Using offline mode."
- "Connection unstable. Retrying..."
- "Connection timeout. Please retry."

**Device Errors:**
- "Device not responding. Check power and WiFi."
- "Device disconnected for 10 minutes."
- "Command will retry when device reconnects."

**API Errors:**
- 400: "Invalid input. Please check and try again."
- 401: "Session expired. Please login again."
- 429: "Too many requests. Please wait a moment."
- 500: "Server error. Please try again later."

---

## Testing

### Unit Tests (Backend)
- Authentication flows (login, refresh, logout)
- Password hashing and verification
- Command queueing logic
- Sensor data validation
- Duration validation (5-180 mins)

### Integration Tests
- Device pairing flow
- Sensor data sync
- Notification delivery
- Offline → Online transition
- Multiple device control

### E2E Tests
- Complete user journey: Register → Pair device → Water → View notifications
- Offline device: Send command → Device reconnects → Command executes
- Error scenarios: Device disconnected, network timeout, invalid credentials

---

## Deployment

### Backend Deployment
1. Containerize with Docker
2. Set up PostgreSQL + TimescaleDB
3. Deploy MQTT broker
4. Configure environment variables
5. Set up SSL/TLS certificates
6. Use load balancer for scaling

### Frontend Deployment
- **Android:** Build APK/AAB, upload to Google Play Store
- **iOS:** Build IPA, upload to Apple App Store
- Both require signing certificates and app IDs

---

## Performance Targets

- Dashboard load: <2 seconds
- Sensor update (WebSocket): <500ms
- Irrigation command: <1 second
- Push notification: <5 seconds
- API response (p95): <500ms
- App size: <50MB

---

## Future Enhancements (Phase 2)

1. **Sensor Data Screen** - Detailed graphs (24h/7d/30d)
2. **AI Predictions Screen** - 7-day watering calendar, yield forecasting
3. **Data Export** - CSV/PDF reports
4. **SMS Commands** - Control via SMS
5. **Weather Integration** - Real-time overlay
6. **Predictive Alerts** - Predict issues before they happen
7. **Community Features** - Farmer groups, knowledge sharing
8. **Government Schemes** - Subsidy tracking integration

---

## Support & Documentation

- API Documentation: `http://localhost:8000/docs`
- Database Schema: See models.py
- Localization: See app_localizations.dart
- Theme Configuration: See app_theme.dart

---

## License

Proprietary - AI Smart Farming Assist

---

**Last Updated:** November 1, 2024
**Version:** 1.0.0 MVP
