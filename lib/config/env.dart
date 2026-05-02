import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get anthropicApiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}