// lib/services/ai_navigation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class AINavigationService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static String? _apiKey;

  static void setApiKey(String key) {
    _apiKey = key;
  }

  static Future<String?> getDirectionsText({
    required String fromLabel,
    required String toRoomName,
    required String floorName,
  }) async {
    if (_apiKey == null) {
      _apiKey = Env.openrouterApiKey;
      if (_apiKey!.isEmpty) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }
    }

    final prompt = 'Give 1-2 friendly walking directions sentences from $fromLabel to $toRoomName on the $floorName of Tangub City Global College. Be brief.';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.0-flash-001',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.2,
          'max_tokens': 150,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 429 || response.statusCode != 200) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      if (content == null || content.toString().isEmpty) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }

      return content.toString().trim();
    } catch (e) {
      return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
    }
  }
}