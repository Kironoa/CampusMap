import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/services/route_calculator.dart';
import 'package:naviapp/widgets/ai_nav_sheet.dart';

void main() {
  group('AINavSheet', () {
    testWidgets('immediately shows room list (no starting-point step)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AINavSheet(currentFloorIndex: 0, onNavigationResult: (_) {}),
          ),
        ),
      );

      // Should immediately show room list, not starting point step
      expect(find.text('📍 Where are you starting from?'), findsNothing);
      expect(find.text('Select your current location:'), findsNothing);
      expect(find.text('🏁 Where do you want to go?'), findsOneWidget);
      // No search bar
      expect(find.byType(TextField), findsNothing);
      // Should show room list
      expect(find.text('Main Lobby'), findsOneWidget);
    });

    testWidgets('tapping a room calls onNavigationResult with non-empty path', (
      WidgetTester tester,
    ) async {
      NavigationResult? capturedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AINavSheet(
              currentFloorIndex: 0,
              onNavigationResult: (result) => capturedResult = result,
            ),
          ),
        ),
      );

      // Tap a room directly (no starting point step)
      await tester.tap(find.text('Main Lobby').first);
      await tester.pumpAndSettle();

      expect(capturedResult, isNotNull);
      expect(capturedResult!.path, isNotEmpty);
    });
  });
}
