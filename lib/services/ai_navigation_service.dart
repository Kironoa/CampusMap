// lib/services/ai_navigation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AINavigationService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
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
      _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (_apiKey!.isEmpty) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }
    }

    final prompt = 'Give 1-2 friendly walking directions sentences from $fromLabel to $toRoomName on the $floorName of Tangub City Global College. Be brief.';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 150,
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 429 || response.statusCode != 200) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }

      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]['content']?['parts']?[0]['text'];
      if (content == null || content.isEmpty) {
        return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
      }

      return content.toString().trim();
    } catch (e) {
      return 'From $fromLabel, follow the paw trail to $toRoomName on the $floorName.';
    }
  }
}