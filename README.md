
#  Smart Women Safety System

<div align="center">

![Banner](https://img.shields.io/badge/Smart%20Women%20Safety-System-E91E8C?style=for-the-badge&logo=shield&logoColor=white)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-339933?style=flat-square&logo=node.js)](https://nodejs.org)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python)](https://python.org)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

**An AI-powered mobile application that automatically detects danger and sends emergency alerts — no manual action required.**

*A Minor Project by students of Department of CSA, SOET, ITM University Gwalior (M.P.)*

</div>

---

## 📌 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#backend-setup)
  - [AI Module Setup](#ai-module-setup)
  - [Flutter App Setup](#flutter-app-setup)
- [How It Works](#how-it-works)
- [API Reference](#api-reference)
- [Screenshots](#screenshots)
- [Future Scope](#future-scope)
- [Team](#team)
- [References](#references)
- [License](#license)

---

## Overview

Women safety is a major concern in today's world, especially when traveling alone or in unsafe areas. Many existing safety apps require the user to **manually press an SOS button** — but in real emergencies, victims may be unable to act due to fear, panic, or sudden danger.

The **Smart Women Safety System** uses Artificial Intelligence to **automatically detect distress** through:

- 🎙️ **Voice commands** (e.g., "Help", "Bachao")
- 📳 **Phone shake / sudden motion**
- 📍 **Real-time GPS location tracking**

Once danger is detected, the system **automatically**:
1. Sends SMS alerts to emergency contacts
2. Shares the live GPS location
3. Starts audio recording for evidence

> *"Technology becomes a silent protector."*

---

## Features

| Feature | Description |
|---|---|
| 🚨 **Auto SOS Trigger** | Emergency activated by voice or shake — no button press needed |
| 🎙️ **AI Voice Detection** | Detects distress keywords (multilingual: English + Hindi) |
| 📳 **Motion / Shake Detection** | Accelerometer-based shake/fall detection |
| 📍 **Real-time GPS Tracking** | Live location streaming via Socket.IO |
| 📲 **SMS Alerts** | Instant SMS to emergency contacts with Google Maps link |
| 🎤 **Audio Recording** | Auto-records audio when emergency is triggered |
| 🗺️ **Safe Route Suggestions** | Google Maps-based safe walking routes |
| 🔒 **Firebase Auth** | Secure user registration and authentication |
| 🧠 **Danger Predictor** | Rule-based risk scoring (time, location, crime data) |
| ✅ **I'm Safe Button** | User can resolve emergency once they are safe |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ Voice/Mic  │  │ Accelerometer│  │  Google Maps UI    │  │
│  └─────┬──────┘  └──────┬───────┘  └─────────┬──────────┘  │
└────────┼────────────────┼───────────────────  ┼────────────┘
         │                │                     │
         ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Node.js Backend (Express)                  │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────────┐  │
│  │ REST API     │  │  Socket.IO    │  │   Twilio SMS     │  │
│  └──────────────┘  └───────────────┘  └──────────────────┘  │
└──────────────────────────────┬──────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        ┌──────────┐   ┌──────────────┐   ┌──────────────┐
        │ Firebase │   │ Python AI    │   │ Google Maps  │
        │Firestore │   │ (Voice+Motion│   │   API        │
        └──────────┘   │  Detection) │   └──────────────┘
                       └──────────────┘
```

---

## Tech Stack

### Frontend
- **Flutter** — Cross-platform mobile app (Android/iOS)
- **Google Maps Flutter** — Live map and safe route display
- **sensors_plus** — Accelerometer for shake detection
- **speech_to_text** — On-device voice recognition

### Backend
- **Node.js + Express** — REST API server
- **Socket.IO** — Real-time live location streaming
- **Firebase Admin SDK** — Firestore database access
- **Twilio** — SMS alert notifications

### AI Module
- **Python 3.10+**
- **SpeechRecognition** — Distress keyword detection
- **PyAudio** — Microphone input
- Custom rule-based **Danger Predictor**

### Database & Services
- **Firebase Firestore** — User data and emergency events
- **Firebase Authentication** — Secure login
- **Google Maps API** — Geocoding and directions

---

## Project Structure

```
smart-women-safety-system/
│
├── backend/                        # Node.js + Express server
│   ├── server.js                   # Main server entry point
│   ├── package.json
│   └── .env.example                # Environment variables template
│
├── ai_module/                      # Python AI detection module
│   ├── detector.py                 # Voice + motion detection
│   └── requirements.txt
│
├── frontend_flutter/               # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart               # App entry point
│   │   ├── screens/
│   │   │   ├── home_screen.dart    # Main monitoring screen
│   │   │   ├── login_screen.dart   # Authentication
│   │   │   └── register_screen.dart
│   │   └── services/
│   │       ├── emergency_service.dart
│   │       └── location_service.dart
│   └── pubspec.yaml
│
├── docs/                           # Documentation and diagrams
│   ├── architecture.png
│   └── flowchart.png
│
└── README.md
```

---

## Getting Started

### Prerequisites

- Node.js v18+
- Python 3.10+
- Flutter SDK 3.x
- Firebase project (Firestore + Authentication enabled)
- Twilio account (for SMS)
- Google Maps API key

---

### Backend Setup

```bash
# 1. Navigate to backend directory
cd backend

# 2. Install dependencies
npm install

# 3. Copy environment template
cp .env.example .env

# 4. Edit .env with your credentials
nano .env

# 5. Place your Firebase service account key
#    Download from: Firebase Console → Project Settings → Service Accounts
mv ~/Downloads/serviceAccountKey.json ./serviceAccountKey.json

# 6. Start the server
npm run dev
```

**Environment variables (`.env`)**:

```env
PORT=5000
FIREBASE_DATABASE_URL=https://your-project-id.firebaseio.com
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

---

### AI Module Setup

```bash
# 1. Navigate to AI module directory
cd ai_module

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate    # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run the detector (connects to backend automatically)
python detector.py
```

> **Note:** On Linux, you may need `sudo apt-get install portaudio19-dev` before installing PyAudio.

---

### Flutter App Setup

```bash
# 1. Navigate to Flutter directory
cd frontend_flutter

# 2. Install Flutter dependencies
flutter pub get

# 3. Add your google-services.json (Android)
#    Download from Firebase Console → Project Settings → Your Apps
cp ~/Downloads/google-services.json android/app/

# 4. Add your GoogleService-Info.plist (iOS)
cp ~/Downloads/GoogleService-Info.plist ios/Runner/

# 5. Update backend URL in lib/screens/home_screen.dart
#    Change: const String backendUrl = "http://10.0.2.2:5000";
#    To your server's IP or deployed URL

# 6. Run on a connected device or emulator
flutter run
```

---

## How It Works

```
User Opens App
      │
      ▼
User Registers + Adds Emergency Contacts
      │
      ▼
App Continuously Monitors:
  ├── 🎙️ Microphone → Voice Recognition
  │         └── Distress keyword detected?
  ├── 📳 Accelerometer → Shake Detection
  │         └── Shake threshold exceeded 3 times?
  └── 📍 GPS → Location Update every 10m
      │
      ▼ (Any trigger fires)
Emergency Mode Activated
  ├── 📲 SMS sent to all emergency contacts (with Maps link)
  ├── 🔴 Live location streaming starts
  ├── 🎤 Audio recording begins
  └── 📍 Location updates sent every few seconds
      │
      ▼
User presses "I'm Safe" → Emergency Resolved
```

---

## API Reference

### `POST /api/user/register`
Register a new user with emergency contacts.

```json
{
  "uid": "firebase_user_id",
  "name": "Priya Sharma",
  "phone": "+919876543210",
  "emergencyContacts": [
    { "name": "Mummy", "phone": "+919876543211" }
  ]
}
```

---

### `POST /api/emergency/trigger`
Trigger an emergency alert.

```json
{
  "uid": "firebase_user_id",
  "latitude": 26.4499,
  "longitude": 80.3319,
  "triggerType": "voice",
  "audioUrl": "https://storage.example.com/recording.mp3"
}
```

**Response:**
```json
{ "success": true, "emergencyId": "abc123" }
```

---

### `POST /api/emergency/location-update`
Update live location during an active emergency.

```json
{
  "emergencyId": "abc123",
  "latitude": 26.4510,
  "longitude": 80.3325
}
```

---

### `POST /api/emergency/resolve`
Mark an emergency as resolved.

```json
{ "emergencyId": "abc123" }
```

---

### `GET /api/route/safe`
Get a safe walking route.

```
GET /api/route/safe?originLat=26.44&originLng=80.33&destLat=26.45&destLng=80.34
```

---

## Future Scope

- ⌚ **Smartwatch Integration** — trigger SOS from wearable devices
- 👤 **Facial Recognition** — detect threatening individuals via camera
- 🗺️ **Crime Hotspot Prediction** — AI model trained on crime data to predict unsafe zones
- 🚔 **Police Integration** — direct alert routing to nearest police station
- 🔊 **Loud Alarm** — auto-activate phone speaker alarm during emergency
- 🌐 **Offline Mode** — basic SOS even without internet (SMS fallback)

---

## Team

| Name | Roll No | Role |
|------|---------|------|
| Humera Khan | BETN1AI23054 | AI Module & Backend |
| Anuj Pratap Singh | BETN1AI23048 | Flutter Frontend |
| Sumit Sharma | BETN1AI23023 | Backend & Integration |

**Under the Guidance of:**  
Mr. Manish Kumar Jain  
*Assistant Professor, Department of CSA, SOET, ITM University, Gwalior (M.P.)*

---

## References

- [Google Maps Platform Documentation](https://developers.google.com/maps)
- [Firebase Documentation](https://firebase.google.com/docs)
- [SpeechRecognition Library (PyPI)](https://pypi.org/project/SpeechRecognition/)
- [Flutter Documentation](https://docs.flutter.dev)
- [Android Developer Documentation](https://developer.android.com)
- Research Paper: *"Women Safety System using IoT and GPS"* — IJERT
- Research Paper: *"Smart Women Safety System using AI"* — IEEE Xplore

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

Made with ❤️ for women's safety | ITM University, Gwalior

</div>
