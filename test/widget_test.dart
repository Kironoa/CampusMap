import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  testWidgets('Login screen shows username field, password field, and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StudentPalLogin()),
    );

    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextButton), findsAtLeastNWidgets(2));
  });

  testWidgets('Login shows error when fields are empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: StudentPalLogin()),
    );

    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Fields cannot be empty.'), findsOneWidget);
  });
}