const express = require("express");
const http = require("http");
const socketIo = require("socket.io");
const cors = require("cors");
const admin = require("firebase-admin");
const twilio = require("twilio");
require("dotenv").config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

app.use(cors());
app.use(express.json());

// Firebase Admin Init
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL,
});

const db = admin.firestore();

// Twilio Init
const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// ─── Routes ──────────────────────────────────────────────────────────────────

// Register / update user profile
app.post("/api/user/register", async (req, res) => {
  const { uid, name, phone, emergencyContacts } = req.body;
  try {
    await db.collection("users").doc(uid).set({
      name,
      phone,
      emergencyContacts, // [{ name, phone }]
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json({ success: true, message: "User registered successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Trigger emergency
app.post("/api/emergency/trigger", async (req, res) => {
  const { uid, latitude, longitude, triggerType, audioUrl } = req.body;
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) return res.status(404).json({ message: "User not found" });

    const user = userDoc.data();
    const mapsLink = `https://maps.google.com/?q=${latitude},${longitude}`;

    // Save emergency event
    const emergencyRef = await db.collection("emergencies").add({
      uid,
      latitude,
      longitude,
      triggerType,  // 'voice' | 'shake' | 'manual'
      audioUrl: audioUrl || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: "active",
    });

    // Notify all emergency contacts via SMS
    const smsPromises = user.emergencyContacts.map((contact) =>
      twilioClient.messages.create({
        body: `🚨 EMERGENCY ALERT! ${user.name} needs help!\nTrigger: ${triggerType}\nLocation: ${mapsLink}\nPlease respond immediately.`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: contact.phone,
      })
    );

    await Promise.all(smsPromises);

    // Emit live location to socket room
    io.to(uid).emit("emergency_active", {
      emergencyId: emergencyRef.id,
      latitude,
      longitude,
      triggerType,
    });

    res.json({ success: true, emergencyId: emergencyRef.id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// Update live location during emergency
app.post("/api/emergency/location-update", async (req, res) => {
  const { emergencyId, latitude, longitude } = req.body;
  try {
    await db.collection("emergencies").doc(emergencyId).update({
      latitude,
      longitude,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    io.emit(`location_${emergencyId}`, { latitude, longitude });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Resolve emergency
app.post("/api/emergency/resolve", async (req, res) => {
  const { emergencyId } = req.body;
  try {
    await db.collection("emergencies").doc(emergencyId).update({
      status: "resolved",
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json({ success: true, message: "Emergency resolved" });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Get safe route (calls Google Directions API)
app.get("/api/route/safe", async (req, res) => {
  const { originLat, originLng, destLat, destLng } = req.query;
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${originLat},${originLng}&destination=${destLat},${destLng}&mode=walking&key=${apiKey}`;
  try {
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// ─── Socket.IO ───────────────────────────────────────────────────────────────
io.on("connection", (socket) => {
  console.log("New client connected:", socket.id);

  socket.on("join_room", (uid) => {
    socket.join(uid);
    console.log(`User ${uid} joined room`);
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

// ─── Start ───────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
