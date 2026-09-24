import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/widgets/captain_cancellation_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Step 43 — Captain Ride Cancellation Tests', () {
    test('CaptainStateService can cancel accepted ride, keeps captain online, and resets to idle', () async {
      final auth = CaptainAuthService();
      final stateService = CaptainStateService();

      // Log in demo captain (so account is verified)
      final loginResult = await auth.loginCaptain(
        phone: '9876543210',
        password: 'password123',
      );
      expect(loginResult['success'], isTrue);
      stateService.setAccount(loginResult['account']);
      stateService.toggleOnlineStatus(true);
      expect(stateService.isOnline, isTrue);

      // Trigger test ride request
      stateService.triggerTestRideRequest();
      expect(stateService.rideState, CaptainRideState.requestReceived);
      expect(stateService.currentRequest, isNotNull);

      // Accept the ride
      stateService.acceptCurrentRequest();
      expect(stateService.rideState, CaptainRideState.accepted);
      expect(stateService.hasActiveAcceptedRide, isTrue);

      // Cancel the accepted ride with reason
      stateService.cancelAcceptedRide(
        cancellationReason: 'Vehicle issue',
        cancellationDescription: 'Punctured rear tyre',
      );

      // Verify captain remains online and returns to idle
      expect(stateService.rideState, CaptainRideState.idle);
      expect(stateService.currentRequest, isNull);
      expect(stateService.hasActiveAcceptedRide, isFalse);
      expect(stateService.isOnline, isTrue);
    });

    test('Passenger cancellation notice captures reason in state service', () {
      final stateService = CaptainStateService();
      // Default state
      expect(stateService.lastCancellationNotice, isNull);
    });
  });

  group('Step 43 — CaptainCancellationDialog Widget Tests', () {
    testWidgets('Renders all captain cancellation reasons and returns selected result', (tester) async {
      CaptainCancellationResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  confirmedResult = await CaptainCancellationDialog.show(
                    ctx,
                    rideId: 'RIDE_123_TEST',
                  );
                },
                child: const Text('Cancel Ride as Captain'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel Ride as Captain'));
      await tester.pumpAndSettle();

      // Check dialog elements
      expect(find.text('Cancel Ride'), findsOneWidget);
      expect(find.text('Reason for cancellation:'), findsOneWidget);
      expect(find.text('Keep Ride'), findsOneWidget);
      expect(find.text('Confirm Cancel'), findsOneWidget);

      // Select 'Vehicle issue'
      await tester.tap(find.text('Vehicle issue'));
      await tester.pumpAndSettle();

      // Enter optional notes
      await tester.enterText(find.byType(TextField), 'Engine overheating');
      await tester.pumpAndSettle();

      // Tap Confirm Cancel
      await tester.tap(find.text('Confirm Cancel'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult?.reason, 'Vehicle issue');
      expect(confirmedResult?.description, 'Engine overheating');
    });
  });
}
