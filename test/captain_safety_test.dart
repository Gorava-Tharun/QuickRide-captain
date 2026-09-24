import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_captain/models/firestore_models.dart';
import 'package:quickride_captain/screens/safety/captain_safety_center_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Captain App Step 40 Safety Center & Emergency Models', () {
    test('FirestoreEmergencyIncidentModel properties & serialization', () {
      final incident = FirestoreEmergencyIncidentModel(
        emergencyId: 'EMG-TEST-001',
        rideId: 'RIDE-123',
        userId: 'USR-001',
        captainId: 'CPT-001',
        latitude: 12.9716,
        longitude: 77.5946,
        status: EmergencyStatus.active,
        triggeredBy: 'CAPTAIN',
        captainName: 'John Captain',
        captainPhone: '9876543210',
        createdAt: DateTime(2026, 9, 19, 10, 0),
        updatedAt: DateTime(2026, 9, 19, 10, 0),
        adminNotes: 'Captain initiated emergency',
      );

      expect(incident.emergencyId, 'EMG-TEST-001');
      expect(incident.triggeredBy, 'CAPTAIN');
      expect(incident.status, EmergencyStatus.active);
      expect(incident.statusLabel, 'ACTIVE');

      final map = incident.toMap();
      expect(map['emergencyId'], 'EMG-TEST-001');
      expect(map['status'], 'ACTIVE');
      expect(map['latitude'], 12.9716);

      final fromMap = FirestoreEmergencyIncidentModel.fromMap(map, id: 'EMG-TEST-001');
      expect(fromMap.emergencyId, 'EMG-TEST-001');
      expect(fromMap.status, EmergencyStatus.active);
      expect(fromMap.captainName, 'John Captain');
    });

    test('FirestoreEmergencyContactModel properties & serialization', () {
      final contact = FirestoreEmergencyContactModel(
        contactId: 'CNT-001',
        ownerId: 'CPT-001',
        name: 'Jane Doe',
        phone: '9988776655',
        relationship: 'Spouse',
        createdAt: DateTime(2026, 9, 19, 9, 0),
      );

      expect(contact.ownerId, 'CPT-001');
      expect(contact.name, 'Jane Doe');
      expect(contact.phone, '9988776655');
      expect(contact.relationship, 'Spouse');

      final map = contact.toMap();
      expect(map['name'], 'Jane Doe');
      expect(map['phone'], '9988776655');

      final fromMap = FirestoreEmergencyContactModel.fromMap(map, id: 'CNT-001');
      expect(fromMap.contactId, 'CNT-001');
      expect(fromMap.name, 'Jane Doe');
    });
  });

  group('Captain App Step 40 Safety Center Screen Widget Tests', () {
    testWidgets('CaptainSafetyCenterScreen renders title, SOS button, guidelines, and support', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainSafetyCenterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Safety Center'), findsOneWidget);
      expect(find.text('Trigger Emergency SOS'), findsOneWidget);
      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Captain Safety Protocols'), findsOneWidget);
      expect(find.text('Report Safety Incident'), findsOneWidget);
    });

    testWidgets('Tapping SOS button opens 2-step confirmation dialog with accidental activation guard', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainSafetyCenterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap SOS button
      await tester.tap(find.text('Trigger Emergency SOS'));
      await tester.pumpAndSettle();

      // Dialog should appear with confirmation button
      expect(find.text('CONFIRM SOS'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('CONFIRM SOS'), findsNothing);
    });
  });
}
