import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickride_captain/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QuickRide Captain App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuickRideCaptainApp());
    expect(find.text('QuickRide Captain'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 1500));
  });
}
