import 'dart:convert';

class LocationModel {
  final double lat;
  final double lng;
  final double ac;
  final int floor;
  LocationModel({
    required this.lat,
    required this.lng,
    required this.ac,
    required this.floor,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'ac': ac,
      'floor': floor,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      lat: map['lat']?.toDouble() ?? 0.0,
      lng: map['lng']?.toDouble() ?? 0.0,
      ac: map['ac']?.toDouble() ?? 0.0,
      floor: map['floor']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocationModel.fromJson(String source) =>
      LocationModel.fromMap(json.decode(source));
}
