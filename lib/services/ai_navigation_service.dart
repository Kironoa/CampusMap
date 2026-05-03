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

  Future<AINavigationResult> navigate({
    required String roomName,
    required String roomId,
    required String floorImagePath,
    required int floorIndex,
  }) async {
    if (_apiKey == null) {
      _apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (_apiKey!.isEmpty) {
        return _generateLocalPath(roomId, floorIndex, roomName);
      }
    }

    final prompt = _buildPrompt(roomName, roomId, floorIndex);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {'inlineData': {'mimeType': 'image/png', 'data': ''}}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseSchema': {
              'type': 'OBJECT',
              'properties': {
                'answer': {'type': 'STRING'},
                'floor': {'type': 'STRING'},
                'steps': {'type': 'ARRAY', 'items': {'type': 'STRING'}},
                'path_points': {
                  'type': 'ARRAY',
                  'items': {
                    'type': 'OBJECT',
                    'properties': {
                      'x': {'type': 'NUMBER'},
                      'y': {'type': 'NUMBER'},
                    },
                  },
                },
              },
            },
          },
        }),
      );

      if (response.statusCode == 429) {
        return AINavigationResult(
          answer: 'AI quota exceeded. Using local navigation to $roomName.',
          floor: floorIndex.toString(),
          pathPoints: _getLocalPathPoints(roomId, floorIndex),
          steps: ['Follow the highlighted path to reach $roomName.'],
        );
      }

      if (response.statusCode != 200) {
        return _generateLocalPath(roomId, floorIndex, roomName);
      }

      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]['content']?['parts']?[0]['text'];
      if (content == null || content.isEmpty) {
        return _generateLocalPath(roomId, floorIndex, roomName);
      }

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        return _generateLocalPath(roomId, floorIndex, roomName);
      }

      final parsed = jsonDecode(jsonMatch.group(0)!);
      final pathPoints = (parsed['path_points'] as List)
          .map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()))
          .toList();

      return AINavigationResult(
        answer: parsed['answer'] ?? 'Route found to $roomName',
        floor: parsed['floor'] ?? floorIndex.toString(),
        pathPoints: pathPoints,
        steps: List<String>.from(parsed['steps'] ?? []),
      );
    } catch (e) {
      return _generateLocalPath(roomId, floorIndex, roomName);
    }
  }

  String _buildPrompt(String roomName, String roomId, int floorIndex) {
    return '''You are a campus navigation assistant for Tangub City Global College (TCGC).
You are given an image of a floor plan. Coordinates are normalized: (0,0) = top-left, (1,1) = bottom-right.

The user wants to navigate to: "$roomName" (id: $roomId)

TASK:
1. Find the exact text label "$roomName" in the floor plan image
2. Identify the CENTER of that room as normalized (x, y) coordinates
3. Build a walking path from the main entrance (bottom-center, approximately x:0.50, y:0.95) to the room center
4. The path MUST travel only through white corridor/hallway spaces — never cut through dark-bordered room walls
5. Use the visible corridors: main horizontal corridor running across the building, vertical connector corridors, and the staircase/elevator core near center
6. For duplicate room names (e.g. multiple Rest Rooms), navigate to the specific instance indicated by the room ID suffix (_left, _right, _center)

Return ONLY this JSON (no markdown, no extra text):
{
  "answer": "2-3 sentence friendly walking directions mentioning landmarks",
  "floor": "$floorIndex",
  "steps": ["Step 1...", "Step 2...", "Step 3..."],
  "path_points": [
    {"x": 0.50, "y": 0.95},
    ... at least 8 points following actual corridor paths ...
    {"x": TARGET_X, "y": TARGET_Y}
  ]
}''';
  }

  AINavigationResult _generateLocalPath(String roomId, int floorIndex, String roomName) {
    final pathPoints = _getLocalPathPoints(roomId, floorIndex);

    return AINavigationResult(
      answer: 'Using local navigation to $roomName on floor $floorIndex.',
      floor: floorIndex.toString(),
      pathPoints: pathPoints,
      steps: ['Follow the highlighted path to reach $roomName.'],
    );
  }

  List<Offset> _getLocalPathPoints(String roomId, int floorIndex) {
    final positions = _getPositionMap(floorIndex);
    final targetPos = positions[roomId];

    if (targetPos == null) {
      return [
        const Offset(0.50, 0.95),
        const Offset(0.50, 0.80),
        const Offset(0.50, 0.65),
        const Offset(0.50, 0.50),
        const Offset(0.50, 0.35),
        const Offset(0.50, 0.20),
      ];
    }

    final entrance = const Offset(0.50, 0.95);
    final corridorY = 0.45;
    final path = <Offset>[entrance];

    if (targetPos.dx < 0.30) {
      path.add(Offset(0.30, 0.95));
      path.add(Offset(0.30, corridorY));
    } else if (targetPos.dx > 0.70) {
      path.add(Offset(0.70, 0.95));
      path.add(Offset(0.70, corridorY));
    } else {
      path.add(Offset(targetPos.dx, 0.95));
    }

    path.add(Offset(targetPos.dx, corridorY));
    path.add(targetPos);

    return path;
  }

  Map<String, Offset> _getPositionMap(int floorIndex) {
    switch (floorIndex) {
      case 0:
        return _groundFloorPositions;
      case 1:
        return _secondFloorPositions;
      case 2:
        return _thirdFloorPositions;
      default:
        return _groundFloorPositions;
    }
  }

  static const Map<String, Offset> _groundFloorPositions = {
    'gf_main_lobby': Offset(0.72, 0.72),
    'gf_drive_way': Offset(0.44, 0.92),
    'gf_scholarship_welfare': Offset(0.44, 0.55),
    'gf_ojt_placement': Offset(0.44, 0.65),
    'gf_accreditation': Offset(0.60, 0.72),
    'gf_record_registrar': Offset(0.44, 0.42),
    'gf_registrar': Offset(0.38, 0.42),
    'gf_vp_admin': Offset(0.30, 0.42),
    'gf_crim_lab': Offset(0.17, 0.42),
    'gf_icje': Offset(0.10, 0.42),
    'gf_sldo': Offset(0.03, 0.32),
    'gf_ciso': Offset(0.60, 0.42),
    'gf_avr': Offset(0.68, 0.42),
    'gf_dressing': Offset(0.76, 0.42),
    'gf_music': Offset(0.82, 0.42),
    'gf_dance': Offset(0.89, 0.42),
    'gf_barracks': Offset(0.96, 0.42),
    'gf_medical': Offset(0.64, 0.20),
    'gf_restroom_left': Offset(0.09, 0.20),
    'gf_restroom_center': Offset(0.40, 0.20),
    'gf_restroom_right': Offset(0.86, 0.20),
    'gf_mb105': Offset(0.72, 0.20),
    'gf_mb103': Offset(0.78, 0.20),
    'gf_mpr': Offset(0.84, 0.20),
    'gf_midwifery': Offset(0.90, 0.20),
    'gf_pfom': Offset(0.96, 0.20),
    'gf_ias': Offset(0.48, 0.20),
    'gf_ite': Offset(0.36, 0.20),
    'gf_ibfs': Offset(0.29, 0.20),
    'gf_ihs': Offset(0.24, 0.20),
    'gf_training': Offset(0.18, 0.20),
    'gf_ics': Offset(0.13, 0.20),
    'gf_cr_left1': Offset(0.17, 0.07),
    'gf_cr_left2': Offset(0.19, 0.07),
    'gf_cr_right1': Offset(0.89, 0.07),
    'gf_cr_right2': Offset(0.91, 0.07),
    'gf_elevator': Offset(0.50, 0.42),
  };

  static const Map<String, Offset> _secondFloorPositions = {
    'sf_main_stage': Offset(0.50, 0.12),
    'sf_guidance_testing': Offset(0.04, 0.32),
    'sf_sub_lobby': Offset(0.08, 0.32),
    'sf_computer_lab': Offset(0.18, 0.32),
    'sf_computer_room_1': Offset(0.30, 0.32),
    'sf_computer_room_2': Offset(0.37, 0.32),
    'sf_computer_room_3': Offset(0.43, 0.32),
    'sf_restroom_left': Offset(0.47, 0.32),
    'sf_restroom_center_left': Offset(0.50, 0.32),
    'sf_restroom_center_right': Offset(0.53, 0.32),
    'sf_restroom_right': Offset(0.56, 0.32),
    'sf_vip_lounge': Offset(0.60, 0.32),
    'sf_faculty_lounge': Offset(0.75, 0.32),
    'sf_speech_lab': Offset(0.87, 0.32),
    'sf_bseed_left': Offset(0.97, 0.32),
    'sf_bseed_right': Offset(0.97, 0.55),
    'sf_guidance_counseling': Offset(0.04, 0.55),
    'sf_moot_court': Offset(0.17, 0.55),
    'sf_business_center': Offset(0.30, 0.55),
    'sf_classroom_left': Offset(0.40, 0.55),
    'sf_classroom_center': Offset(0.45, 0.55),
    'sf_classroom_right': Offset(0.50, 0.55),
    'sf_board_room': Offset(0.60, 0.55),
    'sf_hrmo': Offset(0.67, 0.55),
    'sf_faculty_room': Offset(0.75, 0.55),
    'sf_supply': Offset(0.82, 0.55),
    'sf_vp_planning': Offset(0.87, 0.55),
    'sf_evp': Offset(0.92, 0.55),
    'sf_deans': Offset(0.44, 0.70),
    'sf_vpaa': Offset(0.44, 0.80),
    'sf_president': Offset(0.60, 0.75),
    'sf_deck_canopy': Offset(0.50, 0.95),
    'sf_bleacher_left': Offset(0.25, 0.18),
    'sf_bleacher_right': Offset(0.75, 0.18),
  };

  static const Map<String, Offset> _thirdFloorPositions = {
    'tf_prayer': Offset(0.37, 0.15),
    'tf_activity': Offset(0.50, 0.12),
    'tf_research': Offset(0.60, 0.15),
    'tf_library': Offset(0.25, 0.35),
    'tf_lrc1': Offset(0.07, 0.35),
    'tf_lrc2': Offset(0.43, 0.35),
    'tf_elevator': Offset(0.50, 0.35),
    'tf_restroom_left': Offset(0.54, 0.35),
    'tf_restroom_right': Offset(0.57, 0.35),
    'tf_classroom_1': Offset(0.63, 0.35),
    'tf_classroom_2': Offset(0.70, 0.35),
    'tf_classroom_3': Offset(0.76, 0.35),
    'tf_classroom_4': Offset(0.82, 0.35),
    'tf_classroom_5': Offset(0.88, 0.35),
    'tf_science_lab': Offset(0.93, 0.35),
    'tf_classroom_6': Offset(0.98, 0.35),
    'tf_bleacher_left': Offset(0.25, 0.65),
    'tf_bleacher_right': Offset(0.75, 0.65),
    'tf_main_stage': Offset(0.50, 0.75),
  };
}