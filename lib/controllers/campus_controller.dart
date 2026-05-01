import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../data/database_helper.dart';
import '../data/campus_landmarks.dart';
import '../repositories/local_landmark_repository.dart';

class CampusController extends ChangeNotifier {
  final LocalLandmarkRepository _repository;
  List<CampusLandmark> _landmarks = [];
  bool _isLoading = false;

  CampusController() : _repository = LocalLandmarkRepository(DatabaseHelper());

  List<CampusLandmark> get landmarks => _landmarks;
  bool get isLoading => _isLoading;

  Future<void> loadLandmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _repository.getLandmarks();
      if (maps.isEmpty) {
        await _cacheDefaultLandmarks();
        final refreshed = await _repository.getLandmarks();
        _landmarks = refreshed.map(_landmarkFromMap).toList();
      } else {
        _landmarks = maps.map(_landmarkFromMap).toList();
      }
    } catch (e) {
      debugPrint('Error loading landmarks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _cacheDefaultLandmarks() async {
    final maps = tcgcLandmarks
        .map(
          (l) => {
            'id': l.id,
            'name': l.name,
            'latitude': l.position.latitude,
            'longitude': l.position.longitude,
            'description': l.description,
            'category': l.category,
            'floor': l.floor,
          },
        )
        .toList();
    await _repository.cacheLandmarks(maps);
  }

  CampusLandmark _landmarkFromMap(Map<String, dynamic> map) {
    // Safely parse coordinates from various types (num, String, etc.)
    double parseCoordinate(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final lat = parseCoordinate(map['latitude']);
    final lng = parseCoordinate(map['longitude']);

    return CampusLandmark(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? '',
      position: gmaps.LatLng(lat, lng),
      floor: map['floor'] as String?,
    );
  }

  Future<List<Map<String, dynamic>>> searchLandmarks(String query) =>
      _repository.searchLandmarks(query);
}
