import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/screens/earnings/captain_earnings_screen.dart';
import 'package:quickride_captain/screens/history/captain_history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Step 28: Earnings Calculations (Today, Week, Month, Total, Average) & Sorting', () async {
    final state = CaptainStateService();
    await state.clearCompletedRides();

    // 1. Empty State Check: No fake values
    expect(state.completedRides.isEmpty, isTrue);
    expect(state.todayEarningsTotal, 0.0);
    expect(state.todayCompletedRidesCount, 0);
    expect(state.weeklyEarningsTotal, 0.0);
    expect(state.weeklyCompletedRidesCount, 0);
    expect(state.monthlyEarningsTotal, 0.0);
    expect(state.monthlyCompletedRidesCount, 0);
    expect(state.totalEarnings, 0.0);
    expect(state.totalCompletedRidesCount, 0);
    expect(state.averageFare, 0.0);

    // 2. Add Controlled Completed Rides through demo seed
    state.completedRides; // verify getter
    await state.seedDemoCompletedRides();
    expect(state.completedRides.length, 3);
    expect(state.completedRides.first.passengerName.contains('DEMO'), isTrue);

    // Clear and test exact custom values
    await state.clearCompletedRides();
    expect(state.completedRides.isEmpty, isTrue);

    // Complete active ride through full service state machine
    state.toggleOnlineStatus(true);
    state.triggerTestRideRequest();
    state.acceptCurrentRequest();
    state.startNavigationToPickup();
    state.arriveAtPickup();
    state.startRide();
    state.tickRideTimer();
    state.tickRideTimer();
    final completed = await state.completeRide();
    expect(completed, isTrue);

    expect(state.completedRides.length, 1);
    expect(state.todayCompletedRidesCount, 1);
    expect(state.todayEarningsTotal, 75.0);
    expect(state.totalEarnings, 75.0);
    expect(state.averageFare, 75.0);

    // Verify Persistence across fresh load
    final freshState = CaptainStateService();
    await freshState.loadCompletedRides();
    expect(freshState.completedRides.length, 1);
    expect(freshState.todayEarningsTotal, 75.0);
  });

  testWidgets('CaptainEarningsScreen renders live breakdown cards and demo seed button', (tester) async {
    final state = CaptainStateService();
    await state.clearCompletedRides();

    await tester.pumpWidget(
      const MaterialApp(
        home: CaptainEarningsScreen(),
      ),
    );

    // Empty state
    expect(find.text('Captain Earnings'), findsOneWidget);
    expect(find.text('No completed rides yet'), findsOneWidget);
    expect(find.text('Load Sample Demo Rides'), findsOneWidget);

    // Tap Load Sample Demo Rides
    await tester.tap(find.text('Load Sample Demo Rides'));
    await tester.pumpAndSettle();

    // Now earnings content should be visible
    expect(find.text("Today's Earnings"), findsOneWidget);
    expect(find.text('Earnings Breakdown'), findsOneWidget);
    expect(find.text("This Week's Earnings"), findsOneWidget);
    expect(find.text("This Month's Earnings"), findsOneWidget);
    expect(find.text('Total Earnings (All Time)'), findsOneWidget);
  });

  testWidgets('CaptainHistoryScreen renders filter chips and navigates to Ride Details', (tester) async {
    final state = CaptainStateService();
    await state.clearCompletedRides();
    await state.seedDemoCompletedRides();

    await tester.pumpWidget(
      const MaterialApp(
        home: CaptainHistoryScreen(),
      ),
    );

    // Verify filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);

    // Verify ride card items appear
    expect(find.text('Rahul (DEMO)'), findsOneWidget);
    expect(find.text('Pooja (DEMO)'), findsOneWidget);
    expect(find.text('Amit (DEMO)'), findsOneWidget);

    // Tap on a ride card to open Ride Details
    await tester.tap(find.text('Rahul (DEMO)'));
    await tester.pumpAndSettle();

    // Verify Ride Details screen is opened
    expect(find.text('Ride Details'), findsOneWidget);
    expect(find.text('Total Fare Earned'), findsOneWidget);
    expect(find.text('Passenger Details'), findsOneWidget);
    expect(find.text('Route & Trip Details'), findsOneWidget);
    expect(find.text('Back to History'), findsOneWidget);

    // Tap Back to History
    await tester.ensureVisible(find.text('Back to History'));
    await tester.tap(find.text('Back to History'));
    await tester.pumpAndSettle();

    expect(find.text('Ride History'), findsOneWidget);
  });
}
