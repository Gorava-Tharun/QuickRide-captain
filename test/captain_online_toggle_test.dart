import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Captain Home Online/Offline toggle and persistence cycle', () async {
    final auth = CaptainAuthService();
    final state = CaptainStateService();

    // 1. Initial login with seed captain
    final loginResult = await auth.loginCaptain(
      phone: '9876543210',
      password: 'password123',
    );
    expect(loginResult['success'], isTrue);
    state.setAccount(loginResult['account']);
    expect(state.isOnline, isTrue);

    // 2. Toggle to Offline
    state.toggleOnlineStatus(false);
    expect(state.isOnline, isFalse);

    // 3. Verify session saved locally as Offline
    var session = await auth.getActiveSession();
    expect(session?.isOnline, isFalse);

    // 4. Simulate App Restart (Reopening App)
    final restoredSession = await auth.getActiveSession();
    expect(restoredSession, isNotNull);
    expect(restoredSession!.isOnline, isFalse);
    state.setAccount(restoredSession);
    expect(state.isOnline, isFalse);

    // 5. Toggle to Online
    state.toggleOnlineStatus(true);
    expect(state.isOnline, isTrue);

    // 6. Verify updated session saved locally as Online
    session = await auth.getActiveSession();
    expect(session?.isOnline, isTrue);
  });
}
