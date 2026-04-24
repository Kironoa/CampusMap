# TCGC Guide

**TCGC Guide** is a specialized campus navigation app with AI assistance. Built with Flutter, it combines indoor navigation, schedule management, resource organization, and AI-driven support into a single, intuitive interface.

## Core Features

* **Indoor Navigation:** Find your way around Tangub City Global College with Google Maps.
* **AI Study Assistant:** A generative AI chat powered by Gemini to help clarify complex concepts.
* **Class Schedule:** Smart class reminders and schedule management.
* **Resource Center:** Manage academic files and study materials efficiently.
* **Interactive Dashboard:** Quick access to campus navigation and essential student categories.

## Tech Stack

* **Frontend:** Flutter & Dart
* **Backend:** Supabase
* **AI Integration:** Google Generative AI (Gemini API)
* **Maps:** Google Maps Flutter

## Getting Started

### Prerequisites
* Flutter SDK (Stable)
* Supabase Account & API Keys
* Google AI (Gemini) API Key
* Google Maps API Key

### Installation
1. Clone the repo
2. Install dependencies: `flutter pub get`
3. Run: `flutter run`

## Project Structure
* `lib/screens/`: UI for Dashboard, AI Chat, and Navigation
* `lib/services/`: Logic for Notifications, API calls
* `lib/widgets/`: Reusable UI components
* `lib/models/`: Data models
* `lib/providers/`: State management