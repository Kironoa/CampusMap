import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/main.dart';

void main() {
  testWidgets('NaviApp smoke test', (WidgetTester tester) async {
    // This now matches the class name in your main.dart
    await tester.pumpWidget(const NaviApp());

    // Verify that the app starts correctly
    expect(find.byType(NaviApp), findsOneWidget);
  });
}
