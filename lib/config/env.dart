// lib/config/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  /// Returns the OpenRouter API key, or '' when .env was not loaded or the
  /// key is missing. Never throws: the AI service falls back to its
  /// hardcoded directions text when the key is empty.
  static String get openrouterApiKey {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }
}