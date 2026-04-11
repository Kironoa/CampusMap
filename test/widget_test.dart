import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard UI content test', (WidgetTester tester) async {
    // 1. Pump the Dashboard directly for a faster UI-specific test
    // Wrap it in a MaterialApp so it has access to the Poppins font and theme
    await tester.pumpWidget(const MaterialApp(home: StudentPalApp()));

    // 2. Verify the Header
    expect(find.text('Student Pal'), findsOneWidget);
    expect(find.text('Hi, Kirigaya'), findsOneWidget);

    // 3. Verify Sections
    expect(find.text('Class Progress'), findsOneWidget);
    expect(find.text('Study Notes'), findsOneWidget);

    // 4. Check for the profile icon inside the avatar
    expect(find.byIcon(Icons.person), findsOneWidget);

    // 5. Test interaction: Tap the Study Notes resource
    await tester.tap(find.text('Study Notes'));
    await tester.pumpAndSettle();
  });
}
