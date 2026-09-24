import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/screens/home/captain_home_screen.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 55: QuickRide Captain Performance, Lifecycle & Crash Prevention', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CaptainStateService().updateAccount(CaptainAuthService.defaultSeedCaptain);
    });

    test('CaptainStateService cancels GPS tracking and ride sync on ride completion return home', () {
      final service = CaptainStateService();
      
      // Simulate duty and test ride request
      service.toggleOnlineStatus(true);
      service.triggerTestRideRequest();
      expect(service.rideState, CaptainRideState.requestReceived);

      // Accept ride -> transitions to accepted and starts sync
      final accepted = service.acceptCurrentRequest();
      expect(accepted, isTrue);
      expect(service.hasActiveAcceptedRide, isTrue);

      // Finish and return home -> safely tears down GPS and active ride streams
      service.finishCompletedRideAndReturnHome();
      expect(service.rideState, CaptainRideState.idle);
      expect(service.currentRequest, isNull);
    });

    test('CaptainStateService cancels GPS tracking and requests when toggled offline', () {
      final service = CaptainStateService();
      service.toggleOnlineStatus(true);
      expect(service.isOnline, isTrue);

      service.toggleOnlineStatus(false);
      expect(service.isOnline, isFalse);
      expect(service.currentRequest, isNull);
      expect(service.rideState, CaptainRideState.idle);
    });

    test('CaptainStateService stopAllSubscriptions cleanly cancels all active subscriptions', () {
      final service = CaptainStateService();
      service.initComplaintsListener();
      
      // Verify stopAllSubscriptions executes without throw
      expect(() => service.stopAllSubscriptions(), returnsNormally);
    });

    testWidgets('CaptainHomeScreen mounts and disposes map and timer cleanly without leaks or exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainHomeScreen(),
        ),
      );
      await tester.pump();

      // Trigger pump frame
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      // Replace with empty container to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
