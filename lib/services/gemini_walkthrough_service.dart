import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env.dart';
import '../data/floor_plan_step.dart';

class GeminiWalkthroughService {
  static const String _modelName = 'gemini-1.5-flash';
  static const String _defaultMime = 'image/png';

  Future<List<FloorPlanStep>> analyzeFloorPlan({
    required File imageFile,
    required String floorPlanId,
  }) async {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('GOOGLE_GEMINI_API_KEY not set in .env file');
    }

    final model = GenerativeModel(model: _modelName, apiKey: apiKey);

    final Uint8List imageBytes;
    try {
      imageBytes = await imageFile.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read image file: $e');
    }

    final mimeType = _inferMimeType(imageFile.path);

    const prompt = '''
Analyze this floor plan image and create a walkthrough path.
Return ONLY a JSON array with no markdown formatting or extra text.
Each step must have:
- "description": Clear description of the area/room
- "x": Relative x-coordinate (0.0 to 1.0, left to right)
- "y": Relative y-coordinate (0.0 to 1.0, top to bottom)

The walkthrough should follow a logical path through the floor plan, starting from the main entrance.
Example format: [{"description": "Main Entrance", "x": 0.5, "y": 0.9}, {"description": "Reception Area", "x": 0.5, "y": 0.7}]
''';

    try {
      final content = [
        Content.multi([
          DataPart(mimeType, imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await model.generateContent(content);
      final rawText = response.text?.trim() ?? '';

      if (rawText.isEmpty) {
        throw Exception('Empty response from Gemini AI');
      }

      final cleanedText = _stripMarkdown(rawText);
      final decoded = jsonDecode(cleanedText);

      if (decoded is! List) {
        throw Exception('Response is not a valid JSON array');
      }

      return decoded.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        return FloorPlanStep(
          floorPlanId: floorPlanId,
          description: item['description'] as String,
          x: (item['x'] as num).toDouble(),
          y: (item['y'] as num).toDouble(),
          stepOrder: index,
        );
      }).toList();
    } catch (e) {
      throw Exception('Floor plan analysis failed: $e');
    }
  }

  String _inferMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return _defaultMime;
    }
  }

  String _stripMarkdown(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}
