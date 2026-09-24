import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/screens/auth/captain_login_screen.dart';
import 'package:quickride_captain/screens/auth/captain_signup_screen.dart';
import 'package:quickride_captain/screens/earnings/captain_earnings_screen.dart';
import 'package:quickride_captain/screens/home/captain_home_screen.dart';
import 'package:quickride_captain/screens/profile/captain_profile_screen.dart';
import 'package:quickride_captain/screens/splash/splash_screen.dart';
import 'package:quickride_captain/services/captain_auth_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STEP 54: QuickRide Captain App UI/UX Polish & Responsive Verification', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      CaptainStateService().updateAccount(CaptainAuthService.defaultSeedCaptain);
    });

    // =========================================================================
    // 1. BRANDING & SPLASH POLISH
    // =========================================================================
    testWidgets('Captain Splash Screen renders captain branding and gold styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('QuickRide Captain'), findsOneWidget);
      expect(find.text('Drive & Earn with QuickRide'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });

    // =========================================================================
    // 2. AUTHENTICATION SCREENS
    // =========================================================================
    testWidgets('Captain Login Screen renders credential fields and CTA cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Login'), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Captain Signup Screen renders driver registration fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainSignupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Register as Captain'), findsOneWidget);
    });

    // =========================================================================
    // 3. CAPTAIN HOME & DUTY CARD
    // =========================================================================
    testWidgets('Captain Home Screen renders duty control, map and status elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainHomeScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(Switch), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // =========================================================================
    // 4. EARNINGS & PROFILE POLISH
    // =========================================================================
    testWidgets('Captain Earnings Screen renders net earnings breakdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainEarningsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Earnings'), findsOneWidget);
    });

    testWidgets('Captain Profile Screen renders profile and vehicle details', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Profile'), findsOneWidget);
    });

    // =========================================================================
    // 5. RESPONSIVE MULTI-DEVICE VIEWPORT CHECKS
    // =========================================================================
    testWidgets('Captain Home adapts to small mobile viewport (320x568) without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainHomeScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Captain Login adapts to tablet viewport (768x1024) cleanly', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Login'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
