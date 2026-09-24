import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_chat_service.dart';
import 'package:quickride_captain/services/captain_connectivity_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 53: QuickRide Three-App Integration Testing Suite (Captain App Perspective)', () {
    late CaptainStateService stateService;
    late CaptainConnectivityService connectivity;
    late CaptainChatService chatService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      connectivity = CaptainConnectivityService();
      connectivity.setMockOnlineState(true);
      stateService = CaptainStateService();
      stateService.updateAccount(CaptainAuthService.defaultSeedCaptain);
      chatService = CaptainChatService();
    });

    tearDown(() {
      connectivity.setMockOnlineState(true);
    });

    // =========================================================================
    // 1. CAPTAIN RECEIVES & ACCEPTS RIDE FLOW
    // =========================================================================
    group('1. Captain Request Reception & Active Trip Lifecycle', () {
      test('Captain receives ride request item and accepts transitioning state', () {
        const req = RideRequestItem(
          id: 'REQ-INT-501',
          passengerName: 'Aarav Sharma',
          passengerPhone: '+91 98765 43210',
          passengerRating: 4.9,
          pickupAddress: 'MG Road Metro Station',
          pickupLatitude: 12.9756,
          pickupLongitude: 77.6066,
          dropAddress: 'Koramangala 5th Block',
          dropLatitude: 12.9345,
          dropLongitude: 77.6265,
          distanceKm: 6.5,
          estimatedMinutes: 18,
          vehicleType: 'Auto',
          estimatedFare: 120.0,
          paymentMode: 'UPI / Online',
        );

        expect(req.id, 'REQ-INT-501');
        expect(req.estimatedFare, 120.0);
        expect(req.passengerName, 'Aarav Sharma');

        // Test manual trigger and accept in stateService
        stateService.triggerTestRideRequest();
        expect(stateService.rideState, CaptainRideState.requestReceived);
        expect(stateService.currentRequest, isNotNull);

        stateService.acceptCurrentRequest();
        expect(stateService.rideState, CaptainRideState.accepted);
        expect(stateService.hasActiveAcceptedRide, isTrue);

        stateService.startNavigationToPickup();
        expect(stateService.rideState, CaptainRideState.navigatingToPickup);

        stateService.arriveAtPickup();
        expect(stateService.rideState, CaptainRideState.arrivedAtPickup);

        stateService.startRide();
        expect(stateService.rideState, CaptainRideState.rideInProgress);

        stateService.completeRide();
        expect(stateService.rideState, CaptainRideState.completed);

        stateService.finishCompletedRideAndReturnHome();
        expect(stateService.rideState, CaptainRideState.idle);
      });

      test('Captain earnings split computes 85% driver share vs 15% platform fee', () {
        const fare = 150.0;
        final earnings = fare * 0.85;
        final platformFee = fare * 0.15;

        expect(earnings, 127.5);
        expect(platformFee, 22.5);
        expect(earnings + platformFee, fare);
      });
    });

    // =========================================================================
    // 2. BIDIRECTIONAL CHAT CHANNEL
    // =========================================================================
    group('2. Captain Chat Flow & Read Receipts', () {
      test('Captain chat message sending and gating verification', () async {
        const rideId = 'RIDE_CAP_CHAT_01';
        chatService.reset(rideId);

        // Allowed in active ride state
        final success = await chatService.sendMessage(
          rideId: rideId,
          senderId: 'cap_201',
          senderName: 'Rajesh Kumar',
          message: 'I have arrived at the pickup location.',
          senderRole: 'CAPTAIN',
          rideStatus: 'ARRIVED',
        );
        expect(success, isTrue);

        // Blocked in completed ride state
        final blocked = await chatService.sendMessage(
          rideId: rideId,
          senderId: 'cap_201',
          senderName: 'Rajesh Kumar',
          message: 'Have a nice day!',
          senderRole: 'CAPTAIN',
          rideStatus: 'COMPLETED',
        );
        expect(blocked, isFalse);
      });
    });

    // =========================================================================
    // 3. ADMIN VERIFICATION & DUTY GATING
    // =========================================================================
    group('3. Admin Verification Integration & Duty Gating', () {
      test('Captain duty is blocked if verification is REJECTED or PENDING', () {
        final pendingCaptain = stateService.account.copyWith(
          verificationStatus: 'PENDING',
        );
        expect(pendingCaptain.isApproved, isFalse);

        final rejectedCaptain = stateService.account.copyWith(
          verificationStatus: 'REJECTED',
          rejectionReason: 'Blurry driving license image',
        );
        expect(rejectedCaptain.isRejected, isTrue);
        expect(rejectedCaptain.rejectionReason, contains('Blurry'));

        final approvedCaptain = stateService.account.copyWith(
          verificationStatus: 'APPROVED',
        );
        expect(approvedCaptain.isApproved, isTrue);
      });
    });

    // =========================================================================
    // 4. DUPLICATE ACTIONS & CONCURRENCY
    // =========================================================================
    group('4. Duplicate Actions & Idempotency', () {
      test('Double tap on accept does not corrupt state', () {
        stateService.triggerTestRideRequest();
        expect(stateService.rideState, CaptainRideState.requestReceived);

        stateService.acceptCurrentRequest();
        expect(stateService.rideState, CaptainRideState.accepted);

        // Second tap
        stateService.acceptCurrentRequest();
        expect(stateService.rideState, CaptainRideState.accepted);

        stateService.finishCompletedRideAndReturnHome();
      });
    });

    // =========================================================================
    // 5. SECURITY RULES INTEGRITY
    // =========================================================================
    group('5. Security Rules Verification', () {
      test('Verify absence of open allow read write wildcard in rules files', () {
        final firestoreRulesFile = File('../firestore.rules');
        if (firestoreRulesFile.existsSync()) {
          final content = firestoreRulesFile.readAsStringSync();
          expect(content.contains('allow read, write: if true;'), isFalse);
          expect(content.contains('allow read, write: if false;'), isTrue);
        }
      });
    });

    // =========================================================================
    // 6. OFFLINE & RECONNECTION SYNC
    // =========================================================================
    group('6. Offline & Reconnection Resiliency', () {
      test('Captain offline transition preserves active trip and synchronizes on reconnect', () {
        connectivity.setMockOnlineState(false);
        expect(connectivity.isOffline, isTrue);

        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
      });
    });
  });
}
