// lib/services/ai_navigation_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AINavigationResult {
  final String answer;
  final String floor;
  final List<Offset> pathPoints;
  final List<String> steps;

  AINavigationResult({
    required this.answer,
    required this.floor,
    required this.pathPoints,
    required this.steps,
  });
}

class AINavigationService {
  static final AINavigationService instance = AINavigationService._();
  AINavigationService._();

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  String? _apiKey;

  void setApiKey(String key) {
    _apiKey = key;
  }

  Future<String> getDirectionsText({
    required String fromLabel,
    required String toRoomName,
    required String floorName,
  }) async {
    if (_apiKey == null) {
      _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (_apiKey!.isEmpty) {
        return 'From $fromLabel, follow the highlighted paw trail to reach $toRoomName on the $floorName.';
      }
    }

    final prompt = 'You are a friendly campus navigation assistant for TCGC. '
        'Give brief 2-3 sentence walking directions from $fromLabel to $toRoomName on $floorName floor. '
        'Mention corridors and landmarks. Be concise.';

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
      );

      if (response.statusCode == 429 || response.statusCode != 200) {
        return 'From $fromLabel, follow the highlighted paw trail to reach $toRoomName on the $floorName.';
      }

      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]['content']?['parts']?[0]['text'];
      if (content == null || content.isEmpty) {
        return 'From $fromLabel, follow the highlighted paw trail to reach $toRoomName on the $floorName.';
      }

      return content.toString().trim();
    } catch (e) {
      return 'From $fromLabel, follow the highlighted paw trail to reach $toRoomName on the $floorName.';
    }
  }

  Future<AINavigationResult> navigate({
    required String roomName,
    required String roomId,
    required int floorIndex,
    required String startNodeId,
    required String endNodeId,
    required String fromLabel,
  }) async {
    final floorName = floorIndex == 0
        ? 'Ground'
        : floorIndex == 1
            ? '2nd'
            : '3rd';

    final answer = await getDirectionsText(
      fromLabel: fromLabel,
      toRoomName: roomName,
      floorName: floorName,
    );

    return AINavigationResult(
      answer: answer,
      floor: floorIndex.toString(),
      pathPoints: const [],
      steps: [answer],
    );
  }
}