// lib/services/app_help.dart
//
// Offline help content for the in-app assistant chat.
//
// The chat's purpose is to teach users HOW TO USE the app (every screen and
// flow) — it does not give directions itself. Room-to-room routing lives in
// the Floor Plan (indoor) and Live Navigation (outdoor) screens; this file
// only explains how to reach and operate them.
//
// Pure Dart (no Flutter imports) so answers stay unit-testable on the VM.
// To add a topic: add a keyword branch in [answerFor] and cover it in
// test/services/app_help_test.dart.
class AppHelp {
  AppHelp._();

  /// Greeting shown when the help chat opens.
  static const String greeting =
      'Hi! I\'m the NaviApp guide — ask me how to use any part of the app.\n\n'
      'Try:\n'
      '- "How do I scan a QR code?"\n'
      '- "How do I get directions indoors?"\n'
      '- "How does Live Navigation work?"';

  /// Short capability summary used by the info button and "help" queries.
  static const String capabilities =
      'I explain how to use the app:\n'
      '- Scan a starting-point QR code\n'
      '- Explore Floor Plans and navigate to rooms\n'
      '- Use outdoor Live Navigation with GPS\n'
      '- Switch between buildings and indoor maps\n'
      '- Voice replies and dark mode\n\n'
      'Ask e.g. "How do I scan?", "How do I navigate to a room?", or "The map is blank".';

  /// Answers a free-text how-to question. Never returns an empty string.
  static String answerFor(String query) {
    final t = query.toLowerCase();

    // Word-boundary match so "which"/"vehicle" don't trip on the "hi" in
    // "hello"/"hi"/"hey".
    if (RegExp(r'\b(hello|hi|hey|good morning|good afternoon)\b').hasMatch(t)) {
      return 'Hello! $capabilities';
    }
    if (t.contains('thank')) {
      return 'You\'re welcome! Ask me anytime you get stuck using the app.';
    }
    // Troubleshooting first: users describing a problem should get fixes,
    // even when their message also names a screen.
    if (_containsAny(t, ['blank', 'loading', 'not loading', 'empty map', 'grey', 'gray'])) {
      return _mapBlank;
    }
    if (_containsAny(t, ['no internet', 'offline', 'no connection', 'no signal', 'no wifi'])) {
      return _offline;
    }
    if (_containsAny(t, ['permission', 'denied', 'blocked', 'allow location', 'gps off', 'location off'])) {
      return _permissions;
    }
    if (_containsAny(t, ['invalid qr', 'wrong qr', 'qr not working', 'qr doesn\'t', 'qr doesnt', 'can\'t scan', 'cant scan', 'camera'])) {
      return _qrTrouble;
    }
    if (_containsAny(t, ['no path', 'no route', 'accessible path', 'can\'t find path', 'cant find path', 'not connected'])) {
      return _noPath;
    }
    if (_containsAny(t, ['qr', 'scan', 'starting point'])) {
      return _qrScan;
    }
    if (_containsAny(t, ['live navigation', 'live nav', 'outdoor', 'gps']) ||
        (_containsAny(t, ['navigate', 'navigation', 'direction', 'route', 'go to']) &&
            _containsAny(t, ['outside', 'gps', 'map', 'pin', 'drive', 'walk outside']))) {
      return _liveNav;
    }
    if (_containsAny(t, [
      'gate 1',
      'gate 2',
      'gate 3',
      'gate 4',
      'gate 5',
      'gates',
      'vehicle',
      'visitor',
      'which gate',
    ])) {
      return _entrances;
    }
    if (_containsAny(t, ['building', 'enter', 'indoor map', 'switch to indoor', 'prompt', 'continue to'])) {
      return _buildingHandoff;
    }
    if (_containsAny(t, ['recenter', 'follow', 'lost', 'off-route', 'off route', 'rerout'])) {
      return _followReroute;
    }
    if (_containsAny(t, ['style', 'layers', 'dark map', 'bright', 'streets', 'positron'])) {
      return _mapStyle;
    }
    if (_containsAny(t, ['floor plan', 'floorplan', 'indoor']) ||
        (_containsAny(t, ['navigate', 'navigation', 'direction', 'route', 'room']) &&
            !_containsAny(t, ['outside', 'gps', 'live']))) {
      return _floorPlan;
    }
    if (_containsAny(t, ['room list', 'find room', 'search room', 'choose room', 'sheet'])) {
      return _roomSheet;
    }
    if (_containsAny(t, ['voice', 'speak', 'speech', 'sound', 'read aloud', 'tts', 'speaker', 'mute'])) {
      return _voice;
    }
    if (_containsAny(t, ['dark mode', 'dark theme', 'light mode', 'theme'])) {
      return _darkMode;
    }
    if (_containsAny(t, ['home', 'main screen', 'menu', 'cards', 'start'])) {
      return _home;
    }
    if (_containsAny(t, ['help', 'how do i', 'how to', 'how can', 'what can you', 'guide', 'tutorial', 'use the app', 'use this app'])) {
      return capabilities;
    }
    // User asked for directions to a place: this chat no longer routes —
    // point at the screens that do.
    if (_containsAny(t, ['navigate', 'navigation', 'go to', 'get to', 'where is', 'direction', 'route to'])) {
      return _directionsRedirect;
    }
    return _fallback;
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }

