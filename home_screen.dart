import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const String backendUrl = "http://10.0.2.2:5000"; // use your server IP in prod

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMonitoring = false;
  bool _emergencyActive = false;
  String? _emergencyId;
  String _statusText = "Tap to start monitoring";
  LatLng? _currentLocation;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<Position>? _locationSub;
  final Completer<GoogleMapController> _mapController = Completer();

  static const double _shakeThreshold = 15.0;
  int _shakeCount = 0;

  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? "test_user";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _statusText = "Monitoring active...";
    });

    // Location updates
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
      if (_emergencyActive && _emergencyId != null) {
        _updateLiveLocation(pos.latitude, pos.longitude);
      }
    });

    // Shake detection
    _accelSub = accelerometerEvents.listen((event) {
      double magnitude =
          (event.x.abs() + event.y.abs() + event.z.abs()) - 9.81;
      if (magnitude > _shakeThreshold) {
        _shakeCount++;
        if (_shakeCount >= 3 && !_emergencyActive) {
          _triggerEmergency("shake");
          _shakeCount = 0;
        }
      } else {
        _shakeCount = 0;
      }
    });
  }

  void _stopMonitoring() {
    _accelSub?.cancel();
    _locationSub?.cancel();
    setState(() {
      _isMonitoring = false;
      _statusText = "Tap to start monitoring";
    });
  }

  Future<void> _triggerEmergency(String triggerType) async {
    if (_currentLocation == null) return;
    setState(() {
      _emergencyActive = true;
      _statusText = "🚨 Emergency Alert Sent!";
    });

    try {
      final resp = await http.post(
        Uri.parse("$backendUrl/api/emergency/trigger"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uid": _uid,
          "latitude": _currentLocation!.latitude,
          "longitude": _currentLocation!.longitude,
          "triggerType": triggerType,
        }),
      );
      final data = jsonDecode(resp.body);
      setState(() => _emergencyId = data["emergencyId"]);
    } catch (e) {
      debugPrint("Emergency trigger error: $e");
    }
  }

  Future<void> _updateLiveLocation(double lat, double lng) async {
    await http.post(
      Uri.parse("$backendUrl/api/emergency/location-update"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "emergencyId": _emergencyId,
        "latitude": lat,
        "longitude": lng,
      }),
    );
  }

  Future<void> _resolveEmergency() async {
    if (_emergencyId == null) return;
    await http.post(
      Uri.parse("$backendUrl/api/emergency/resolve"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"emergencyId": _emergencyId}),
    );
    setState(() {
      _emergencyActive = false;
      _emergencyId = null;
      _statusText = "Monitoring active...";
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Women Safety"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: _emergencyActive
                ? Colors.red
                : _isMonitoring
                    ? Colors.green
                    : Colors.grey.shade300,
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isMonitoring ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // Map
          Expanded(
            child: _currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (c) => _mapController.complete(c),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _currentLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId("user"),
                              position: _currentLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRose),
                            )
                          },
                  ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // SOS Button
                GestureDetector(
                  onTap: () => _triggerEmergency("manual"),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                      icon: Icon(_isMonitoring ? Icons.stop : Icons.shield),
                      label: Text(_isMonitoring ? "Stop" : "Start Monitoring"),
                    ),
                    if (_emergencyActive)
                      ElevatedButton.icon(
                        onPressed: _resolveEmergency,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("I'm Safe"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
