import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/widgets/accepted_ride_card.dart';
import 'package:quickride_captain/widgets/ride_in_progress_card.dart';
import 'package:quickride_captain/widgets/ride_completed_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testRequest = RideRequestItem(
    id: 'REQ-101',
    passengerName: 'Rahul',
    passengerPhone: '+91 98450 77123',
    passengerRating: 4.85,
    pickupAddress: 'Main Road, 100 Feet Corner, Indiranagar',
    dropAddress: 'Railway Station, City Center Platform 1',
    distanceKm: 4.2,
    estimatedMinutes: 12,
    estimatedFare: 75.0,
  );

  testWidgets('AcceptedRideCard displays Navigate, Arrived, and Start buttons based on state', (tester) async {
    bool navigateCalled = false;
    bool arrivedCalled = false;
    bool startCalled = false;
    bool cancelCalled = false;

    // 1. ACCEPTED state: Shows "Navigate to Pickup"
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcceptedRideCard(
            request: testRequest,
            rideState: CaptainRideState.accepted,
            onNavigateToPickup: () => navigateCalled = true,
            onArrivedAtPickup: () => arrivedCalled = true,
            onStartRide: () => startCalled = true,
            onCancel: () => cancelCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('RIDE ACCEPTED'), findsOneWidget);
    expect(find.text('Navigate to Pickup'), findsOneWidget);
    await tester.tap(find.text('Navigate to Pickup'));
    expect(navigateCalled, isTrue);

    // 2. NAVIGATING_TO_PICKUP state: Shows "I've Arrived"
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcceptedRideCard(
            request: testRequest,
            rideState: CaptainRideState.navigatingToPickup,
            onNavigateToPickup: () => navigateCalled = true,
            onArrivedAtPickup: () => arrivedCalled = true,
            onStartRide: () => startCalled = true,
            onCancel: () => cancelCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('GO TO PICKUP'), findsOneWidget);
    expect(find.text("I've Arrived"), findsOneWidget);
    await tester.tap(find.text("I've Arrived"));
    expect(arrivedCalled, isTrue);

    // 3. ARRIVED_AT_PICKUP state: Shows "Start Ride"
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcceptedRideCard(
            request: testRequest,
            rideState: CaptainRideState.arrivedAtPickup,
            onNavigateToPickup: () => navigateCalled = true,
            onArrivedAtPickup: () => arrivedCalled = true,
            onStartRide: () => startCalled = true,
            onCancel: () => cancelCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('ARRIVED AT PICKUP'), findsOneWidget);
    expect(find.text('Captain has arrived at pickup. Passenger notified.'), findsOneWidget);
    expect(find.text('Start Ride'), findsOneWidget);
    await tester.tap(find.text('Start Ride'));
    expect(startCalled, isTrue);
    expect(cancelCalled, isFalse);
  });

  testWidgets('RideInProgressCard displays active timer, destination and Complete Ride action', (tester) async {
    bool completeCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideInProgressCard(
            request: testRequest,
            formattedTimer: '02:45',
            onCompleteRide: () => completeCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('RIDE IN PROGRESS'), findsOneWidget);
    expect(find.text('02:45'), findsOneWidget);
    expect(find.text('Rahul'), findsOneWidget);
    expect(find.text('Complete Ride'), findsOneWidget);

    await tester.tap(find.text('Complete Ride'));
    expect(completeCalled, isTrue);
  });

  testWidgets('RideCompletedCard displays summary and Back to Home button', (tester) async {
    bool homeCalled = false;
    final record = CompletedRideRecord(
      id: 'CR-12345',
      passengerName: 'Rahul',
      passengerPhone: '+91 98450 77123',
      pickupAddress: 'Main Road, 100 Feet Corner, Indiranagar',
      dropAddress: 'Railway Station, City Center Platform 1',
      vehicleType: 'QuickRide Bike',
      fare: 75.0,
      distanceKm: 4.2,
      durationSeconds: 165,
      completionTime: DateTime(2026, 9, 12, 19, 45),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideCompletedCard(
            record: record,
            onBackToHome: () => homeCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Ride completed successfully'), findsOneWidget);
    expect(find.text('₹75'), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    await tester.tap(find.text('Back to Home'));
    expect(homeCalled, isTrue);
  });
}
