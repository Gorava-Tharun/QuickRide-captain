import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/services/captain_demo_service.dart';
import 'package:quickride_captain/widgets/ride_request_card.dart';
import 'package:quickride_captain/widgets/accepted_ride_card.dart';
import 'package:quickride_captain/widgets/ride_in_progress_card.dart';
import 'package:quickride_captain/widgets/ride_completed_card.dart';
import 'package:quickride_captain/screens/home/captain_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CaptainDemoService().clearDemoCompletedRides();
    await CaptainDemoService().setDemoMode(true);
    final service = CaptainStateService();
    service.finishCompletedRideAndReturnHome();
    service.clearCompletedRides();
  });

  group('QuickRide Captain Demo Ride Lifecycle & Earnings Tests', () {
    test('1. Demo Mode toggle and initialization', () async {
      final demoService = CaptainDemoService();
      expect(demoService.isDemoMode, isTrue);

      await demoService.setDemoMode(false);
      expect(demoService.isDemoMode, isFalse);

      await demoService.setDemoMode(true);
      expect(demoService.isDemoMode, isTrue);
    });

    test('2. Standalone Demo Request contains required realistic fields and DEMO indicator', () async {
      final demoService = CaptainDemoService();
      final req = demoService.createSampleDemoRequest();

      expect(req.isDemo, isTrue);
      expect(req.passengerName, contains('Demo Rider'));
      expect(req.pickupAddress, contains('Dharmavaram RTC Bus Stand'));
      expect(req.dropAddress, contains('Dharmavaram Railway Station'));
      expect(req.pickupLatitude, closeTo(14.4137, 0.001));
      expect(req.dropLatitude, closeTo(14.4230, 0.001));
      expect(req.distanceKm, equals(3.5));
      expect(req.estimatedFare, equals(55.0));
    });

    test('3. Reject Demo Request: transitions to REJECTED, 0 earnings, 0 history, resets to idle', () async {
      final stateService = CaptainStateService();
      final demoService = CaptainDemoService();
      await demoService.setDemoMode(true);

      // Trigger demo request
      final triggered = stateService.triggerDemoRideRequest();
      expect(triggered, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.requestReceived));
      expect(stateService.currentRequest, isNotNull);
      expect(stateService.currentRequest!.isDemo, isTrue);

      // Reject the demo request
      stateService.rejectCurrentRequest();

      // Verify request removed & state returns to idle
      expect(stateService.currentRequest, isNull);
      expect(stateService.rideState, equals(CaptainRideState.idle));
      expect(demoService.demoRideLifecycleStatus, equals('REJECTED'));

      // Verify 0 earnings and 0 completed demo history
      expect(demoService.todayDemoEarningsTotal, equals(0.0));
      expect(demoService.todayDemoCompletedRidesCount, equals(0));
      expect(demoService.demoCompletedRides, isEmpty);

      // Verify real earnings and history unaffected
      expect(stateService.todayEarningsTotal, equals(0.0));
      expect(stateService.todayCompletedRidesCount, equals(0));
      expect(stateService.completedRides, isEmpty);
    });

    test('4. Allows testing another demo request after rejection', () async {
      final stateService = CaptainStateService();
      await CaptainDemoService().setDemoMode(true);

      // 1st request rejected
      stateService.triggerDemoRideRequest();
      stateService.rejectCurrentRequest();
      expect(stateService.rideState, equals(CaptainRideState.idle));

      // 2nd request triggered
      final second = stateService.triggerDemoRideRequest();
      expect(second, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.requestReceived));
      expect(stateService.currentRequest, isNotNull);
    });

    test('5. Complete Demo Ride Lifecycle: ACCEPTED -> NAVIGATING -> ARRIVED -> IN_PROGRESS -> COMPLETED', () async {
      final stateService = CaptainStateService();
      final demoService = CaptainDemoService();
      await demoService.setDemoMode(true);

      // Present request
      stateService.triggerDemoRideRequest();
      expect(stateService.rideState, equals(CaptainRideState.requestReceived));

      // 1. Accept Ride
      final accepted = stateService.acceptCurrentRequest();
      expect(accepted, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.accepted));
      expect(demoService.demoRideLifecycleStatus, equals('ACCEPTED'));

      // Duplicate accept blocked
      expect(stateService.acceptCurrentRequest(), isFalse);

      // 2. Start navigation to pickup
      stateService.startNavigationToPickup();
      expect(stateService.rideState, equals(CaptainRideState.navigatingToPickup));
      expect(demoService.demoRideLifecycleStatus, equals('NAVIGATING_TO_PICKUP'));

      // Guard: Starting ride blocked before arrival at pickup
      final earlyStart = stateService.startRide();
      expect(earlyStart, isFalse);
      expect(stateService.rideState, equals(CaptainRideState.navigatingToPickup));

      // 3. Arrive at pickup
      final arrived = stateService.arriveAtPickup();
      expect(arrived, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.arrivedAtPickup));
      expect(demoService.demoRideLifecycleStatus, equals('ARRIVED_AT_PICKUP'));

      // 4. Start ride
      final started = stateService.startRide();
      expect(started, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.rideInProgress));
      expect(demoService.demoRideLifecycleStatus, equals('RIDE_IN_PROGRESS'));

      // Timer ticks
      stateService.tickRideTimer();
      expect(stateService.rideDurationSeconds, equals(1));

      // 5. Complete ride
      final completed = await stateService.completeRide();
      expect(completed, isTrue);
      expect(stateService.rideState, equals(CaptainRideState.completed));
      expect(demoService.demoRideLifecycleStatus, equals('COMPLETED'));

      // Duplicate complete blocked
      final duplicateComplete = await stateService.completeRide();
      expect(duplicateComplete, isFalse);

      // Check last completed ride record
      final last = stateService.lastCompletedRide;
      expect(last, isNotNull);
      expect(last!.isDemo, isTrue);
      expect(last.paymentStatus, equals('PAID (DEMO)'));
      expect(last.paymentMethod, equals('DEMO / CASH'));
      expect(last.fare, equals(55.0));
      expect(last.distanceKm, equals(3.5));
    });

    test('6. Demo Earnings Update exactly once & Strictly separated from Real Earnings', () async {
      final stateService = CaptainStateService();
      final demoService = CaptainDemoService();
      await demoService.setDemoMode(true);

      final initialRealAccountEarnings = stateService.account.todayEarnings;
      final initialRealAccountRides = stateService.account.totalRides;

      // Complete a demo ride of fare 55.0
      stateService.triggerDemoRideRequest();
      stateService.acceptCurrentRequest();
      stateService.startNavigationToPickup();
      stateService.arriveAtPickup();
      stateService.startRide();
      await stateService.completeRide();

      // Check Demo Earnings (Today & Total)
      expect(demoService.todayDemoEarningsTotal, equals(55.0));
      expect(demoService.todayDemoCaptainEarningsNet, equals(55.0 * 0.85)); // 46.75
      expect(demoService.todayDemoPlatformFeeTotal, equals(55.0 * 0.15)); // 8.25
      expect(demoService.todayDemoCompletedRidesCount, equals(1));
      expect(demoService.totalDemoEarnings, equals(55.0));
      expect(demoService.totalDemoCompletedRidesCount, equals(1));
      expect(demoService.averageDemoFare, equals(55.0));

      // Guard: Attempting duplicate record addition with same ID must be rejected
      final duplicateRecord = stateService.lastCompletedRide!;
      final addedAgain = await demoService.recordCompletedDemoRide(duplicateRecord);
      expect(addedAgain, isFalse);
      expect(demoService.todayDemoEarningsTotal, equals(55.0)); // Still 55.0!
      expect(demoService.todayDemoCompletedRidesCount, equals(1));

      // Check Real Account Earnings remain 100% UNTOUCHED
      expect(stateService.todayEarningsTotal, equals(0.0));
      expect(stateService.todayCompletedRidesCount, equals(0));
      expect(stateService.account.todayEarnings, equals(initialRealAccountEarnings));
      expect(stateService.account.totalRides, equals(initialRealAccountRides));
    });

    test('7. Demo Ride History Persistence across state reload', () async {
      final stateService = CaptainStateService();
      final demoService = CaptainDemoService();
      await demoService.setDemoMode(true);

      // Complete a demo ride
      stateService.triggerDemoRideRequest();
      stateService.acceptCurrentRequest();
      stateService.arriveAtPickup();
      stateService.startRide();
      await stateService.completeRide();

      expect(demoService.demoCompletedRides.length, equals(1));
      final trip = demoService.demoCompletedRides.first;
      expect(trip.passengerName, contains('Rahul'));
      expect(trip.pickupAddress, contains('Dharmavaram'));
      expect(trip.isDemo, isTrue);

      // Re-load state from SharedPreferences mock
      await demoService.loadState();
      expect(demoService.demoCompletedRides.length, equals(1));
      expect(demoService.todayDemoEarningsTotal, equals(55.0));
    });

    test('8. Return to Home resets state to IDLE and allows testing full cycle repeatedly', () async {
      final stateService = CaptainStateService();
      await CaptainDemoService().setDemoMode(true);

      // Complete 1st ride
      stateService.triggerDemoRideRequest();
      stateService.acceptCurrentRequest();
      stateService.arriveAtPickup();
      stateService.startRide();
      await stateService.completeRide();
      expect(stateService.rideState, equals(CaptainRideState.completed));

      // Return home
      stateService.finishCompletedRideAndReturnHome();
      expect(stateService.rideState, equals(CaptainRideState.idle));
      expect(stateService.currentRequest, isNull);

      // Complete 2nd ride
      stateService.triggerDemoRideRequest();
      expect(stateService.rideState, equals(CaptainRideState.requestReceived));
      stateService.acceptCurrentRequest();
      stateService.arriveAtPickup();
      stateService.startRide();
      await stateService.completeRide();

      expect(CaptainDemoService().todayDemoEarningsTotal, equals(110.0));
      expect(CaptainDemoService().todayDemoCompletedRidesCount, equals(2));
    });
  });

  group('QuickRide Captain Demo Ride UI Widget Tests', () {
    testWidgets('9. RideRequestCard renders DEMO REQUEST badge and working Accept/Reject buttons', (tester) async {
      final req = RideRequestItem(
        id: 'DEMO-REQ-TEST',
        passengerName: 'Rahul (Demo Rider)',
        passengerPhone: '+91 98450 77123',
        passengerRating: 4.9,
        pickupAddress: 'Dharmavaram RTC Bus Stand, Main Road',
        dropAddress: 'Dharmavaram Railway Station, Station Road',
        distanceKm: 3.5,
        estimatedMinutes: 12,
        vehicleType: 'Bike (QuickRide)',
        estimatedFare: 55.0,
        isDemo: true,
      );

      bool accepted = false;
      bool rejected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideRequestCard(
              request: req,
              secondsRemaining: 25,
              onAccept: () => accepted = true,
              onReject: () => rejected = true,
            ),
          ),
        ),
      );

      // Verify DEMO REQUEST label & DEMO MODE chip
      expect(find.text('DEMO REQUEST'), findsOneWidget);
      expect(find.text('DEMO MODE'), findsOneWidget);
      expect(find.text('Rahul (Demo Rider)'), findsOneWidget);
      expect(find.text('₹55'), findsOneWidget);
      expect(find.text('Dharmavaram RTC Bus Stand, Main Road'), findsOneWidget);
      expect(find.text('Dharmavaram Railway Station, Station Road'), findsOneWidget);

      // Verify buttons
      expect(find.text('Accept Ride'), findsOneWidget);
      expect(find.text('Reject Ride'), findsOneWidget);

      await tester.tap(find.text('Accept Ride'));
      expect(accepted, isTrue);

      await tester.tap(find.text('Reject Ride'));
      expect(rejected, isTrue);
    });

    testWidgets('10. AcceptedRideCard renders DEMO ACCEPTED badge and Navigate/Arrived/Start actions', (tester) async {
      final req = RideRequestItem(
        id: 'DEMO-REQ-TEST',
        passengerName: 'Rahul (Demo Rider)',
        passengerRating: 4.9,
        pickupAddress: 'Dharmavaram RTC Bus Stand, Main Road',
        dropAddress: 'Dharmavaram Railway Station, Station Road',
        distanceKm: 3.5,
        estimatedFare: 55.0,
        isDemo: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcceptedRideCard(
              request: req,
              rideState: CaptainRideState.accepted,
              onNavigateToPickup: () {},
              onArrivedAtPickup: () {},
              onStartRide: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('DEMO ACCEPTED'), findsOneWidget);
      expect(find.text('Navigate to Pickup'), findsOneWidget);
    });

    testWidgets('11. RideInProgressCard and RideCompletedCard render DEMO indicators', (tester) async {
      final req = RideRequestItem(
        id: 'DEMO-REQ-TEST',
        passengerName: 'Rahul (Demo Rider)',
        passengerRating: 4.9,
        pickupAddress: 'Dharmavaram RTC Bus Stand, Main Road',
        dropAddress: 'Dharmavaram Railway Station, Station Road',
        distanceKm: 3.5,
        estimatedFare: 55.0,
        isDemo: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideInProgressCard(
              request: req,
              formattedTimer: '02:30',
              onCompleteRide: () {},
            ),
          ),
        ),
      );

      expect(find.text('DEMO'), findsOneWidget);
      expect(find.text('RIDE IN PROGRESS'), findsOneWidget);
      expect(find.text('Complete Ride'), findsOneWidget);

      // Now test completed card
      final completed = CompletedRideRecord(
        id: 'DEMO-REQ-TEST',
        passengerName: 'Rahul (Demo Rider)',
        passengerPhone: '+91 98450 77123',
        pickupAddress: 'Dharmavaram RTC Bus Stand, Main Road',
        dropAddress: 'Dharmavaram Railway Station, Station Road',
        vehicleType: 'Bike (QuickRide)',
        fare: 55.0,
        distanceKm: 3.5,
        durationSeconds: 150,
        completionTime: DateTime.now(),
        isDemo: true,
        paymentStatus: 'PAID (DEMO)',
        paymentMethod: 'DEMO / CASH',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideCompletedCard(
              record: completed,
              onBackToHome: () {},
            ),
          ),
        ),
      );

      expect(find.text('DEMO RIDE COMPLETED'), findsOneWidget);
      expect(find.text('Ride completed successfully'), findsOneWidget);
      expect(find.text('₹55'), findsOneWidget);
      expect(find.text('DEMO EARNING / FARE'), findsOneWidget);
    });

    testWidgets('12. CaptainHomeScreen displays Demo Mode banner and Demo Earnings stats row', (tester) async {
      await CaptainDemoService().setDemoMode(true);

      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainHomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DEMO MODE ACTIVE'), findsOneWidget);
      expect(find.text('VIVA / PPT'), findsOneWidget);
      expect(find.text("Today's Demo Earnings"), findsOneWidget);
      expect(find.text('Demo Completed Rides'), findsOneWidget);
    });
  });
}
