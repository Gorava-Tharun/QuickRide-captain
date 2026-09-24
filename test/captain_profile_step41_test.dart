import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/captain_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';
import 'package:quickride_captain/screens/profile/captain_profile_screen.dart';
import 'package:quickride_captain/screens/profile/captain_edit_profile_screen.dart';
import 'package:quickride_captain/screens/profile/captain_change_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('QuickRide Captain Step 41 Profile & Password Unit Tests', () {
    test('CaptainAuthService changePassword validates requirements and updates password', () async {
      final auth = CaptainAuthService();

      // Log in initial seed captain
      final login = await auth.loginCaptain(
        phone: '9876543210',
        password: 'password123',
      );
      expect(login['success'], isTrue);

      // 1. Empty current password fails
      final failEmptyCurrent = await auth.changePassword(
        currentPassword: '',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(failEmptyCurrent['success'], isFalse);

      // 2. Short new password (< 6 chars) fails
      final failShort = await auth.changePassword(
        currentPassword: 'password123',
        newPassword: '12345',
        confirmPassword: '12345',
      );
      expect(failShort['success'], isFalse);

      // 3. Mismatched passwords fail
      final failMismatch = await auth.changePassword(
        currentPassword: 'password123',
        newPassword: 'newpassword123',
        confirmPassword: 'differentpassword',
      );
      expect(failMismatch['success'], isFalse);

      // 4. Incorrect current password fails
      final failWrongCurrent = await auth.changePassword(
        currentPassword: 'wrongpassword',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(failWrongCurrent['success'], isFalse);

      // 5. Successful password change
      final success = await auth.changePassword(
        currentPassword: 'password123',
        newPassword: 'newpassword123',
        confirmPassword: 'newpassword123',
      );
      expect(success['success'], isTrue);

      // 6. Verify login works with new password
      final newLogin = await auth.loginCaptain(
        phone: '9876543210',
        password: 'newpassword123',
      );
      expect(newLogin['success'], isTrue);
    });

    test('CaptainStateService updateProfile updates all editable fields and persists', () {
      final state = CaptainStateService();

      state.updateProfile(
        name: 'Vikramaditya Rao',
        phone: '9845012345',
        email: 'vikram.rao@quickride.com',
        vehicleNumber: 'KA-01-AB-9999',
        vehicleType: 'Bajaj RE (Auto)',
        licenseNumber: 'DL-KA0120220001234',
      );

      final updated = state.account;
      expect(updated.name, 'Vikramaditya Rao');
      expect(updated.phone, '9845012345');
      expect(updated.email, 'vikram.rao@quickride.com');
      expect(updated.vehicleNumber, 'KA-01-AB-9999');
      expect(updated.vehicleType, 'Bajaj RE (Auto)');
      expect(updated.licenseNumber, 'DL-KA0120220001234');
    });
  });

  group('QuickRide Captain Step 41 Profile UI Widget Tests', () {
    testWidgets('CaptainProfileScreen renders details, badges, and action buttons', (tester) async {
      final state = CaptainStateService();
      state.setAccount(
        const CaptainAccount(
          id: 'CPT-TEST-01',
          name: 'Vikram Singh',
          phone: '9876543210',
          email: 'vikram@quickride.com',
          password: 'password123',
          vehicleNumber: 'KA-05-HA-1234',
          vehicleType: 'Honda Activa 6G (Bike)',
          licenseNumber: 'DL-KA0520210009876',
          rating: 4.88,
          totalRides: 148,
          isOnline: true,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Profile'), findsOneWidget);
      expect(find.text('Vikram Singh'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('4.9 Rating'), findsOneWidget);
      expect(find.text('•  148 Rides'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('CPT-TEST-01'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('vikram@quickride.com'), findsOneWidget);
      expect(find.text('KA-05-HA-1234'), findsOneWidget);
      expect(find.text('DL-KA0520210009876'), findsOneWidget);
    });

    testWidgets('CaptainProfileScreen Logout button shows confirmation dialog and can cancel', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Logout'), 200);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Logout Confirmation'), findsOneWidget);
      expect(find.text('Are you sure you want to log out of QuickRide Captain?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Logout Confirmation'), findsNothing);
    });

    testWidgets('CaptainEditProfileScreen validates inputs and displays protected Captain ID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainEditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Captain Profile'), findsOneWidget);
      expect(find.text('Captain ID (Protected)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Enter invalid phone
      final phoneField = find.byType(TextFormField).at(1);
      await tester.enterText(phoneField, '123');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 10-digit phone number'), findsOneWidget);
    });

    testWidgets('CaptainChangePasswordScreen renders and validates password length', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainChangePasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Update Captain Password'), findsOneWidget);

      // Scroll to and tap submit with empty fields
      await tester.scrollUntilVisible(
        find.text('Update Password'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is required'), findsOneWidget);
    });
  });
}
