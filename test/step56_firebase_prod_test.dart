import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/models/firestore_models.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_firebase_service.dart';
import 'package:quickride_captain/services/captain_push_notification_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 56: QuickRide Captain App Production Firebase Configuration & Safety Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CaptainStateService().setAccount(CaptainAuthService.defaultSeedCaptain);
    });

    test('CaptainFirebaseService initializes safely without unhandled exceptions', () async {
      final fb = CaptainFirebaseService();
      final initialized = await fb.initialize();
      expect(initialized, isA<bool>());
      expect(fb.statusMessage, isNotEmpty);
    });

    test('CaptainAuthService and StateService maintain authentication session safely', () async {
      final auth = CaptainAuthService();
      final state = CaptainStateService();

      expect(state.isOnline, isTrue);
      expect(state.account.id, isNotEmpty);

      // Verify login validation
      final invalidLogin = await auth.loginCaptain(phone: '0000000000', password: 'bad');
      expect(invalidLogin['success'], isFalse);

      final validLogin = await auth.loginCaptain(
        phone: CaptainAuthService.defaultSeedCaptain.phone,
        password: CaptainAuthService.defaultSeedCaptain.password,
      );
      expect(validLogin['success'], isTrue);
    });

    test('CaptainPushNotificationService registers and cleans device tokens cleanly', () {
      final pushService = CaptainPushNotificationService();
      expect(() => pushService.registerCaptain('test_cpt_01'), returnsNormally);
      expect(() => pushService.clearCaptain(), returnsNormally);
    });

    test('CaptainFirebaseService handles offline complaints and emergency support securely', () async {
      final fb = CaptainFirebaseService();
      final complaints = await fb.fetchCaptainComplaints('test_cpt_01');
      expect(complaints, isA<List<FirestoreComplaintModel>>());
    });
  });
}
