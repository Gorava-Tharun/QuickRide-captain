import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Step 26: Captain Accept, Navigate, Cancel, and Reject Flow', () async {
    final auth = CaptainAuthService();
    final state = CaptainStateService();

    // 1. Initial Login & Online
    final loginResult = await auth.loginCaptain(
      phone: '9876543210',
      password: 'password123',
    );
    expect(loginResult['success'], isTrue);
    state.setAccount(loginResult['account']);
    state.toggleOnlineStatus(true);
    expect(state.rideState, CaptainRideState.idle);

    // 2. Trigger incoming ride request
    final triggered = state.triggerTestRideRequest();
    expect(triggered, isTrue);
    expect(state.rideState, CaptainRideState.requestReceived);
    expect(state.currentRequest, isNotNull);
    expect(state.requestSecondsRemaining, 30);

    // 3. Test ACCEPT RIDE
    final acceptSuccess = state.acceptCurrentRequest();
    expect(acceptSuccess, isTrue);
    expect(state.rideState, CaptainRideState.accepted);
    expect(state.acceptedRide, isNotNull);
    expect(state.acceptedRide?.passengerName, 'Rahul');
    expect(state.acceptedRide?.passengerPhone, '+91 98450 77123');
    expect(state.acceptedRide?.pickupAddress, 'Main Road, 100 Feet Corner, Indiranagar');
    expect(state.acceptedRide?.dropAddress, 'Railway Station, City Center Platform 1');
    expect(state.acceptedRide?.estimatedFare, 75.0);
    expect(state.requestSecondsRemaining, 0);

    // 4. Test DUPLICATE ACCEPTANCE GUARD
    final duplicateAccept = state.acceptCurrentRequest();
    expect(duplicateAccept, isFalse);

    // 5. Test NAVIGATE TO PICKUP
    state.startNavigationToPickup();
    expect(state.rideState, CaptainRideState.navigatingToPickup);
    expect(state.acceptedRide, isNotNull);

    // 6. Test CANCEL ACCEPTED RIDE
    state.cancelAcceptedRide();
    expect(state.rideState, CaptainRideState.idle);
    expect(state.acceptedRide, isNull);

    // 7. Test REJECT RIDE
    state.triggerTestRideRequest();
    expect(state.rideState, CaptainRideState.requestReceived);
    expect(state.currentRequest, isNotNull);
    state.rejectCurrentRequest();
    expect(state.rideState, CaptainRideState.idle);
    expect(state.currentRequest, isNull);

    // 8. Test OFFLINE GUARD while ride is accepted
    state.triggerTestRideRequest();
    state.acceptCurrentRequest();
    expect(state.acceptedRide, isNotNull);
    state.toggleOnlineStatus(false);
    // Accepted ride must persist even if offline is toggled during an active trip
    expect(state.acceptedRide, isNotNull);
    expect(state.rideState, CaptainRideState.accepted);
  });
}
