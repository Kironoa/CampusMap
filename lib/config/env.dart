import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get mapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
}