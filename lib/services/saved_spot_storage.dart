import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naviapp/data/saved_spot.dart';

class SavedSpotStorage {
  static const String _key = 'personal_saved_spots';

  static Future<List<SavedSpot>> loadSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => SavedSpot.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveSpots(List<SavedSpot> spots) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = spots.map((spot) => spot.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    return prefs.setString(_key, jsonString);
  }

  static Future<bool> addSpot(SavedSpot spot) async {
    final spots = await loadSpots();
    spots.add(spot);
    return saveSpots(spots);
  }

  static Future<bool> removeSpotById(String id) async {
    final spots = await loadSpots();
    spots.removeWhere((spot) => spot.id == id);
    return saveSpots(spots);
  }

  static Future<bool> removeSpot(int index) async {
    final spots = await loadSpots();
    if (index >= 0 && index < spots.length) {
      spots.removeAt(index);
      return saveSpots(spots);
    }
    return false;
  }

  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.remove(_key);
  }
}