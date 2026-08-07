// lib/config/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get openrouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
}