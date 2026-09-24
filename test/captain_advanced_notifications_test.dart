import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_captain/services/captain_push_notification_service.dart';
import 'package:quickride_captain/screens/home/captain_home_screen.dart';

void main() {
  group('Step 46: Captain Advanced Notifications Tests', () {
    test('CaptainPushNotificationService deduplication works reliably', () {
      final service = CaptainPushNotificationService();
      const rideId = 'CAP_REQ_501';
      const eventType = 'NEW_RIDE_REQUEST';

      // First event is accepted
      final first = service.shouldProcessRideEvent(rideId, eventType);
      expect(first, isTrue);

      // Duplicate event is rejected
      final second = service.shouldProcessRideEvent(rideId, eventType);
      expect(second, isFalse);

      // Different event on same ride is accepted
      final third = service.shouldProcessRideEvent(rideId, 'RIDE_CANCELLED');
      expect(third, isTrue);
    });

    test('CaptainPushNotificationService notification tap callback passes data payload', () {
      final service = CaptainPushNotificationService();
      String? tappedRideId;
      String? tappedType;
      Map<String, dynamic>? tappedData;

      service.initialize(
        captainId: 'CAP-101',
        onNotificationTap: (rideId, type, [data]) {
          tappedRideId = rideId;
          tappedType = type;
          tappedData = data;
        },
      );

      service.onNotificationTap?.call('REQ-202', 'CHAT_MESSAGE', {'rideId': 'REQ-202', 'type': 'CHAT_MESSAGE'});

      expect(tappedRideId, 'REQ-202');
      expect(tappedType, 'CHAT_MESSAGE');
      expect(tappedData?['rideId'], 'REQ-202');
    });

    testWidgets('CaptainHomeScreen initializes push notification service without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainHomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(CaptainHomeScreen), findsOneWidget);
    });
  });
}
