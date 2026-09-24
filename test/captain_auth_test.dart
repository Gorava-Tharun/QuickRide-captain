import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Captain registration and login authentication cycle', () async {
    final auth = CaptainAuthService();

    // 1. Initial Seed Captain Login Check
    final seedLogin = await auth.loginCaptain(
      phone: '9876543210',
      password: 'password123',
    );
    expect(seedLogin['success'], isTrue);
    expect(seedLogin['account'].name, 'Rajesh Kumar');

    // 2. Active Session check
    final active = await auth.getActiveSession();
    expect(active, isNotNull);
    expect(active?.phone, '9876543210');

    // 3. Register New Captain
    final regResult = await auth.registerCaptain(
      name: 'Sunil Gowda',
      phone: '9123456789',
      email: 'sunil@quickride.com',
      password: 'captainsecret',
      vehicleNumber: 'KA-04-TR-9999',
      licenseNumber: 'DL-KA042023001',
    );
    expect(regResult['success'], isTrue);

    // 4. Duplicate Registration Check
    final dupResult = await auth.registerCaptain(
      name: 'Duplicate Gowda',
      phone: '9123456789',
      email: 'other@quickride.com',
      password: 'captainsecret',
      vehicleNumber: 'KA-04-TR-9999',
      licenseNumber: 'DL-KA042023001',
    );
    expect(dupResult['success'], isFalse);

    // 5. Wrong Password Login
    final wrongPass = await auth.loginCaptain(
      phone: '9123456789',
      password: 'wrongpassword',
    );
    expect(wrongPass['success'], isFalse);

    // 6. Correct Password Login
    final correctLogin = await auth.loginCaptain(
      phone: '9123456789',
      password: 'captainsecret',
    );
    expect(correctLogin['success'], isTrue);
    expect(correctLogin['account'].name, 'Sunil Gowda');

    // 7. Password Reset
    final resetResult = await auth.resetPassword(
      phone: '9123456789',
      newPassword: 'newcaptainpass123',
    );
    expect(resetResult['success'], isTrue);

    // 8. Login with New Password
    final newPassLogin = await auth.loginCaptain(
      phone: '9123456789',
      password: 'newcaptainpass123',
    );
    expect(newPassLogin['success'], isTrue);

    // 9. Logout
    await auth.logout();
    final clearedSession = await auth.getActiveSession();
    expect(clearedSession, isNull);
  });
}
