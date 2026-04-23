import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static String? _apiKey;
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService._internal();

  static Future<void> initialize() async {
    await dotenv.load();
    _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _instance._model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: _apiKey!,
    );
    _instance._chatSession = _instance._model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession?.sendMessage(Content.text(message));
      return response?.text ?? "I couldn't generate a response.";
    } catch (e) {
      if (e.toString().contains('429')) {
        return "Quota exceeded for today. Please try your new API key!";
      }
      return "Error: $e";
    }
  }
}