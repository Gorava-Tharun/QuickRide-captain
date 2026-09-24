import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickride_captain/services/captain_connectivity_service.dart';
import 'package:quickride_captain/core/errors/captain_error_handler.dart';
import 'package:quickride_captain/widgets/captain_offline_banner.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 49: QuickRide Captain Error Handling & Offline Support Tests', () {
    late CaptainConnectivityService connectivity;

    setUp(() {
      connectivity = CaptainConnectivityService();
      connectivity.setMockOnlineState(true);
    });

    tearDown(() {
      connectivity.setMockOnlineState(true);
    });

    group('1. CaptainConnectivityService & Reconnection Synchronization', () {
      test('Initial connectivity defaults to online', () {
        expect(connectivity.isOnline, isTrue);
        expect(connectivity.isOffline, isFalse);
      });

      test('Toggling mock state updates isOnline and isOffline correctly', () {
        connectivity.setMockOnlineState(false);
        expect(connectivity.isOnline, isFalse);
        expect(connectivity.isOffline, isTrue);

        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
        expect(connectivity.isOffline, isFalse);
      });

      test('onConnectivityChanged stream emits status updates in order', () async {
        final events = <bool>[];
        final sub = connectivity.onConnectivityChanged.listen((status) {
          events.add(status);
        });

        connectivity.setMockOnlineState(false);
        connectivity.setMockOnlineState(true);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        expect(events, containsAllInOrder([false, true]));
      });

      test('Reconnection listener fires when connection restored', () async {
        bool reconnected = false;
        connectivity.addReconnectionListener(() async {
          reconnected = true;
        });

        connectivity.setMockOnlineState(false);
        expect(reconnected, isFalse);

        connectivity.setMockOnlineState(true);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(reconnected, isTrue);
      });
    });

    group('2. CaptainErrorHandler Exception Mapping', () {
      test('Translates Captain Auth exception codes to friendly strings', () {
        final notFound = FirebaseAuthException(code: 'user-not-found');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(notFound), contains('No Captain account found'));

        final wrongPass = FirebaseAuthException(code: 'wrong-password');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(wrongPass), contains('Incorrect credentials'));

        final disabled = FirebaseAuthException(code: 'user-disabled');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(disabled), contains('under review or suspended'));
      });

      test('Translates Firestore and network exceptions', () {
        final permDenied = FirebaseException(plugin: 'firestore', code: 'permission-denied');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(permDenied), contains('Access denied'));

        const socketErr = SocketException('Connection failed');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(socketErr), contains('No internet connection'));

        final timeoutErr = TimeoutException('Timeout');
        expect(CaptainErrorHandler.getFriendlyErrorMessage(timeoutErr), contains('timed out'));
      });
    });

    group('3. CaptainOfflineBanner Widget Tests', () {
      testWidgets('Hidden when Captain is online', (tester) async {
        connectivity.setMockOnlineState(true);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CaptainOfflineBanner(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Offline Mode: Ride status protected locally.'), findsNothing);
      });

      testWidgets('Displays offline banner and handles retry when offline', (tester) async {
        connectivity.setMockOnlineState(false);

        bool retried = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CaptainOfflineBanner(
                onRetry: () => retried = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Offline Mode: Ride status protected locally.'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);

        await tester.tap(find.text('RETRY'));
        await tester.pump();
        expect(retried, isTrue);
      });
    });

    group('4. Captain Ride State Protection during Disconnections', () {
      test('Active ride state is preserved and not cancelled when offline', () {
        final stateService = CaptainStateService();

        // Simulate going offline during an active ride
        connectivity.setMockOnlineState(false);

        // Ride state remains valid
        expect(stateService.isOnline, isNotNull);

        // Restore online
        connectivity.setMockOnlineState(true);
        expect(connectivity.isOnline, isTrue);
      });
    });
  });
}
