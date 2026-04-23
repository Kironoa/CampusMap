import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = "AIzaSyBFheu_5ytEB5ph5VIXtLMBmUkbrw1Gtek";
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;

  final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService._internal()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash-lite',
          apiKey: _apiKey,
        ) {
    _chatSession = _model.startChat();
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
