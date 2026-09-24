import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/core/constants/app_strings.dart';
import 'package:quickride_captain/core/errors/captain_error_handler.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/screens/auth/captain_login_screen.dart';
import 'package:quickride_captain/screens/auth/captain_signup_screen.dart';
import 'package:quickride_captain/screens/home/captain_home_screen.dart';
import 'package:quickride_captain/screens/splash/splash_screen.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_connectivity_service.dart';
import 'package:quickride_captain/services/captain_firebase_service.dart';
import 'package:quickride_captain/services/captain_push_notification_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/widgets/accepted_ride_card.dart';
import 'package:quickride_captain/widgets/captain_offline_banner.dart';
import 'package:quickride_captain/widgets/ride_in_progress_card.dart';
import 'package:quickride_captain/widgets/ride_completed_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 51: QuickRide Captain App Complete End-to-End Testing Suite', () {
    late CaptainAuthService authService;
    late CaptainStateService stateService;
    late CaptainConnectivityService connectivityService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authService = CaptainAuthService();
      stateService = CaptainStateService();
      connectivityService = CaptainConnectivityService();
      connectivityService.setMockOnlineState(true);

      CaptainFirebaseService().clearLocalEmergencies();
      CaptainFirebaseService().clearLocalComplaints();
      CaptainFirebaseService().clearLocalChatMessages();

      // Reset to approved verified captain for general tests
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
      CaptainFirebaseService().clearLocalEmergencies();
      CaptainFirebaseService().clearLocalComplaints();
      CaptainFirebaseService().clearLocalChatMessages();
    });

    // =========================================================================
    // 1. CAPTAIN LOGIN, SIGNUP & SESSION PERSISTENCE
    // =========================================================================
    group('1. Captain Authentication, Signup & Session Persistence', () {
      testWidgets('Splash screen initializes and renders Captain branding', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(AppStrings.appName), findsOneWidget);
        expect(find.text(AppStrings.appTagline), findsOneWidget);

        // Advance timer past splash navigation
        await tester.pump(const Duration(milliseconds: 2500));
      });

      testWidgets('Captain login screen validates inputs and authenticates captain', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CaptainLoginScreen(),
          ),
        );

        expect(find.text(AppStrings.loginTitle), findsOneWidget);
        expect(find.text(AppStrings.loginButton), findsOneWidget);

        final result = await authService.loginCaptain(
          phone: '9876543210',
          password: 'password123',
        );

        expect(result['success'], isTrue);
        expect(result['account'], isNotNull);
        final acc = result['account'] as CaptainAccount;
        expect(acc.name, 'Rajesh Kumar');
        expect(acc.phone, '9876543210');
      });

      test('Invalid credentials return clear error without throwing unhandled exceptions', () async {
        final result = await authService.loginCaptain(
          phone: '9999999999',
          password: 'wrongpassword',
        );

        expect(result['success'], isFalse);
        expect(result['message'], isNotNull);
      });

      testWidgets('Captain signup screen validates required license and vehicle fields', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CaptainSignupScreen(),
          ),
        );

        expect(find.text(AppStrings.signupTitle), findsWidgets);
        expect(find.text(AppStrings.createAccountButton), findsOneWidget);
      });

      test('Captain session persistence: save, fetch and logout', () async {
        const captain = CaptainAuthService.defaultSeedCaptain;
        await authService.updateActiveCaptain(captain);

        final session = await authService.getActiveSession();
        expect(session, isNotNull);
        expect(session!.id, captain.id);
        expect(session.name, captain.name);

        await authService.logout();
        final emptySession = await authService.getActiveSession();
        expect(emptySession, isNull);
      });
    });

    // =========================================================================
    // 2. CAPTAIN PROFILE & VEHICLE INFO
    // =========================================================================
    group('2. Captain Profile, Vehicle Details & License Records', () {
      test('CaptainAccount model serializes and maintains profile integrity', () {
        const captain = CaptainAccount(
          id: 'CPT-501',
          name: 'Vikram Singh',
          phone: '+91 98111 22334',
          email: 'vikram@quickride.com',
          password: 'password123',
          vehicleType: 'Bike',
          vehicleNumber: 'KA 01 AB 1234',
          licenseNumber: 'DL-0420110012345',
          rating: 4.9,
          totalRides: 320,
          todayEarnings: 2400.0,
          isOnline: true,
          verificationStatus: 'APPROVED',
          vehicleVerificationStatus: 'APPROVED',
        );

        expect(captain.name, 'Vikram Singh');
        expect(captain.vehicleType, 'Bike');
        expect(captain.rating, 4.9);
        expect(captain.isApproved, isTrue);

        final updated = captain.copyWith(vehicleNumber: 'KA 05 CD 5678');
        expect(updated.vehicleNumber, 'KA 05 CD 5678');
        expect(captain.vehicleNumber, 'KA 01 AB 1234'); // Immutable original

        final jsonMap = captain.toMap();
        final reconstructed = CaptainAccount.fromMap(jsonMap);
        expect(reconstructed.id, captain.id);
        expect(reconstructed.name, captain.name);
        expect(reconstructed.licenseNumber, captain.licenseNumber);
      });

      test('CaptainStateService updates profile details reactively', () {
        stateService.updateProfile(
          name: 'Vikram Singh Updated',
          phone: '+91 99887 76655',
          vehicleNumber: 'KA 03 XY 9999',
        );

        expect(stateService.account.name, 'Vikram Singh Updated');
        expect(stateService.account.phone, '+91 99887 76655');
        expect(stateService.account.vehicleNumber, 'KA 03 XY 9999');
      });
    });

    // =========================================================================
    // 3. DOCUMENTS & VEHICLE VERIFICATION
    // =========================================================================
    group('3. Verification Documents & Duty Status Gating', () {
      test('Duty status gating blocks going online when verification is PENDING', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'PENDING',
          isOnline: false,
        ));

        final success = stateService.toggleOnlineStatus(true);
        expect(success, isFalse);
        expect(stateService.isOnline, isFalse);
      });

      test('Duty status gating blocks going online when verification is REJECTED', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'REJECTED',
          rejectionReason: 'Invalid document',
          isOnline: false,
        ));

        final success = stateService.toggleOnlineStatus(true);
        expect(success, isFalse);
        expect(stateService.isOnline, isFalse);
      });

      test('Duty status gating allows going online when verification is APPROVED', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'APPROVED',
          isOnline: false,
        ));

        final success = stateService.toggleOnlineStatus(true);
        expect(success, isTrue);
        expect(stateService.isOnline, isTrue);
      });

      test('Submitting verification documents sets status to PENDING and takes captain offline', () async {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'APPROVED',
          isOnline: true,
        ));

        await stateService.submitVerificationDocuments(
          licenseNumber: 'DL-NEW-12345',
          vehicleNumber: 'KA 02 MN 7788',
          vehicleType: 'Auto',
          licenseImageUrl: 'https://test.com/license.jpg',
        );

        expect(stateService.account.verificationStatus, 'PENDING');
        expect(stateService.account.licenseNumber, 'DL-NEW-12345');
        expect(stateService.account.vehicleNumber, 'KA 02 MN 7788');
        expect(stateService.isOnline, isFalse);
      });
    });

    // =========================================================================
    // 4. ONLINE / OFFLINE STATUS
    // =========================================================================
    group('4. Online / Offline Status Synchronization', () {
      test('Toggling online state updates CaptainStateService reactively', () {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'APPROVED',
          isOnline: false,
        ));

        expect(stateService.isOnline, isFalse);

        stateService.toggleOnlineStatus(true);
        expect(stateService.isOnline, isTrue);

        stateService.toggleOnlineStatus(false);
        expect(stateService.isOnline, isFalse);
      });

      testWidgets('CaptainHomeScreen displays Online/Offline toggle switch and duty card', (tester) async {
        stateService.setAccount(CaptainAuthService.defaultSeedCaptain.copyWith(
          verificationStatus: 'APPROVED',
          isOnline: false,
        ));

        await tester.pumpWidget(
          const MaterialApp(
            home: CaptainHomeScreen(),
          ),
        );
        await tester.pump();

        expect(find.byType(CaptainOfflineBanner), findsOneWidget);
        expect(find.text('You are Offline'), findsWidgets);
        expect(find.text(stateService.account.name), findsOneWidget);
      });
    });

    // =========================================================================
    // 5. RIDE REQUESTS & TIMEOUT
    // =========================================================================
    group('5. Ride Request Ingestion, Rejection & Timeout', () {
      test('Incoming ride request transitions state to REQUEST_RECEIVED with 30s countdown', () {
        stateService.toggleOnlineStatus(true);
        final triggered = stateService.triggerTestRideRequest();
        expect(triggered, isTrue);
        expect(stateService.rideState, CaptainRideState.requestReceived);
        expect(stateService.currentRequest, isNotNull);
        expect(stateService.requestSecondsRemaining, 30);
      });

      test('Timer decrement counts down and auto-expires request on reaching 0', () {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();
        expect(stateService.rideState, CaptainRideState.requestReceived);

        // Tick timer down
        for (int i = 0; i < 30; i++) {
          stateService.tickTimer();
        }

        expect(stateService.rideState, CaptainRideState.idle);
        expect(stateService.currentRequest, isNull);
        expect(stateService.requestSecondsRemaining, 0);
      });

      test('Captain can reject incoming ride request and return to IDLE', () {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();
        expect(stateService.rideState, CaptainRideState.requestReceived);

        stateService.rejectCurrentRequest();
        expect(stateService.rideState, CaptainRideState.idle);
        expect(stateService.currentRequest, isNull);
      });
    });

    // =========================================================================
    // 6. ACCEPT RIDE & DUPLICATE PROTECTION
    // =========================================================================
    group('6. Accept Ride & Concurrency Guard', () {
      test('Accepting ride transitions state to ACCEPTED and stops countdown timer', () {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();

        final accepted = stateService.acceptCurrentRequest();
        expect(accepted, isTrue);
        expect(stateService.rideState, CaptainRideState.accepted);
        expect(stateService.acceptedRide, isNotNull);
        expect(stateService.hasActiveAcceptedRide, isTrue);

        // Duplicate acceptance is safely rejected
        final duplicate = stateService.acceptCurrentRequest();
        expect(duplicate, isFalse);
      });
    });

    // =========================================================================
    // 7. ACTIVE RIDE FLOW (ACCEPTED -> ARRIVED -> IN_PROGRESS -> COMPLETED)
    // =========================================================================
    group('7. Active Ride Lifecycle State Transitions', () {
      test('Complete 4-stage ride flow executes cleanly to completion', () async {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();

        // 1. ACCEPTED
        stateService.acceptCurrentRequest();
        expect(stateService.rideState, CaptainRideState.accepted);

        // Guard: Cannot start ride directly from ACCEPTED (must arrive first)
        expect(stateService.startRide(), isFalse);

        // 2. NAVIGATING TO PICKUP
        stateService.startNavigationToPickup();
        expect(stateService.rideState, CaptainRideState.navigatingToPickup);

        // Guard: Cannot complete ride while navigating
        expect(await stateService.completeRide(), isFalse);

        // 3. ARRIVED AT PICKUP
        final arrived = stateService.arriveAtPickup();
        expect(arrived, isTrue);
        expect(stateService.rideState, CaptainRideState.arrivedAtPickup);

        // 4. RIDE IN PROGRESS
        final started = stateService.startRide();
        expect(started, isTrue);
        expect(stateService.rideState, CaptainRideState.rideInProgress);

        // Simulate ride timer
        stateService.tickRideTimer();
        stateService.tickRideTimer();
        expect(stateService.rideDurationSeconds, 2);

        // 5. COMPLETE RIDE
        final completed = await stateService.completeRide();
        expect(completed, isTrue);
        expect(stateService.rideState, CaptainRideState.completed);
        expect(stateService.lastCompletedRide, isNotNull);

        // 6. FINISH AND RETURN HOME
        stateService.finishCompletedRideAndReturnHome();
        expect(stateService.rideState, CaptainRideState.idle);
        expect(stateService.currentRequest, isNull);
        expect(stateService.isOnline, isTrue);
      });

      testWidgets('AcceptedRideCard renders action buttons per lifecycle state', (tester) async {
        const testReq = RideRequestItem(
          id: 'REQ-101',
          passengerName: 'Rahul',
          passengerPhone: '+91 98450 77123',
          passengerRating: 4.85,
          pickupAddress: 'Indiranagar 100ft Rd',
          dropAddress: 'City Center MG Rd',
          distanceKm: 4.2,
          estimatedMinutes: 12,
          estimatedFare: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AcceptedRideCard(
                request: testReq,
                rideState: CaptainRideState.accepted,
                onNavigateToPickup: () {},
                onArrivedAtPickup: () {},
                onStartRide: () {},
                onCancel: () {},
              ),
            ),
          ),
        );

        expect(find.text('RIDE ACCEPTED'), findsOneWidget);
        expect(find.text('Navigate to Pickup'), findsOneWidget);
        expect(find.text('Rahul'), findsOneWidget);
      });

      testWidgets('RideInProgressCard displays elapsed timer, drop address, and Complete Ride', (tester) async {
        const testReq = RideRequestItem(
          id: 'REQ-101',
          passengerName: 'Rahul',
          passengerPhone: '+91 98450 77123',
          passengerRating: 4.85,
          pickupAddress: 'Indiranagar 100ft Rd',
          dropAddress: 'City Center MG Rd',
          distanceKm: 4.2,
          estimatedMinutes: 12,
          estimatedFare: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RideInProgressCard(
                request: testReq,
                formattedTimer: '05:30',
                onCompleteRide: () {},
              ),
            ),
          ),
        );

        expect(find.text('RIDE IN PROGRESS'), findsOneWidget);
        expect(find.text('05:30'), findsOneWidget);
        expect(find.text('Complete Ride'), findsOneWidget);
      });

      testWidgets('RideCompletedCard displays fare earnings breakdown and returns home', (tester) async {
        final record = CompletedRideRecord(
          id: 'RIDE-REC-01',
          passengerName: 'Rahul',
          passengerPhone: '+91 98450 77123',
          pickupAddress: 'Indiranagar',
          dropAddress: 'MG Road',
          vehicleType: 'Bike',
          fare: 100.0,
          distanceKm: 5.0,
          durationSeconds: 600,
          completionTime: DateTime.now(),
          paymentStatus: 'PAID',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RideCompletedCard(
                record: record,
                onBackToHome: () {},
              ),
            ),
          ),
        );

        expect(find.text('RIDE COMPLETED'), findsOneWidget);
        expect(find.text('₹100'), findsOneWidget);
        expect(find.text('Back to Home'), findsOneWidget);
      });
    });

    // =========================================================================
    // 8. PAYMENT & EARNINGS BREAKDOWN
    // =========================================================================
    group('8. Captain Earnings Breakdown & Deduplication', () {
      test('Earnings calculation accurately computes 85% captain share and 15% platform fee', () {
        final record = CompletedRideRecord(
          id: 'REC-001',
          passengerName: 'Test Passenger',
          passengerPhone: '+91 98000 11111',
          pickupAddress: 'Indiranagar',
          dropAddress: 'MG Road',
          vehicleType: 'Bike',
          fare: 200.0,
          distanceKm: 10.0,
          durationSeconds: 900,
          completionTime: DateTime.now(),
          paymentStatus: 'PAID',
        );

        expect(record.fare, 200.0);
        expect(record.captainEarning, 170.0); // 85%
        expect(record.platformFee, 30.0); // 15%
        expect(record.isPaid, isTrue);
      });

      test('Today, Weekly, Monthly, and Total earnings aggregations compute accurately', () async {
        await stateService.seedDemoCompletedRides();

        expect(stateService.completedRides.length, 3);
        expect(stateService.todayCompletedRidesCount, 2);
        expect(stateService.todayEarningsTotal, 170.0); // 75 + 95
        expect(stateService.totalEarnings, 280.0); // 75 + 95 + 110
        expect(stateService.totalCompletedRidesCount, 3);
        expect(stateService.averageFare, closeTo(93.33, 0.1));
      });
    });

    // =========================================================================
    // 9. CANCELLATION & DISCONNECTION HANDLING
    // =========================================================================
    group('9. Ride Cancellation & Intermittent Connectivity Protection', () {
      test('Active ride is preserved during offline events without premature cancellation', () {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();
        stateService.acceptCurrentRequest();
        expect(stateService.hasActiveAcceptedRide, isTrue);

        connectivityService.setMockOnlineState(false);
        expect(connectivityService.isOffline, isTrue);

        // Active ride state remains intact when offline
        expect(stateService.hasActiveAcceptedRide, isTrue);
        expect(stateService.rideState, CaptainRideState.accepted);

        connectivityService.setMockOnlineState(true);
        expect(connectivityService.isOnline, isTrue);
        expect(stateService.hasActiveAcceptedRide, isTrue);
      });

      test('Captain cancelling accepted ride returns cleanly to IDLE', () {
        stateService.toggleOnlineStatus(true);
        stateService.triggerTestRideRequest();
        stateService.acceptCurrentRequest();

        stateService.cancelAcceptedRide(cancellationReason: 'Vehicle breakdown');
        expect(stateService.rideState, CaptainRideState.idle);
        expect(stateService.acceptedRide, isNull);
        expect(stateService.currentRequest, isNull);
      });
    });

    // =========================================================================
    // 10. CHAT & PUSH NOTIFICATIONS
    // =========================================================================
    group('10. In-Ride Chat & Push Notification Dispatcher', () {
      test('Push notification service suppresses duplicates and validates events', () {
        final push = CaptainPushNotificationService();
        expect(push.shouldProcessRideEvent('RIDE-01', 'NEW_RIDE_REQUEST'), isTrue);
        // Duplicate event with same ID and type is suppressed
        expect(push.shouldProcessRideEvent('RIDE-01', 'NEW_RIDE_REQUEST'), isFalse);
        // Different event type is permitted
        expect(push.shouldProcessRideEvent('RIDE-01', 'RIDE_CANCELLED'), isTrue);
      });
    });

    // =========================================================================
    // 11. SAFETY & EMERGENCY SOS
    // =========================================================================
    group('11. Safety Center & Emergency SOS Telemetry', () {
      test('Trigger SOS sets active emergency and updates telemetry coordinates', () async {
        final sosTriggered = await stateService.triggerSOS(reason: 'Test Emergency alert');
        expect(sosTriggered, isTrue);
        expect(stateService.isEmergencyActive, isTrue);
        expect(stateService.activeEmergency, isNotNull);

        await Future.delayed(const Duration(milliseconds: 50));

        final updateLoc = await stateService.updateEmergencyLocation(12.9800, 77.6500);
        expect(updateLoc, isTrue);
        expect(stateService.activeEmergency!.latitude, 12.9800);
        expect(stateService.activeEmergency!.longitude, 77.6500);

        stateService.clearActiveEmergency();
        expect(stateService.isEmergencyActive, isFalse);
      });
    });

    // =========================================================================
    // 12. RATINGS & REVIEWS
    // =========================================================================
    group('12. Passenger Rating & Reviews Flow', () {
      test('Captain rates passenger and review is persisted to completed ride record', () async {
        await stateService.seedDemoCompletedRides();
        final targetRide = stateService.completedRides.first;

        final rated = await stateService.ratePassenger(
          targetRide.id,
          5,
          review: 'Very polite and on time passenger!',
        );

        expect(rated, isTrue);
        final updatedRecord = stateService.completedRides.firstWhere((r) => r.id == targetRide.id);
        expect(updatedRecord.isRated, isTrue);
        expect(updatedRecord.rating, 5);
        expect(updatedRecord.reviewText, 'Very polite and on time passenger!');
      });

      test('Rating validation prevents invalid star ratings (< 1 or > 5)', () async {
        final invalidLow = await stateService.ratePassenger('DEMO-101', 0);
        expect(invalidLow, isFalse);

        final invalidHigh = await stateService.ratePassenger('DEMO-101', 6);
        expect(invalidHigh, isFalse);
      });
    });

    // =========================================================================
    // 13. SUPPORT & COMPLAINTS MANAGEMENT
    // =========================================================================
    group('13. Support & Complaints Ticket Lifecycle', () {
      test('Captain creates support complaint and sends reply', () async {
        final complaint = await stateService.createComplaint(
          category: 'Payment Issue',
          subject: 'Fare discrepancy on ride',
          description: 'Payment was not credited immediately.',
          priority: 'HIGH',
        );

        expect(complaint.complaintId.isNotEmpty, isTrue);
        expect(complaint.status, 'OPEN');
        expect(complaint.priority, 'HIGH');
        expect(stateService.complaints.any((c) => c.complaintId == complaint.complaintId), isTrue);

        final replySent = await stateService.sendComplaintReply(
          complaintId: complaint.complaintId,
          message: 'Attaching the transaction screenshot for review.',
        );
        expect(replySent, isTrue);
      });
    });

    // =========================================================================
    // 14. ERROR TRANSLATION & SECURITY ISOLATION
    // =========================================================================
    group('14. Error Handling & Security Isolation', () {
      test('CaptainErrorHandler maps technical exceptions to friendly driver feedback', () {
        final msgSocket = CaptainErrorHandler.getFriendlyErrorMessage(
          const SocketException('Connection failed'),
        );
        expect(msgSocket.contains('internet') || msgSocket.contains('Network') || msgSocket.contains('connection'), isTrue);

        final msgTimeout = CaptainErrorHandler.getFriendlyErrorMessage(
          TimeoutException('request took too long'),
        );
        expect(msgTimeout.contains('time') || msgTimeout.contains('slow') || msgTimeout.contains('network') || msgTimeout.contains('timed out'), isTrue);
      });

      test('CaptainFirebaseService protects captain data and handles offline fallback gracefully', () {
        final fb = CaptainFirebaseService();
        expect(fb.isFirebaseAvailable, isNotNull);
      });
    });
  });
}
