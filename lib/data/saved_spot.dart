import 'package:latlong2/latlong.dart';

class SavedSpot {
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final String category;

  SavedSpot({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.category = 'Personal',
  });

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'category': category,
  };

  factory SavedSpot.fromJson(Map<String, dynamic> json) {
    return SavedSpot(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Personal',
    );
  }
}