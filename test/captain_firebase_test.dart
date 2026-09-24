import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_captain/models/firestore_models.dart';
import 'package:quickride_captain/services/captain_firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Captain Firebase Integration Tests', () {
    test('FirestoreCaptainModel serialization roundtrip', () {
      final captain = FirestoreCaptainModel(
        captainId: 'CPT-900',
        name: 'Suresh Captain',
        phone: '9876501234',
        email: 'suresh@quickride.com',
        vehicleNumber: 'KA-01-EQ-9988',
        vehicleType: 'Auto',
        drivingLicenseNumber: 'DL-KA-2019-998877',
        rating: 4.95,
        online: true,
        currentLocation: {'lat': 12.95, 'lng': 77.60},
        createdAt: DateTime(2026, 2, 1),
      );

      final map = captain.toMap();
      expect(map['captainId'], 'CPT-900');
      expect(map['vehicleType'], 'Auto');
      expect(map['online'], isTrue);

      final deserialized = FirestoreCaptainModel.fromMap(map, id: 'CPT-900');
      expect(deserialized.captainId, 'CPT-900');
      expect(deserialized.vehicleNumber, 'KA-01-EQ-9988');
      expect(deserialized.rating, 4.95);
      expect(deserialized.currentLocation?['lat'], 12.95);
    });

    test('SharedRideModel statuses conform to 6 standard values', () {
      const allStatuses = [
        'REQUESTED',
        'ACCEPTED',
        'ARRIVED',
        'IN_PROGRESS',
        'COMPLETED',
        'CANCELLED'
      ];

      for (final s in allStatuses) {
        final parsed = SharedRideStatus.fromString(s);
        expect(parsed.firestoreValue, s);
      }
    });

    test('CaptainFirebaseService safe initialization and diagnostic info', () async {
      final service = CaptainFirebaseService();
      await service.initialize();
      expect(service.statusMessage.isNotEmpty, isTrue);

      final testInfo = await service.testConnection();
      expect(testInfo['appId'], 'com.quickride.captain');
      expect(testInfo['firestoreTarget'], contains('captains'));
    });
  });
}
