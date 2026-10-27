import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/models/user_role.dart';
import 'package:naviapp/providers/user_role_provider.dart';
import 'package:naviapp/screens/get_started_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('asks for a role before continuing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final roleProvider = UserRoleProvider();
    await roleProvider.loadRole();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<UserRoleProvider>.value(
          value: roleProvider,
          child: const GetStartedScreen(),
        ),
      ),
    );

    expect(find.text('What is your role?'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Faculty'), findsOneWidget);
    expect(find.text('OJT'), findsOneWidget);
    expect(find.text('Visitor'), findsOneWidget);

    var button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Visitor'));
    await tester.pumpAndSettle();

    expect(roleProvider.role, UserRole.visitor);
    button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });
}
