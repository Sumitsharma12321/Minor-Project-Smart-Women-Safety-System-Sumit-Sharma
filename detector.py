"""
Smart Women Safety System - AI Detection Module
Detects distress via voice commands and motion (shake/fall).
"""

import speech_recognition as sr
import requests
import json
import time
import math
import threading
from typing import Optional

# ── Configuration ─────────────────────────────────────────────────────────────
BACKEND_URL = "http://localhost:5000/api/emergency/trigger"

DISTRESS_KEYWORDS = [
    "help", "bachao", "choro", "help me", "save me",
    "emergency", "danger", "leave me", "chhod do",
    "help please", "call police",
]

SHAKE_THRESHOLD = 15.0        # m/s² above gravity
SHAKE_CONSECUTIVE_COUNT = 3   # number of consecutive readings to confirm shake


# ── Voice Detection ───────────────────────────────────────────────────────────

class VoiceDetector:
    def __init__(self, uid: str, language: str = "en-IN"):
        self.uid = uid
        self.language = language
        self.recognizer = sr.Recognizer()
        self.microphone = sr.Microphone()
        self.running = False

        # Calibrate ambient noise once
        with self.microphone as source:
            print("[Voice] Calibrating for ambient noise...")
            self.recognizer.adjust_for_ambient_noise(source, duration=2)
            print("[Voice] Ready.")

    def _contains_distress(self, text: str) -> bool:
        text_lower = text.lower()
        return any(keyword in text_lower for keyword in DISTRESS_KEYWORDS)

    def _trigger_emergency(self, latitude: float, longitude: float, text: str):
        payload = {
            "uid": self.uid,
            "latitude": latitude,
            "longitude": longitude,
            "triggerType": "voice",
            "detectedText": text,
        }
        try:
            resp = requests.post(BACKEND_URL, json=payload, timeout=10)
            print(f"[Voice] Emergency triggered: {resp.json()}")
        except Exception as e:
            print(f"[Voice] Failed to trigger emergency: {e}")

    def listen_continuously(self, get_location_fn):
        """Continuously listen for distress keywords."""
        self.running = True
        print("[Voice] Listening for distress keywords...")
        while self.running:
            try:
                with self.microphone as source:
                    audio = self.recognizer.listen(source, timeout=5, phrase_time_limit=5)
                text = self.recognizer.recognize_google(audio, language=self.language)
                print(f"[Voice] Heard: {text}")
                if self._contains_distress(text):
                    lat, lng = get_location_fn()
                    print(f"[Voice] 🚨 Distress detected! '{text}'")
                    self._trigger_emergency(lat, lng, text)
            except sr.WaitTimeoutError:
                pass
            except sr.UnknownValueError:
                pass
            except Exception as e:
                print(f"[Voice] Error: {e}")
                time.sleep(1)

    def stop(self):
        self.running = False


# ── Motion / Shake Detection ──────────────────────────────────────────────────

class MotionDetector:
    """
    Simulates accelerometer readings.
    In production, replace `get_accelerometer_reading` with
    actual sensor input (e.g., via Android sensor API bridge).
    """

    def __init__(self, uid: str):
        self.uid = uid
        self.running = False
        self._consecutive_shakes = 0

    def _magnitude(self, x: float, y: float, z: float) -> float:
        gravity = 9.81
        return abs(math.sqrt(x**2 + y**2 + z**2) - gravity)

    def _trigger_emergency(self, latitude: float, longitude: float):
        payload = {
            "uid": self.uid,
            "latitude": latitude,
            "longitude": longitude,
            "triggerType": "shake",
        }
        try:
            resp = requests.post(BACKEND_URL, json=payload, timeout=10)
            print(f"[Motion] Emergency triggered: {resp.json()}")
        except Exception as e:
            print(f"[Motion] Failed to trigger emergency: {e}")

    def monitor(self, get_accelerometer_fn, get_location_fn, interval: float = 0.1):
        """
        get_accelerometer_fn() → (x, y, z) in m/s²
        get_location_fn()      → (latitude, longitude)
        """
        self.running = True
        print("[Motion] Monitoring for shake/fall events...")
        while self.running:
            try:
                x, y, z = get_accelerometer_fn()
                magnitude = self._magnitude(x, y, z)
                if magnitude > SHAKE_THRESHOLD:
                    self._consecutive_shakes += 1
                    print(f"[Motion] Shake detected ({self._consecutive_shakes}/{SHAKE_CONSECUTIVE_COUNT}), magnitude={magnitude:.2f}")
                    if self._consecutive_shakes >= SHAKE_CONSECUTIVE_COUNT:
                        lat, lng = get_location_fn()
                        print("[Motion] 🚨 Shake emergency triggered!")
                        self._trigger_emergency(lat, lng)
                        self._consecutive_shakes = 0
                        time.sleep(10)  # cooldown
                else:
                    self._consecutive_shakes = 0
            except Exception as e:
                print(f"[Motion] Error: {e}")
            time.sleep(interval)

    def stop(self):
        self.running = False


# ── Danger Predictor (rule-based, extendable to ML) ───────────────────────────

class DangerPredictor:
    """
    Scores risk level based on time-of-day, location type, and recent events.
    Returns a risk level: 'low', 'medium', 'high'
    """

    def predict(
        self,
        hour: int,
        is_isolated_area: bool,
        recent_crime_count: int,
    ) -> str:
        score = 0
        if 22 <= hour or hour <= 5:
            score += 3
        elif 20 <= hour <= 22:
            score += 1
        if is_isolated_area:
            score += 3
        score += min(recent_crime_count, 4)

        if score >= 6:
            return "high"
        elif score >= 3:
            return "medium"
        return "low"


# ── Safety Manager (orchestrates everything) ──────────────────────────────────

class SafetyManager:
    def __init__(self, uid: str):
        self.uid = uid
        self.voice_detector = VoiceDetector(uid)
        self.motion_detector = MotionDetector(uid)
        self.predictor = DangerPredictor()
        self._location = (0.0, 0.0)

    def update_location(self, latitude: float, longitude: float):
        self._location = (latitude, longitude)

    def get_location(self):
        return self._location

    def start(self, get_accelerometer_fn):
        print(f"[SafetyManager] Starting for user {self.uid}")

        voice_thread = threading.Thread(
            target=self.voice_detector.listen_continuously,
            args=(self.get_location,),
            daemon=True,
        )
        motion_thread = threading.Thread(
            target=self.motion_detector.monitor,
            args=(get_accelerometer_fn, self.get_location),
            daemon=True,
        )

        voice_thread.start()
        motion_thread.start()

        print("[SafetyManager] All detectors running. Press Ctrl+C to stop.")
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            self.voice_detector.stop()
            self.motion_detector.stop()
            print("[SafetyManager] Stopped.")


# ── Demo Entry Point ──────────────────────────────────────────────────────────

if __name__ == "__main__":
    import random

    def mock_accelerometer():
        """Simulate normal movement with occasional shake."""
        if random.random() < 0.02:  # 2% chance of simulated shake
            return (random.uniform(15, 25), random.uniform(15, 25), random.uniform(15, 25))
        return (random.uniform(0, 1), random.uniform(0, 1), 9.81)

    manager = SafetyManager(uid="demo_user_123")
    manager.update_location(26.4499, 80.3319)  # Example coordinates
    manager.start(mock_accelerometer)
