import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/location_model.dart';

class MapState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<LocationModel> _locations = [];
  Unsubscribe? _listener;
  LocationModel? _selected;

  List<LocationModel> get locations => List.unmodifiable(_locations);
  LocationModel? get selected => _selected;

  /// Initialize and start listening to Firestore 'locations'. Falls back to demo data.
  Future<void> init() async {
    // try real-time listener
    try {
      _listener = _db.collection('locations').snapshots().listen((snap) {
        _locations.clear();
        for (var d in snap.docs) {
          try {
            _locations.add(LocationModel.fromDoc(d));
          } catch (_) {}
        }
        if (_locations.isEmpty) {
          _loadDemoData();
        }
        notifyListeners();
      });
    } catch (_) {
      _loadDemoData();
      notifyListeners();
    }
  }

  void disposeState() {
    _listener?.cancel();
  }

  void _loadDemoData() {
    // realistic demo locations around a city
    _locations.clear();
    _locations.addAll([
      LocationModel(id: 'colaba', lat: 18.92198, lng: 72.8335, aqi: 72, temp: 31.0, humidity: 70, weather: 'cloudy', timestamp: null),
      LocationModel(id: 'fort', lat: 18.9402, lng: 72.8307, aqi: 120, temp: 29.0, humidity: 65, weather: 'sunny', timestamp: null),
      LocationModel(id: 'bandra', lat: 19.0553, lng: 72.8404, aqi: 160, temp: 30.5, humidity: 80, weather: 'rainy', timestamp: null),
      LocationModel(id: 'powai', lat: 19.1190, lng: 72.9108, aqi: 42, temp: 27.0, humidity: 55, weather: 'sunny', timestamp: null),
    ]);
    if (_selected == null && _locations.isNotEmpty) _selected = _locations.first;
  }

  void select(LocationModel l) {
    _selected = l;
    notifyListeners();
  }

  // AQI helpers
  Color colorForAqi(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.limeAccent.shade400;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown.shade700;
  }

  // Map marker hue helper
  double hueForAqi(int aqi) {
    if (aqi <= 50) return 120.0; // green
    if (aqi <= 100) return 70.0; // yellowish
    if (aqi <= 150) return 30.0; // orange
    if (aqi <= 200) return 0.0; // red
    if (aqi <= 300) return 280.0; // purple
    return 330.0; // maroon/brown
  }
}

// Typedef for listener unsubscribe to avoid importing StreamSubscription everywhere
typedef Unsubscribe = StreamSubscription<QuerySnapshot>;
