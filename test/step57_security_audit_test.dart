import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/firestore_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_firebase_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 57: QuickRide Captain App Final Security Audit & Access Control Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CaptainStateService().setAccount(CaptainAuthService.defaultSeedCaptain);
    });

    test('1. Captain Auth & Credential Security: Password changes require minimum 6 characters', () async {
      final auth = CaptainAuthService();

      // Short password rejected
      final shortPass = await auth.changePassword(
        currentPassword: 'password123',
        newPassword: '123',
        confirmPassword: '123',
      );
      expect(shortPass['success'], isFalse);

      // Mismatched confirmation rejected
      final mismatch = await auth.changePassword(
        currentPassword: 'password123',
        newPassword: 'newpassword123',
        confirmPassword: 'different123',
      );
      expect(mismatch['success'], isFalse);
    });

    test('2. Verification Duty Guard: Unverified or pending captains cannot toggle online duty', () {
      final state = CaptainStateService();

      // Seed unverified captain
      final unverified = CaptainAuthService.defaultSeedCaptain.copyWith(
        verificationStatus: 'PENDING',
        isOnline: false,
      );
      state.setAccount(unverified);

      // Attempt to go online must be blocked
      final onlineAllowed = state.toggleOnlineStatus(true);
      expect(onlineAllowed, isFalse);
      expect(state.isOnline, isFalse);
    });

    test('3. Ride State Machine Security: Strict transition enforcement', () {
      // REQUESTED -> ACCEPTED is valid
      expect(isValidRideTransition(SharedRideStatus.requested, SharedRideStatus.accepted), isTrue);

      // ACCEPTED -> ARRIVED is valid
      expect(isValidRideTransition(SharedRideStatus.accepted, SharedRideStatus.arrived), isTrue);

      // ARRIVED -> IN_PROGRESS is valid
      expect(isValidRideTransition(SharedRideStatus.arrived, SharedRideStatus.inProgress), isTrue);

      // IN_PROGRESS -> COMPLETED is valid
      expect(isValidRideTransition(SharedRideStatus.inProgress, SharedRideStatus.completed), isTrue);

      // COMPLETED is a terminal state (cannot transition back to ACCEPTED or IN_PROGRESS)
      expect(isValidRideTransition(SharedRideStatus.completed, SharedRideStatus.accepted), isFalse);
      expect(isValidRideTransition(SharedRideStatus.completed, SharedRideStatus.inProgress), isFalse);

      // CANCELLED is a terminal state
      expect(isValidRideTransition(SharedRideStatus.cancelled, SharedRideStatus.accepted), isFalse);
    });

    test('4. Rating & Review Validation Security: Stars bounded to 1..5', () async {
      final state = CaptainStateService();

      // Zero stars rejected
      final zeroStar = await state.ratePassenger('DEMO-101', 0);
      expect(zeroStar, isFalse);

      // Out-of-bounds stars (6) rejected
      final overStar = await state.ratePassenger('DEMO-101', 6);
      expect(overStar, isFalse);

      // Valid rating (5 stars) succeeds
      final validStar = await state.ratePassenger('DEMO-101', 5, review: 'Polite rider');
      expect(validStar, isTrue);
    });

    test('5. Emergency SOS Security: Emergency incident initializes with ACTIVE status and coordinates', () async {
      final fb = CaptainFirebaseService();
      final now = DateTime.now();

      final emergency = FirestoreEmergencyIncidentModel(
        emergencyId: 'EMG_SEC_999',
        rideId: 'RIDE_SEC_999',
        userId: 'user_01',
        captainId: 'CPT-78901',
        latitude: 12.9716,
        longitude: 77.5946,
        status: EmergencyStatus.active,
        triggeredBy: 'CAPTAIN',
        createdAt: now,
        updatedAt: now,
      );

      expect(emergency.isActive, isTrue);
      expect(emergency.triggeredBy, 'CAPTAIN');

      final created = await fb.createEmergencyIncident(emergency);
      expect(created, isTrue);
    });
  });
}