  static const String _fallback =
      'I help with using the app — I don\'t give directions myself.\n\n'
      'Ask me things like:\n'
      '- "How do I scan a QR code?"\n'
      '- "How do I navigate to a room?"\n'
      '- "How does Live Navigation work?"';

  static const String _directionsRedirect =
      'I don\'t compute routes here — but getting directions is easy:\n\n'
      'INDOORS (rooms, stairs, elevator):\n'
      'Home → Floor Plan → Navigate → pick the floor tab → tap the room.\n\n'
      'OUTDOORS (GPS, buildings):\n'
      'Home → Live Navigation → tap the map to drop a pin → Start.\n\n'
      'Ask me "How do I navigate to a room?" or "How does Live Navigation work?" for the full steps.';

  static const String _home =
      'HOME SCREEN ("TCGC Guide") — your hub:\n'
      '- "Scan Starting Point": opens the camera to scan a posted QR code, then opens the Floor Plan at your spot.\n'
      '- "Floor Plan": opens the indoor map directly to explore.\n'
      '- "App Help" (this chat): how-to answers like this one.\n'
      '- "Live Navigation": outdoor GPS map with turn-by-turn.\n'
      'Top-right sun/moon icon toggles dark mode.';

  static const String _qrScan =
      'HOW TO SCAN A STARTING POINT:\n'
      '1. Home → "Scan Starting Point" (or the Scan button on the Floor Plan).\n'
      '2. Point the camera at a posted green Campus Guide QR code until it reads.\n'
      '3. The Floor Plan opens on the right floor, centered on "You are here".\n\n'
      'That pin becomes your route start. Tap X on the location card to clear it and resume live positioning.';

  static const String _qrTrouble =
      'QR TROUBLESHOOTING:\n'
      '- "Invalid Campus Guide QR Code" means the code isn\'t one of ours — scan a posted green campus code, not a random QR.\n'
      '- Blurry in the viewfinder? Hold steady, move closer, and make sure the room light is on.\n'
      '- "Camera unavailable": grant camera permission in system Settings, then retry.\n'
      '- Wrong spot pinned? Scan the code at your actual location again — the newest scan wins.';

  static const String _floorPlan =
      'FLOOR PLAN (indoor map) — HOW TO USE:\n'
      '1. Home → "Floor Plan". The phone rotates to landscape automatically.\n'
      '2. Switch floors with the bottom bar: Ground, 2nd, 3rd.\n'
      '3. Pinch to zoom, drag to pan and explore rooms.\n'
      '4. Tap "Navigate" (left panel) → pick a floor tab → tap a room. The green dotted route draws from S (start) to E (end).\n'
      '5. If you scanned a QR first, your "You are here" pin is the start — tap "Start Navigation" on its card.';

  static const String _roomSheet =
      'PICKING A ROOM (Where do you want to go?):\n'
      'Tap "Navigate" on the Floor Plan to open the room sheet.\n'
      'Switch tabs (Ground / 2nd Floor / 3rd Floor), scroll, and tap a room.\n'
      'You\'ll briefly see "Finding route to..." then the dotted route appears and the sheet closes.\n'
      '"No accessible path" means the corridors don\'t connect those two spots — try a nearer staircase or entrance.';

