import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_connectivity_service.dart';
import 'package:quickride_captain/services/captain_firebase_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 58: QuickRide Captain App Final End-to-End Testing Suite', () {
    late CaptainStateService stateService;
    late CaptainConnectivityService connectivityService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      stateService = CaptainStateService();
      connectivityService = CaptainConnectivityService();
      connectivityService.setMockOnlineState(true);

      CaptainFirebaseService().clearLocalEmergencies();
      CaptainFirebaseService().clearLocalComplaints();
      CaptainFirebaseService().clearLocalChatMessages();

      stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
        verificationStatus: 'APPROVED',
        vehicleVerificationStatus: 'APPROVED',
        isOnline: false,
      ));
      stateService.clearActiveEmergency();
      stateService.finishCompletedRideAndReturnHome();
      await stateService.clearCompletedRides();
    });

    tearDown(() async {
      connectivityService.setMockOnlineState(true);
      stateService.clearActiveEmergency();
      stateService.finishCompletedRideAndReturnHome();
      await stateService.clearCompletedRides();
    });

    // -------------------------------------------------------------------------
    // 1. CAPTAIN AUTH, VERIFICATION & DUTY GATING
    // -------------------------------------------------------------------------
    group('1. Captain Auth, Profile Verification & Duty Gating', () {
      test('Unverified captain cannot toggle online duty (returns false)', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'PENDING',
          isOnline: false,
        ));

        final result = stateService.toggleOnlineStatus(true);
        expect(result, isFalse);
        expect(stateService.isOnline, isFalse);
      });

      test('Approved verified captain can toggle online duty freely', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'APPROVED',
          vehicleVerificationStatus: 'APPROVED',
          isOnline: false,
        ));

        final onlineResult = stateService.toggleOnlineStatus(true);
        expect(onlineResult, isTrue);
        expect(stateService.isOnline, isTrue);

        final offlineResult = stateService.toggleOnlineStatus(false);
        expect(offlineResult, isTrue);
        expect(stateService.isOnline, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // 2. COMPLETE RIDE LIFECYCLE & NAVIGATION
    // -------------------------------------------------------------------------
    group('2. Full Ride Lifecycle: Request, Acceptance, Navigation & Completion', () {
      test('Captain processes incoming ride request through complete lifecycle', () async {
        // Go online
        stateService.toggleOnlineStatus(true);
        expect(stateService.isOnline, isTrue);

        // Receive request
        final requestTriggered = stateService.triggerTestRideRequest();
        expect(requestTriggered, isTrue);
        expect(stateService.rideState, CaptainRideState.requestReceived);
        expect(stateService.currentRequest, isNotNull);

        // Accept request
        final accepted = stateService.acceptCurrentRequest();
        expect(accepted, isTrue);
        expect(stateService.rideState, CaptainRideState.accepted);
        expect(stateService.hasActiveAcceptedRide, isTrue);

        // Arrive at pickup
        final arrived = stateService.arriveAtPickup();
        expect(arrived, isTrue);
        expect(stateService.rideState, CaptainRideState.arrivedAtPickup);

        // Start ride
        final started = stateService.startRide();
        expect(started, isTrue);
        expect(stateService.rideState, CaptainRideState.rideInProgress);

        // Complete ride
        final completed = await stateService.completeRide();
        expect(completed, isTrue);
        expect(stateService.rideState, CaptainRideState.completed);
        expect(stateService.lastCompletedRide, isNotNull);

        // Verify Earnings Split (85% captain share, 15% platform commission)
        final lastRide = stateService.lastCompletedRide!;
        expect(lastRide.captainEarning, (lastRide.fare * 0.85));
        expect(lastRide.platformFee, (lastRide.fare * 0.15));
      });
    });

    // -------------------------------------------------------------------------
    // 3. EMERGENCY SOS & INCIDENT BROADCAST
    // -------------------------------------------------------------------------
    group('3. Emergency SOS Broadcast & Incident Telemetry', () {
      test('Emergency SOS broadcasts active incident with telemetry', () async {
        final success = await stateService.triggerSOS(
          reason: 'Medical or Route Hazard',
        );

        expect(success, isTrue);
        expect(stateService.isEmergencyActive, isTrue);
        expect(stateService.activeEmergency, isNotNull);

        stateService.clearActiveEmergency();
        expect(stateService.isEmergencyActive, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // 4. OFFLINE & ERROR RESILIENCE
    // -------------------------------------------------------------------------
    group('4. Offline Resilience & Connectivity Handling', () {
      test('Network disconnection toggles offline state cleanly without exceptions', () {
        connectivityService.setMockOnlineState(false);
        expect(connectivityService.isOnline, isFalse);

        connectivityService.setMockOnlineState(true);
        expect(connectivityService.isOnline, isTrue);
      });
    });
  });
}
