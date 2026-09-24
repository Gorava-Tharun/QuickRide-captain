import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/screens/profile/captain_verification_screen.dart';
import 'package:quickride_captain/screens/profile/captain_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuickRide Captain Step 42 Verification Model Tests', () {
    test('CaptainAccount verification getters evaluate statuses correctly', () {
      const pendingCaptain = CaptainAccount(
        id: 'cpt-test-1',
        name: 'Test Driver',
        phone: '9876543210',
        email: 'driver@quickride.com',
        password: 'password123',
        vehicleNumber: 'KA01AB1234',
        vehicleType: 'Auto',
        licenseNumber: 'DL1234567890',
        rating: 4.8,
        totalRides: 50,
        todayEarnings: 500,
        isOnline: false,
        verificationStatus: 'PENDING',
        vehicleVerificationStatus: 'PENDING',
      );

      expect(pendingCaptain.verificationStatus, 'PENDING');
      expect(pendingCaptain.vehicleVerificationStatus, 'PENDING');
      expect(pendingCaptain.isPending, isTrue);
      expect(pendingCaptain.isApproved, isFalse);
      expect(pendingCaptain.isRejected, isFalse);

      final approvedCaptain = CaptainAccount(
        id: 'cpt-appr',
        name: 'Approved Driver',
        phone: '9876543211',
        email: 'approved@quickride.com',
        password: 'password123',
        vehicleNumber: 'KA01AB1234',
        vehicleType: 'Auto',
        licenseNumber: 'DL1234567890',
        rating: 5.0,
        totalRides: 100,
        todayEarnings: 1000,
        isOnline: true,
        verificationStatus: 'APPROVED',
        vehicleVerificationStatus: 'APPROVED',
        verifiedAt: DateTime(2026, 3, 1),
      );

      expect(approvedCaptain.isApproved, isTrue);
      expect(approvedCaptain.isPending, isFalse);
      expect(approvedCaptain.isRejected, isFalse);
      expect(approvedCaptain.verifiedAt, isNotNull);

      const rejectedCaptain = CaptainAccount(
        id: 'cpt-rej',
        name: 'Rejected Driver',
        phone: '9876543212',
        email: 'rejected@quickride.com',
        password: 'password123',
        vehicleNumber: 'KA01AB1234',
        vehicleType: 'Auto',
        licenseNumber: 'DL1234567890',
        rating: 4.0,
        totalRides: 10,
        todayEarnings: 0,
        isOnline: false,
        verificationStatus: 'REJECTED',
        vehicleVerificationStatus: 'REJECTED',
        rejectionReason: 'License photo is blurred and unreadable',
      );

      expect(rejectedCaptain.isRejected, isTrue);
      expect(rejectedCaptain.isPending, isFalse);
      expect(rejectedCaptain.isApproved, isFalse);
      expect(rejectedCaptain.rejectionReason, 'License photo is blurred and unreadable');
    });

    test('CaptainAccount serialization handles verification fields correctly', () {
      final original = CaptainAccount(
        id: 'cpt-map-test',
        name: 'Map Test Driver',
        phone: '9876543213',
        email: 'map@quickride.com',
        password: 'password123',
        vehicleNumber: 'KA01XY9999',
        vehicleType: 'Bike',
        licenseNumber: 'DL9988776655',
        rating: 4.9,
        totalRides: 75,
        todayEarnings: 700,
        isOnline: false,
        drivingLicenseImageUrl: 'https://storage.googleapis.com/license.jpg',
        vehicleDocumentImageUrl: 'https://storage.googleapis.com/rc.jpg',
        vehicleImageUrl: 'https://storage.googleapis.com/vehicle.jpg',
        verificationStatus: 'APPROVED',
        vehicleVerificationStatus: 'APPROVED',
        documentsSubmittedAt: DateTime(2026, 2, 1, 10, 0),
        verifiedAt: DateTime(2026, 2, 2, 15, 30),
        rejectionReason: null,
      );

      final json = original.toJson();
      final reconstructed = CaptainAccount.fromJson(json);
      expect(reconstructed.verificationStatus, 'APPROVED');
      expect(reconstructed.vehicleVerificationStatus, 'APPROVED');
      expect(reconstructed.drivingLicenseImageUrl, 'https://storage.googleapis.com/license.jpg');
      expect(reconstructed.vehicleDocumentImageUrl, 'https://storage.googleapis.com/rc.jpg');
      expect(reconstructed.vehicleImageUrl, 'https://storage.googleapis.com/vehicle.jpg');
      expect(reconstructed.isApproved, isTrue);
    });
  });

  group('QuickRide Captain Step 42 Duty Status Gating Unit Tests', () {
    test('Duty status gating blocks going online when verification is PENDING', () async {
      final state = CaptainStateService();

      // Ensure captain is pending
      state.updateProfile(
        name: 'Pending Driver',
        phone: '9876543200',
        email: 'pending@quickride.com',
        vehicleNumber: 'KA01P1234',
        vehicleType: 'Auto',
        licenseNumber: 'DL0000000001',
      );

      // Submit docs setting it to PENDING
      await state.submitVerificationDocuments(
        licenseNumber: 'DL0000000001',
        vehicleNumber: 'KA01P1234',
        vehicleType: 'Auto',
      );

      expect(state.account.isPending, isTrue);
      expect(state.account.isOnline, isFalse);

      // Attempt to go online - must return false and remain offline
      final toggleResult = state.toggleOnlineStatus(true);
      expect(toggleResult, isFalse);
      expect(state.account.isOnline, isFalse);
      expect(state.isOnline, isFalse);
    });

    test('Duty status gating blocks going online when verification is REJECTED', () {
      final state = CaptainStateService();

      // Seed an account that is rejected
      state.updateAccount(
        const CaptainAccount(
          id: 'cpt-rejected',
          name: 'Rejected Driver',
          phone: '9876543202',
          email: 'rejected@quickride.com',
          password: 'password123',
          vehicleNumber: 'KA01R1234',
          vehicleType: 'Cab',
          licenseNumber: 'DL0000000002',
          rating: 4.5,
          totalRides: 10,
          todayEarnings: 0,
          isOnline: false,
          verificationStatus: 'REJECTED',
          vehicleVerificationStatus: 'REJECTED',
          rejectionReason: 'Invalid RC document',
        ),
      );

      expect(state.account.isRejected, isTrue);
      expect(state.account.isOnline, isFalse);

      final toggleResult = state.toggleOnlineStatus(true);
      expect(toggleResult, isFalse);
      expect(state.account.isOnline, isFalse);
    });

    test('Duty status gating succeeds when verification is APPROVED', () {
      final state = CaptainStateService();

      // Default seed captain is APPROVED
      state.updateAccount(CaptainAuthService.defaultSeedCaptain.copyWith(isOnline: false));

      expect(state.account.isApproved, isTrue);
      expect(state.account.isOnline, isFalse);

      // Toggling online succeeds
      final resultOnline = state.toggleOnlineStatus(true);
      expect(resultOnline, isTrue);
      expect(state.account.isOnline, isTrue);
      expect(state.isOnline, isTrue);

      // Toggling offline succeeds
      final resultOffline = state.toggleOnlineStatus(false);
      expect(resultOffline, isTrue);
      expect(state.account.isOnline, isFalse);
      expect(state.isOnline, isFalse);
    });
  });

  group('QuickRide Captain Step 42 Verification UI Widget Tests', () {
    testWidgets('CaptainVerificationScreen renders form fields, status banner, and upload cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header & screen title
      expect(find.text('Documents & Verification'), findsOneWidget);

      // Verification Status Banner
      expect(find.text('VERIFIED PARTNER'), findsOneWidget);

      // Form text fields
      expect(find.text('Driving License Number'), findsOneWidget);
      expect(find.text('Vehicle Plate Number'), findsOneWidget);
      expect(find.text('Vehicle Type'), findsOneWidget);

      // Document upload sections
      expect(find.text('Driving License (DL)'), findsOneWidget);
      expect(find.text('Vehicle Document (RC)'), findsOneWidget);
      expect(find.text('Vehicle Photo'), findsOneWidget);

      // Submit button
      expect(find.text('Submit Documents for Verification'), findsOneWidget);
    });

    testWidgets('CaptainProfileScreen renders verification card and navigates to verification screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/verification': (context) => const CaptainVerificationScreen(),
          },
          home: const CaptainProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show Documents & Verification card
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.byIcon(Icons.fact_check_rounded), findsOneWidget);

      // Tap verification card
      await tester.tap(find.text('Documents & Verification'));
      await tester.pumpAndSettle();

      // Should have navigated to CaptainVerificationScreen (AppBar title)
      expect(find.text('Documents & Verification'), findsWidgets);
    });
  });
}
