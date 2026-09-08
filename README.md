# TCGC Guide

**TCGC Guide** is a specialized campus navigation app with AI assistance. Built with Flutter, it combines indoor navigation, schedule management, resource organization, and AI-driven support into a single, intuitive interface.

## Core Features

* **Indoor Navigation:** Find your way around Tangub City Global College using BLE beacon-based indoor positioning and a custom navigation graph.
* **AI Study Assistant:** A generative AI chat powered by OpenRouter/Gemini to help clarify complex concepts.
* **QR Code Location Pinning:** Scan QR codes at known locations to instantly set your starting position.
* **Multi-floor Routing:** Navigate across Ground, 2nd, and 3rd floors with staircase/elevator transitions.
* **Live Position Tracking:** Real-time indoor position updates via BLE beacons with Kalman filtering.
* **Offline-First Design:** Core navigation works without network connectivity; AI features require internet.

## Architecture

- `lib/services/navigation_graph.dart` — Navigation nodes, edges, floor transitions, and room-to-node mapping.
- `lib/services/pathfinder.dart` — A* pathfinding on the navigation graph.
- `lib/services/route_calculator.dart` — High-level routing from live position, QR scan, or manual start.
- `lib/services/room_catalog.dart` — Canonical room list with names and IDs per floor.
- `lib/services/indoor_positioning/` — BLE scanning, RSSI buffering, position estimation, and floor detection.
- `lib/services/ai_navigation_service.dart` — AI-generated turn-by-turn directions via OpenRouter (Gemini).
- `lib/widgets/ai_nav_sheet.dart` — Bottom sheet UI for selecting start point and destination.

## Getting Started

1. `flutter pub get`
2. Configure `lib/config/env.dart` with your OpenRouter API key.
3. `flutter run`

## Testing

`flutter test` runs the full test suite including widget tests for the navigation sheet, QR flow, and indoor positioning unit tests.