// ignore_for_file: avoid_classes_with_only_static_members
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/config/env.dart';

class AINavigationResult {
  final String answer;
  final String? targetRoomId;
  final String? floor;
  final List<String> steps;
  final List<Offset> pathPoints;

  AINavigationResult({
    required this.answer,
    this.targetRoomId,
    this.floor,
    this.steps = const [],
    this.pathPoints = const [],
  });
}

class AINavigationService {
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static String get _systemPrompt => _buildSystemPrompt();

  static String _buildSystemPrompt() {
    final groundRooms = FloorPlanData.groundFloorRooms
        .map((r) =>
            '  • [${r.id}] ${r.name} (${r.category.name})${r.description != null ? ' — ${r.description}' : ''}')
        .join('\n');

    final secondRooms = FloorPlanData.secondFloorRooms
        .map((r) =>
            '  • [${r.id}] ${r.name} (${r.category.name})${r.description != null ? ' — ${r.description}' : ''}')
        .join('\n');

    final thirdRooms = FloorPlanData.thirdFloorRooms
        .map((r) =>
            '  • [${r.id}] ${r.name} (${r.category.name})${r.description != null ? ' — ${r.description}' : ''}')
        .join('\n');

    return '''
You are the AI Navigation Assistant for Tangub City Global College (TCGC) campus.

═══ FLOOR 0 (Ground / First Floor — same physical level) ═══
$groundRooms

═══ FLOOR 1 (Second Floor) ═══
$secondRooms

═══ FLOOR 2 (Third Floor) ═══
$thirdRooms

IMPORTANT: "Ground Floor" and "First Floor" are both Floor 0.
- Main entrance: Floor 0, center-top (x: 0.5, y: 0.9)
- Elevator: center of all floors
- West stairs: left side, East stairs: right side

NAVIGATION TASK:
1. When user asks for a room/location, respond with JSON only
2. Include walking path coordinates normalized (0.0-1.0) for the floor layout
3. Path should show realistic corridor route from entrance to destination

JSON RESPONSE FORMAT:
{
  "answer": "2-3 sentence friendly directions",
  "target_room_id": "exact room id from floor data or null",
  "floor": "0, 1, or 2",
  "steps": ["Step 1: ...", "Step 2: ..."],
  "path_points": [
    {"x": 0.5, "y": 0.9},
    {"x": 0.5, "y": 0.7},
    {"x": 0.5, "y": 0.5}
  ]
}

Floor 0 corridor layout: entrance at y:0.9, center x:0.5, west corridor x:0.2, east corridor x:0.8
Floor 1 layout: similar with labs on west, offices on east
Floor 2 layout: smaller, classrooms and library extension

If user asks non-navigation question, return helpful answer in JSON with null for room_id and empty path_points.
''';
  }

  static Future<AINavigationResult> navigate({
    required String userQuery,
    String? currentFloor,
    String? currentRoomId,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not set in .env file');
    }

    final contextInfo = currentRoomId != null
        ? 'User is currently at: $currentRoomId on floor $currentFloor. '
        : currentFloor != null
            ? 'User is on floor $currentFloor. '
            : '';

    final fullPrompt = '$_systemPrompt\n\nUser: $contextInfo$userQuery';

    try {
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl/models/gemini-2.0-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': [{'text': fullPrompt}]}
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode} — ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawText = (data['candidates'] as List?)?.firstOrNull?['content']?['parts']?.firstOrNull?['text'] ?? '';

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .replaceAll('json', '')
          .trim();

      Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Expected Map<String, dynamic>');
        }
        json = decoded;
      } catch (e) {
        return AINavigationResult(
          answer: cleaned.isNotEmpty ? cleaned : 'I understand your request. Please try asking for a specific room.',
          targetRoomId: null,
          floor: null,
          steps: [],
          pathPoints: [],
        );
      }

      List<Offset> pathPoints = [];
      if (json['path_points'] != null) {
        final points = json['path_points'] as List<dynamic>;
        for (final point in points) {
          if (point is Map<String, dynamic>) {
            final x = (point['x'] as num?)?.toDouble() ?? 0.5;
            final y = (point['y'] as num?)?.toDouble() ?? 0.5;
            pathPoints.add(Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0)));
          }
        }
      }

      return AINavigationResult(
        answer: json['answer'] as String? ?? 'I found your destination!',
        targetRoomId: json['target_room_id'] as String?,
        floor: json['floor'] as String?,
        steps: (json['steps'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
        pathPoints: pathPoints,
      );
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Failed to get AI navigation: $e');
    }
  }
}