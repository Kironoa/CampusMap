import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:naviapp/data/campus_landmarks.dart';
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/config/env.dart';

class AINavigationResult {
  final String answer;
  final String? targetRoomId;
  final String? targetLandmarkId;
  final String? floor;
  final List<String> steps;

  AINavigationResult({
    required this.answer,
    this.targetRoomId,
    this.targetLandmarkId,
    this.floor,
    this.steps = const [],
  });
}

class AINavigationService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-opus-4-5';

  static String _buildSystemPrompt() {
    final groundRooms = FloorPlanData.groundFloorRooms
        .map((r) => '  • [${r.id}] ${r.name} (${r.category})'
            '${r.description != null ? ' — ${r.description}' : ''}')
        .join('\n');

    final secondRooms = FloorPlanData.secondFloorRooms
        .map((r) => '  • [${r.id}] ${r.name} (${r.category})'
            '${r.description != null ? ' — ${r.description}' : ''}')
        .join('\n');

    final landmarks = tcgcLandmarks
        .map((l) => '  • [${l.id}] ${l.name} (${l.category})'
            '${l.floor != null ? ' on ${l.floor}' : ''} — ${l.description}')
        .join('\n');

    return '''
You are the AI Navigation Assistant for Tangub City Global College (TCGC) campus.
You have complete knowledge of every room, office, lab, and facility in the campus.

═══════════════════════════════════════════
GROUND FLOOR — 12 rooms/areas:
$groundRooms

SECOND FLOOR — 34 rooms/areas:
$secondRooms

OUTDOOR LANDMARKS — 19 locations:
$landmarks
═══════════════════════════════════════════

Your job is to:
1. Understand the user's navigation request in natural language (English or Filipino).
2. Identify the BEST matching room/office/lab from the list above.
3. Give clear step-by-step walking directions appropriate to their current position.
4. Return a JSON object ONLY — no markdown, no extra text.

JSON format:
{
  "answer": "Friendly 1-2 sentence response with directions summary",
  "target_room_id": "the exact id from the floor plan data (or null if outdoor only)",
  "target_landmark_id": "the exact id from tcgcLandmarks (or null if indoor only)",
  "floor": "ground | second | outdoor",
  "steps": [
    "Step 1: ...",
    "Step 2: ...",
    "Step 3: ..."
  ]
}

If the user asks something that isn't navigation-related, still return the JSON with a helpful answer and null for room/landmark IDs.
''';
  }

  static Future<AINavigationResult> navigate({
    required String userQuery,
    String? currentFloor,
    String? currentRoomId,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    final apiKey = Env.anthropicApiKey;
    if (apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY not set. Add it to your .env file.');
    }

    final contextPrefix = currentRoomId != null
        ? 'User is currently at: $currentRoomId on $currentFloor floor. '
        : currentFloor != null
            ? 'User is on the $currentFloor floor. '
            : '';

    final messages = [
      ...conversationHistory,
      {
        'role': 'user',
        'content': '$contextPrefix$userQuery',
      }
    ];

    try {
      final dio = Dio();
      final response = await dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        ),
        data: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': _buildSystemPrompt(),
          'messages': messages,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AI API error: ${response.statusCode} — ${response.data}');
      }

      final data = response.data as Map<String, dynamic>;
      final rawText = (data['content'] as List)
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('');

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      return AINavigationResult(
        answer: json['answer'] as String? ?? 'I found your destination!',
        targetRoomId: json['target_room_id'] as String?,
        targetLandmarkId: json['target_landmark_id'] as String?,
        floor: json['floor'] as String?,
        steps: (json['steps'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
      );
    } catch (e) {
      throw Exception('Failed to get AI navigation: $e');
    }
  }
}
