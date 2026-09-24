import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Captain Ride Request Receive, Reject and Expiration Lifecycle', () async {
    final auth = CaptainAuthService();
    final state = CaptainStateService();

    // 1. Initial Login
    final loginResult = await auth.loginCaptain(
      phone: '9876543210',
      password: 'password123',
    );
    expect(loginResult['success'], isTrue);
    state.setAccount(loginResult['account']);

    // 2. OFFLINE Test: should NOT allow receiving ride request
    state.toggleOnlineStatus(false);
    expect(state.isOnline, isFalse);
    final offlineTrigger = state.triggerTestRideRequest();
    expect(offlineTrigger, isFalse);
    expect(state.currentRequest, isNull);

    // 3. ONLINE Test: Trigger test ride request
    state.toggleOnlineStatus(true);
    expect(state.isOnline, isTrue);
    final onlineTrigger = state.triggerTestRideRequest();
    expect(onlineTrigger, isTrue);
    expect(state.currentRequest, isNotNull);
    expect(state.requestSecondsRemaining, 30);
    expect(state.currentRequest?.passengerName, 'Rahul');
    expect(state.currentRequest?.estimatedFare, 75.0);
    expect(state.currentRequest?.distanceKm, 4.2);

    // 4. Countdown timer ticker
    state.tickTimer();
    expect(state.requestSecondsRemaining, 29);

    // 5. REJECT Test: Reject removes request and clears timer
    state.rejectCurrentRequest();
    expect(state.currentRequest, isNull);
    expect(state.requestSecondsRemaining, 0);

    // 6. EXPIRATION Test: Trigger next request and expire
    state.triggerTestRideRequest();
    expect(state.currentRequest, isNotNull);
    expect(state.currentRequest?.passengerName, 'Priya');

    state.expireRequest();
    expect(state.currentRequest, isNull);
    expect(state.requestSecondsRemaining, 0);

    // 7. Going OFFLINE clears any active request
    state.triggerTestRideRequest();
    expect(state.currentRequest, isNotNull);
    state.toggleOnlineStatus(false);
    expect(state.currentRequest, isNull);
  });
}
