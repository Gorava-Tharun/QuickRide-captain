import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickride_captain/models/firestore_models.dart';
import 'package:quickride_captain/screens/support/captain_support_screen.dart';
import 'package:quickride_captain/screens/support/captain_complaint_details_screen.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 39: QuickRide Captain Support & Complaints Tests', () {
    test('CaptainStateService creates complaint with proper ID, role and defaults', () async {
      final stateService = CaptainStateService();

      final complaint = await stateService.createComplaint(
        category: 'PAYMENT',
        subject: 'Weekly Incentive Calculation',
        description: 'Test description of fare dispute that is sufficiently long.',
        rideId: 'DEMO-101',
        priority: 'NORMAL',
      );

      expect(complaint.complaintId.startsWith('CPT-'), isTrue);
      expect(complaint.complainantRole, 'CAPTAIN');
      expect(complaint.category, 'PAYMENT');
      expect(complaint.priority, 'NORMAL');
      expect(complaint.status, 'OPEN');
      expect(complaint.statusLabel, 'Open');
      expect(complaint.isOpen, isTrue);
      expect(complaint.isResolved, isFalse);

      final found = stateService.complaints.any((c) => c.complaintId == complaint.complaintId);
      expect(found, isTrue);
    });

    test('CaptainStateService adds conversation reply correctly', () async {
      final stateService = CaptainStateService();

      final complaint = await stateService.createComplaint(
        category: 'RIDER_ISSUE',
        subject: 'Rider Damaged Seat',
        description: 'Rider tore the back seat cushion during the trip.',
        priority: 'HIGH',
      );

      final replySuccess = await stateService.sendComplaintReply(
        complaintId: complaint.complaintId,
        message: 'I have attached photos of the torn cushion.',
      );

      expect(replySuccess, isTrue);
    });

    testWidgets('CaptainSupportScreen renders emergency cards, FAQs and tickets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaptainSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Captain Help & Support'), findsOneWidget);
      expect(find.text('24/7 Captain Assistance'), findsOneWidget);
      expect(find.text('1800-QR-CAPTAIN'), findsOneWidget);
      expect(find.text('Police SOS (112)'), findsOneWidget);
      expect(find.text('File Complaint'), findsOneWidget);
      expect(find.text('My Tickets & Complaints'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Captain FAQs'), findsOneWidget);
    });

    testWidgets('CaptainComplaintDetailsScreen renders overview, description and replies', (tester) async {
      final testComplaint = FirestoreComplaintModel(
        complaintId: 'CPT-TEST-99',
        captainId: 'captain_seed_01',
        complainantRole: 'CAPTAIN',
        complainantName: 'Vikram Singh',
        category: 'PAYMENT',
        subject: 'Toll Reimbursement Missing',
        description: 'Airport toll of ₹110 was paid in cash but not added to rider invoice.',
        rideId: 'DEMO-101',
        status: 'OPEN',
        priority: 'NORMAL',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CaptainComplaintDetailsScreen(complaint: testComplaint),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ticket #CPT-TEST-99'), findsOneWidget);
      expect(find.text('Toll Reimbursement Missing'), findsOneWidget);
      expect(find.text('Ride #DEMO-101'), findsOneWidget);
      expect(find.text('Support Conversation'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
