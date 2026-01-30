import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final double lat;
  final double lng;
  final int aqi;
  final double temp;
  final int humidity;
  final String weather; // sunny/rainy/cloudy
  final Timestamp? timestamp;

  LocationModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.aqi,
    required this.temp,
    required this.humidity,
    required this.weather,
    this.timestamp,
  });

  factory LocationModel.fromDoc(DocumentSnapshot d) {
    final raw = d.data();
    final map = raw is Map ? Map<String, dynamic>.from(raw as Map) : <String, dynamic>{};
    double parseDouble(dynamic v, double def) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? def;
      return def;
    }

    int parseInt(dynamic v, int def) {
      if (v == null) return def;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }

    return LocationModel(
      id: d.id,
      lat: parseDouble(map['lat'], 19.0760),
      lng: parseDouble(map['lng'], 72.8777),
      aqi: parseInt(map['aqi'], 50),
      temp: parseDouble(map['temp'], 28.0),
      humidity: parseInt(map['humidity'], 60),
      weather: (map['weather']?.toString() ?? 'sunny'),
      timestamp: map['timestamp'] is Timestamp ? map['timestamp'] as Timestamp : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'aqi': aqi,
        'temp': temp,
        'humidity': humidity,
        'weather': weather,
        'timestamp': timestamp,
      };
}
