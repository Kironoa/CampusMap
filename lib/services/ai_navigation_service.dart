import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:naviapp/data/floor_plan_data.dart';
import 'package:naviapp/models/room.dart';
import 'package:naviapp/config/env.dart';

class AINavigationResult {
  final String answer;
  final String? targetRoomId;
  final String? floor;
  final List<String> steps;

  AINavigationResult({
    required this.answer,
    this.targetRoomId,
    this.floor,
    this.steps = const [],
  });
}

class AINavigationService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';

  static String _buildSystemPrompt() {
    final groundRooms = FloorPlanData.groundFloorRooms
        .map(
          (r) =>
              '  • [${r.id}] ${r.name} (${r.category.name})'
              '${r.description != null ? ' — ${r.description}' : ''}',
        )
        .join('\n');

    final secondRooms = FloorPlanData.secondFloorRooms
        .map(
          (r) =>
              '  • [${r.id}] ${r.name} (${r.category.name})'
              '${r.description != null ? ' — ${r.description}' : ''}',
        )
        .join('\n');

    final thirdRooms = FloorPlanData.thirdFloorRooms
        .map(
          (r) =>
              '  • [${r.id}] ${r.name} (${r.category.name})'
              '${r.description != null ? ' — ${r.description}' : ''}',
        )
        .join('\n');

    return '''
You are the AI Navigation Assistant for Tangub City Global College (TCGC) campus.
You have complete knowledge of every room, office, lab, and facility in the campus.

═════════════════════════════════════════
FLOOR 0 (Ground / First Floor — physically the same level) — rooms/areas:
$groundRooms

FLOOR 1 (Second Floor) — rooms/areas:
$secondRooms

FLOOR 2 (Third Floor) — rooms/areas:
$thirdRooms
═════════════════════════════════════════

NOTE: "Ground Floor" and "First Floor" are the SAME physical level (Floor 0).
If the user says "Ground" or "First" floor, map to floor_index: "0".

NAVIGATION CONTEXT:
- Main entrance is on Floor 0 (Ground/First) at the Main Lobby (center of building)
- Elevator is located at the center of all floors
- West stairs and East stairs connect all floors
- Floor 0 contains: Registrar, VP Admin, Library, ICJE, ICS, TCGC Training, Health Sciences
- Floor 0 also contains: Arts & Sciences, Teacher Ed, Business, Clinic, AVR, Music, Dance
- Floor 1 (Second Floor) has: Computer Labs, Moot Court, Business Center, President's Office
- Floor 1 (Second Floor) center: VP offices, Board Room, HR Office, Faculty Lounge
- Floor 2 (Third Floor) has: Library extension, Classrooms, Science Lab
- Always mention which floor the destination is on
- If user needs to change floors, mention taking the stairs or elevator

Your job is to:
1. Understand the user's navigation request in natural language (English or Filipino).
2. Identify the BEST matching room/office/lab from the list above.
3. Give clear step-by-step walking directions appropriate to their current position.
4. Return a JSON object ONLY — no markdown, no extra text.

JSON format:
{
  "answer": "Friendly 1-2 sentence response with directions summary",
  "target_room_id": "the exact id from the floor plan data (or null)",
  "floor": "0 | 1 | 2",
  "steps": [
    "Step 1: ...",
    "Step 2: ...",
    "Step 3: ..."
  ]
}

IMPORTANT:
- Use "floor": "0" for Ground OR First floor requests
- Use "floor": "1" for Second floor requests
- Use "floor": "2" for Third floor requests
- If asked about floors other than 0, 1, or 2, politely say data not yet available

If the user asks something that isn't navigation-related, still return the JSON with a helpful answer and null for room ID.
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
        ? 'User is currently at: $currentRoomId on floor $currentFloor. '
        : currentFloor != null
            ? 'User is on floor $currentFloor. '
            : '';

    final messages = [
      ...conversationHistory,
      {
        'role': 'user',
        'content': '$contextPrefix$userQuery',
      }
    ];

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': _buildSystemPrompt(),
          'messages': messages,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'AI API error: ${response.statusCode} — ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawText = (data['content'] as List)
          .where((c) => c['type'] == 'text')
          .map((c) => c['text'] as String)
          .join('');

      final cleaned = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(cleaned);
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Parse error: expected Map<String, dynamic>');
        }
        json = decoded;
      } catch (e) {
        throw Exception(
          'AI returned an unexpected response format. Please try again.',
        );
      }

      return AINavigationResult(
        answer: json['answer'] as String? ?? 'I found your destination!',
        targetRoomId: json['target_room_id'] as String?,
        floor: json['floor'] as String?,
        steps:
            (json['steps'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [],
      );
    } catch (e) {
      throw Exception('Failed to get AI navigation: $e');
    }
  }

  static String? getRoomDirections(String roomName) {
    final query = roomName.toLowerCase().trim();

    for (final floor in [
      FloorPlanData.groundFloorRooms,
      FloorPlanData.secondFloorRooms,
      FloorPlanData.thirdFloorRooms,
    ]) {
      for (final room in floor) {
        if (room.name.toLowerCase().contains(query) ||
            query.contains(room.name.toLowerCase())) {
          return "The ${room.name} is located on Floor ${_floorIndexOf(floor)}.";
        }
      }
    }

    return null;
  }

  static String _floorIndexOf(List<Room> floor) {
    if (floor == FloorPlanData.groundFloorRooms) return '0 (Ground/First)';
    if (floor == FloorPlanData.secondFloorRooms) return '1 (Second)';
    if (floor == FloorPlanData.thirdFloorRooms) return '2 (Third)';
    return '0';
  }
}
