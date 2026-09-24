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

  test('Step 27: Complete Ride Lifecycle (Accepted -> Pickup -> Arrived -> Start -> In Progress -> Complete -> Home)', () async {
    final auth = CaptainAuthService();
    final state = CaptainStateService();

    // 1. Initial State: Login & Go Online
    final loginResult = await auth.loginCaptain(
      phone: '9876543210',
      password: 'password123',
    );
    expect(loginResult['success'], isTrue);
    state.setAccount(loginResult['account']);
    state.toggleOnlineStatus(true);
    expect(state.rideState, CaptainRideState.idle);

    final initialEarnings = state.account.todayEarnings;
    final initialRides = state.account.totalRides;

    // 2. Trigger incoming ride request
    final triggered = state.triggerTestRideRequest();
    expect(triggered, isTrue);
    expect(state.rideState, CaptainRideState.requestReceived);
    expect(state.currentRequest, isNotNull);

    // 3. Accept Ride -> State: ACCEPTED
    final accepted = state.acceptCurrentRequest();
    expect(accepted, isTrue);
    expect(state.rideState, CaptainRideState.accepted);
    expect(state.hasActiveAcceptedRide, isTrue);

    // SAFETY GUARD TEST 1: Cannot start ride while in ACCEPTED (before arrival)
    final invalidStart1 = state.startRide();
    expect(invalidStart1, isFalse);
    expect(state.rideState, CaptainRideState.accepted);

    // SAFETY GUARD TEST 2: Cannot complete ride before starting
    final invalidComplete1 = await state.completeRide();
    expect(invalidComplete1, isFalse);
    expect(state.rideState, CaptainRideState.accepted);

    // 4. Navigate to Pickup -> State: NAVIGATING_TO_PICKUP
    state.startNavigationToPickup();
    expect(state.rideState, CaptainRideState.navigatingToPickup);
    expect(state.hasActiveAcceptedRide, isTrue);

    // SAFETY GUARD TEST 3: Cannot start ride directly while NAVIGATING_TO_PICKUP
    final invalidStart2 = state.startRide();
    expect(invalidStart2, isFalse);
    expect(state.rideState, CaptainRideState.navigatingToPickup);

    // 5. Captain Arrives at Pickup -> State: ARRIVED_AT_PICKUP
    final arrived = state.arriveAtPickup();
    expect(arrived, isTrue);
    expect(state.rideState, CaptainRideState.arrivedAtPickup);
    expect(state.hasActiveAcceptedRide, isTrue);

    // SAFETY GUARD TEST 4: Cannot complete ride before starting
    final invalidComplete2 = await state.completeRide();
    expect(invalidComplete2, isFalse);
    expect(state.rideState, CaptainRideState.arrivedAtPickup);

    // 6. Start Ride -> State: RIDE_IN_PROGRESS
    final started = state.startRide();
    expect(started, isTrue);
    expect(state.rideState, CaptainRideState.rideInProgress);
    expect(state.rideDurationSeconds, 0);

    // SAFETY GUARD TEST 5: Cannot start the same ride twice
    final duplicateStart = state.startRide();
    expect(duplicateStart, isFalse);
    expect(state.rideState, CaptainRideState.rideInProgress);

    // 7. Simulate Ride in progress timer ticks
    state.tickRideTimer();
    state.tickRideTimer();
    state.tickRideTimer();
    expect(state.rideDurationSeconds, 3);
    expect(state.formattedRideDuration, '00:03');

    final activeReq = state.currentRequest!;
    final expectedFare = activeReq.estimatedFare;

    // 8. Complete Ride -> State: COMPLETED
    final completed = await state.completeRide();
    expect(completed, isTrue);
    expect(state.rideState, CaptainRideState.completed);
    expect(state.lastCompletedRide, isNotNull);

    // Verify Completed Record Fields
    final record = state.lastCompletedRide!;
    expect(record.passengerName, activeReq.passengerName);
    expect(record.passengerPhone, activeReq.passengerPhone);
    expect(record.pickupAddress, activeReq.pickupAddress);
    expect(record.dropAddress, activeReq.dropAddress);
    expect(record.fare, expectedFare);
    expect(record.distanceKm, activeReq.distanceKm);
    expect(record.durationSeconds, 3);
    expect(record.formattedDuration, '3s');
    expect(record.completionTime, isNotNull);

    // SAFETY GUARD TEST 6: Cannot complete the same ride twice
    final duplicateComplete = await state.completeRide();
    expect(duplicateComplete, isFalse);

    // Verify Cumulative Stats updated
    expect(state.account.todayEarnings, initialEarnings + expectedFare);
    expect(state.account.totalRides, initialRides + 1);

    // Verify Persistence in SharedPreferences
    expect(state.completedRides.length, 1);
    expect(state.completedRides.first.passengerName, activeReq.passengerName);

    // Reload from SharedPreferences to confirm offline persistence
    final newState = CaptainStateService();
    await newState.loadCompletedRides();
    expect(newState.completedRides.isNotEmpty, isTrue);
    expect(newState.completedRides.first.fare, expectedFare);

    // 9. Back to Home -> State: IDLE and Captain remains Online
    state.finishCompletedRideAndReturnHome();
    expect(state.rideState, CaptainRideState.idle);
    expect(state.currentRequest, isNull);
    expect(state.isOnline, isTrue);

    // 10. Verify Captain is ready for the next incoming ride
    final nextTriggered = state.triggerTestRideRequest();
    expect(nextTriggered, isTrue);
    expect(state.rideState, CaptainRideState.requestReceived);
    expect(state.currentRequest, isNotNull);
  });
}
