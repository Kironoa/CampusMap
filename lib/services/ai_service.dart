import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // Get your key from https://aistudio.google.com/
  static const String _apiKey = "YOUR_GEMINI_API_KEY";

  final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService()
      : _model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: _apiKey,
            // System instructions give your AI a "personality"
            systemInstruction: Content.system(
                "You are Student Pal, a helpful AI tutor. "
                "Keep answers concise, use bullet points for clarity, and encourage students.")) {
    // Start a multi-turn chat session
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chatSession?.sendMessage(Content.text(message));
      return response?.text ?? "I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