  static const String _liveNav =
      'LIVE NAVIGATION (outdoor GPS) — HOW TO USE:\n'
      '1. Home → "Live Navigation" and grant location permission when asked.\n'
      '2. Tap the map to drop a red pin (or use the top bar to type coordinates).\n'
      '3. A preview card shows distance/time options — tap one, then "Start".\n'
      '4. Follow the top banner (next turn + distance) and the bottom panel (ETA + remaining).\n'
      '5. "Stop" ends guidance and returns to preview.\n\n'
      'Needs internet: map tiles stream online. Buildings show as peach shapes with name labels.';

  static const String _buildingHandoff =
      'ENTERING A BUILDING (outdoor → indoor):\n'
      'When GPS shows you entering a mapped building (Main, Annex, or Tangub Asenso), a popup asks: "You are about to enter [name]. Continue to the indoor map?"\n'
      '- "Continue" opens that building\'s Floor Plan.\n'
      '- "Not now" stays outdoors; you won\'t be asked again until you leave and re-enter.\n'
      'Tip: GPS is weak indoors, so step inside then scan the room\'s QR code to pin your exact spot.';

  static const String _followReroute =
      'STAYING ON ROUTE OUTDOORS:\n'
      '- The camera follows you while navigating. Drag the map and follow pauses; tap the target (my-location) button to recenter.\n'
      '- Stray off the line and the banner shows rerouting, then "Route updated."\n'
      '- Arrival shows "You have arrived at your destination."';

  static const String _mapStyle =
      'MAP STYLES:\n'
      'The map opens in satellite mode. Tap the layers icon (top-right of Live Navigation) to cycle Satellite → Streets → Bright → Light. It only changes how the base map looks — GPS dot, routes, peach buildings, gates, and labels stay the same.';

  static const String _entrances =
      'CAMPUS GATES — WHO USES WHICH:\n'
      '- Gate 1: student walk-in entrance only.\n'
      '- Gate 2: vehicle entrance for anyone with a vehicle.\n'
      '- Gate 3: walk-in entrance for visitors, OJT, and faculty; vehicle and walk-in exit.\n'
      '- Gate 4: exit only for vehicles and walk-ins.\n'
      '- Gate 5: alternative walk-in entrance or exit.\n\n'
      'Green "Gate N" pills mark each gate on the outdoor map — tap one for its rules and a "Navigate here" shortcut.';

  static const String _voice =
      'VOICE REPLIES IN THIS CHAT:\n'
      '- Top speaker icon: speaks every reply aloud / mutes them.\n'
      '- Small speaker under each of my messages: replays / stops that one message.\n'
      'Text always works even where audio is unavailable.';

  static const String _darkMode =
      'DARK MODE:\n'
      'Tap the sun/moon icon on the Home top bar. It recolors the app chrome and chat bubbles; the outdoor map tiles change separately via the layers button.';

  static const String _mapBlank =
      'MAP IS BLANK / STUCK ON "Loading map…":\n'
      'Live Navigation tiles need internet — that message over 12 seconds means check your connection.\n'
      'Indoor Floor Plans are bundled images, so they work offline: if those load but the outdoor map doesn\'t, it\'s the network, not the app.';

  static const String _offline =
      'NO INTERNET — WHAT STILL WORKS:\n'
      '- Floor Plans (bundled images), QR scanning, and room sheets: fully work.\n'
      '- Live Navigation tiles and routes need a connection and will fail gracefully — reconnect and re-pick your destination.';

  static const String _permissions =
      'LOCATION PERMISSION / GPS:\n'
      '- "Location permission needed": tap "Grant permission".\n'
      '- "Location blocked": you permanently denied it — tap "Open Settings" and enable Location for NaviApp.\n'
      '- "GPS is turned off": tap "Open location settings" and turn location services on.\n'
      'Live Navigation needs GPS for the blue dot, routes, and building entry prompts.';

  static const String _noPath =
      '"NO ACCESSIBLE PATH" — WHAT IT MEANS:\n'
      'The corridors/stairs on the map don\'t connect those two spots.\n'
      'Try: a nearer staircase or entrance as your start, the correct floor tab, or re-scan the QR at your real spot so the start is exact.';
}
