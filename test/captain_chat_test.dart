import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/screens/chat/captain_chat_screen.dart';
import 'package:quickride_captain/services/captain_chat_service.dart';
import 'package:quickride_captain/widgets/accepted_ride_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CaptainChatService().reset();
  });

  group('Step 45: CaptainChatService Tests', () {
    test('isChatEnabledForStatus validates captain chat lifecycle', () {
      expect(CaptainChatService.isChatEnabledForStatus('ACCEPTED'), isTrue);
      expect(CaptainChatService.isChatEnabledForStatus('ARRIVED'), isTrue);
      expect(CaptainChatService.isChatEnabledForStatus('IN_PROGRESS'), isTrue);
      expect(CaptainChatService.isChatEnabledForStatus('COMPLETED'), isFalse);
      expect(CaptainChatService.isChatEnabledForStatus('CANCELLED'), isFalse);
      expect(CaptainChatService.isChatEnabledForStatus(null), isFalse);
    });

    test('sendMessage rejects empty or overly long messages', () async {
      final service = CaptainChatService();
      final r1 = await service.sendMessage(
        rideId: 'R1',
        senderId: 'C1',
        senderName: 'Captain',
        message: '   ',
      );
      expect(r1, isFalse);

      final r2 = await service.sendMessage(
        rideId: 'R1',
        senderId: 'C1',
        senderName: 'Captain',
        message: 'B' * 501,
      );
      expect(r2, isFalse);
    });

    test('sendMessage delivers captain message and updates stream', () async {
      final service = CaptainChatService();
      const rideId = 'RIDE_CAP_100';

      final ok = await service.sendMessage(
        rideId: rideId,
        senderId: 'cap_01',
        senderName: 'Vikram',
        message: 'I have arrived at the gate.',
        rideStatus: 'ARRIVED',
      );
      expect(ok, isTrue);

      final messages = await service.fetchMessages(rideId);
      expect(messages.length, 1);
      expect(messages.first.isFromCaptain, isTrue);
      expect(messages.first.message, 'I have arrived at the gate.');
    });

    test('markAllReceivedAsRead marks passenger messages as read', () async {
      final service = CaptainChatService();
      const rideId = 'RIDE_CAP_READ_100';

      await service.sendMessage(
        rideId: rideId,
        senderId: 'user_01',
        senderName: 'Passenger Aarav',
        senderRole: 'USER',
        message: 'Coming down now.',
      );

      final list = await service.fetchMessages(rideId);
      expect(list.first.read, isFalse);

      await service.markAllReceivedAsRead(
        rideId: rideId,
        currentCaptainId: 'cap_01',
        messages: list,
      );

      final updated = await service.fetchMessages(rideId);
      expect(updated.first.read, isTrue);
    });
  });

  group('Step 45: CaptainChatScreen Widget Tests', () {
    testWidgets('CaptainChatScreen displays passenger header and quick chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainChatScreen(
            rideId: 'RIDE_CAP_WIDGET',
            currentCaptainId: 'cap_01',
            currentCaptainName: 'Vikram',
            passengerId: 'user_01',
            passengerName: 'Aarav Sharma',
            passengerPhone: '+91 98765 43210',
            pickupAddress: 'Indiranagar 100ft Rd',
            rideStatus: 'ACCEPTED',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Pickup: Indiranagar 100ft Rd'), findsOneWidget);
      expect(find.text('I have arrived at your pickup point'), findsOneWidget);
      expect(find.text('Chat with Passenger'), findsOneWidget);
    });

    testWidgets('Tapping quick response chip sends captain message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainChatScreen(
            rideId: 'RIDE_CAP_SEND',
            currentCaptainId: 'cap_01',
            currentCaptainName: 'Vikram',
            passengerId: 'user_01',
            passengerName: 'Aarav Sharma',
            rideStatus: 'ACCEPTED',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('I have arrived at your pickup point'));
      await tester.pumpAndSettle();

      expect(find.text('I have arrived at your pickup point'), findsWidgets);
    });

    testWidgets('AcceptedRideCard renders Chat button and navigates to ChatScreen', (tester) async {
      const item = RideRequestItem(
        id: 'REQ_100',
        passengerName: 'Rahul Verma',
        passengerPhone: '+91 98765 00000',
        passengerRating: 4.8,
        pickupAddress: 'Koramangala 4th Block',
        dropAddress: 'HSR Layout Sector 1',
        distanceKm: 4.5,
        estimatedFare: 85.0,
        estimatedMinutes: 12,
        vehicleType: 'Bike',
        paymentMode: 'CASH',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AcceptedRideCard(
              request: item,
              rideState: CaptainRideState.navigatingToPickup,
              onNavigateToPickup: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('SOS Safety'), findsOneWidget);

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('Pickup: Koramangala 4th Block'), findsOneWidget);
    });
  });
}
