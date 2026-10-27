import 'package:flutter_test/flutter_test.dart';
import 'package:naviapp/models/user_role.dart';
import 'package:naviapp/providers/user_role_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads a saved role', () async {
    SharedPreferences.setMockInitialValues({'user_role': 'faculty'});
    final provider = UserRoleProvider();

    await provider.loadRole();

    expect(provider.role, UserRole.faculty);
    expect(provider.hasRole, isTrue);
  });

  test('persists a selected role', () async {
    final provider = UserRoleProvider();
    await provider.loadRole();

    await provider.setRole(UserRole.visitor);

    expect(provider.role, UserRole.visitor);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_role'), 'visitor');

    final restored = UserRoleProvider();
    await restored.loadRole();
    expect(restored.role, UserRole.visitor);
  });

  test('ignores an unknown saved role', () async {
    SharedPreferences.setMockInitialValues({'user_role': 'guard'});
    final provider = UserRoleProvider();

    await provider.loadRole();

    expect(provider.role, isNull);
  });
}
