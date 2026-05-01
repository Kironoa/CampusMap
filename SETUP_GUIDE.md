# Campus Map Upgrade - Setup Guide

## New Dependencies Added
- `google_maps_flutter: ^2.5.0` - Google Maps integration
- `google_generative_ai: ^0.4.6` - Gemini AI for floor plan analysis
- `sqflite: ^2.3.0` - Local SQLite database for offline caching
- `path_provider: ^2.1.5` - File system paths
- `path: ^1.8.3` - Path manipulation

## Environment Variables (.env file)
Add these to your `.env` file:
```
GOOGLE_MAPS_API_KEY=your_actual_maps_api_key
GOOGLE_GEMINI_API_KEY=your_actual_gemini_api_key
```

## Android Setup
The API key is injected via `AndroidManifest.xml` using manifest placeholders.
You can pass it during build:
```bash
flutter build apk -P MAPS_API_KEY=your_api_key
```

Or set environment variable:
```bash
export MAPS_API_KEY=your_api_key
flutter build apk
```

## iOS Setup
Add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
GMSServices.provideAPIKey("your_api_key")
```

## Features Implemented

### 1. AI Walkthrough Service (`lib/services/gemini_walkthrough_service.dart`)
- Analyzes floor plan images using Gemini 1.5 Flash
- Returns structured walkthrough steps with coordinates
- Handles image as Uint8List for model input
- Strips markdown from AI responses

### 2. Campus Map Screen (`lib/screens/campus_map_screen.dart`)
- Google Maps with custom styling
- Search bar for campus buildings
- Floating action button for centering on user location
- Floor plan overlay with AI walkthrough
- Poppins font throughout

### 3. Database Layer (`lib/data/database_helper.dart`)
- SQLite database for caching landmarks and floor plan steps
- Offline functionality once data is loaded
- Tables: `landmarks`, `floor_plan_steps`

### 4. Repository Pattern (`lib/repositories/`)
- `LandmarkRepository` - Abstract interface
- `LocalLandmarkRepository` - SQLite implementation

### 5. Error Handling (`lib/utils/error_handler.dart`)
- User-friendly error messages
- Handles network, location, API, and database errors
- Translates technical errors for students

## Usage

### Navigate to Campus Map
```dart
Navigator.pushNamed(context, '/campus_map');
```

### Using the AI Floor Plan Walkthrough
1. Tap the layers FAB (bottom right)
2. Select a floor plan (Second Floor or Ground Floor)
3. AI analyzes the image and creates a walkthrough
4. Use Next/Previous buttons to navigate steps
5. Steps are cached for offline use

## Floor Plan Images
Place your floor plan images in `assets/images/`:
- `second_floor.png`
- `ground_floor.png`

## Database Initialization
The database is automatically initialized on first app launch.
Default landmarks are cached from `campus_landmarks.dart`.

## Error Messages
The app shows user-friendly messages for:
- No internet connection
- Location services disabled
- API configuration errors
- Database access issues
