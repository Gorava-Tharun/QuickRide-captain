import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../services/captain_firebase_service.dart';
import '../../services/captain_state_service.dart';
import '../support/captain_create_complaint_screen.dart';

/// STEP 40: QuickRide Captain Safety Center & Emergency Management Screen.
class CaptainSafetyCenterScreen extends StatefulWidget {
  const CaptainSafetyCenterScreen({super.key});

  @override
  State<CaptainSafetyCenterScreen> createState() => _CaptainSafetyCenterScreenState();
}

class _CaptainSafetyCenterScreenState extends State<CaptainSafetyCenterScreen> {
  late final CaptainStateService _stateService;

  @override
  void initState() {
    super.initState();
    _stateService = CaptainStateService();
    _stateService.recoverActiveEmergency();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open phone dialer for $phoneNumber'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialer error: $phoneNumber'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSOSConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Captain Emergency SOS',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'High-Priority Incident Alert',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will immediately create an ACTIVE emergency alert on the QuickRide Safety Operations Desk with your live coordinates and vehicle details.\n\nIf you are in immediate physical danger, dial 112 immediately.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await _stateService.triggerSOS(
                reason: 'Captain triggered emergency SOS from Partner Safety Center',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'ðŸš¨ Emergency SOS Activated. Live location telemetry is transmitting.'
                          : 'Emergency recorded locally. Transmitting alert.',
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            icon: const Icon(Icons.emergency_rounded, size: 18),
            label: const Text('CONFIRM SOS', style: TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String relationship = 'Family';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            side: const BorderSide(color: AppColors.borderDark),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    hintText: 'e.g. Spouse, Brother, QuickRide Depot',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Family', child: Text('Family')),
                    DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                    DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                    DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                    DropdownMenuItem(value: 'Depot Manager', child: Text('Depot Manager')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => relationship = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final messenger = ScaffoldMessenger.of(context);
                if (name.isEmpty || phone.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Please enter both name and phone number.')),
                  );
                  return;
                }

                final captainId = _stateService.account.id;
                final contact = FirestoreEmergencyContactModel(
                  contactId: 'contact_cpt_${DateTime.now().millisecondsSinceEpoch}',
                  ownerId: captainId,
                  name: name,
                  phone: phone,
                  relationship: relationship,
                  createdAt: DateTime.now(),
                );

                final ok = await CaptainFirebaseService().addEmergencyContact(contact);
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Emergency contact added' : 'Failed to add contact'),
                    backgroundColor: ok ? const Color(0xFF10B981) : AppColors.error,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundDark,
              ),
              child: const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Captain Safety Center',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _stateService,
          builder: (context, _) {
            final activeEmergency = _stateService.activeEmergency;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Active Emergency Banner (if active)
                  if (activeEmergency != null && activeEmergency.isActive)
                    _buildActiveEmergencyBanner(activeEmergency),

                  // 2. Overview Banner
                  _buildHeaderBanner(),
                  const SizedBox(height: AppDimensions.space16),

                  // 3. Emergency SOS Section
                  _buildEmergencySection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 4. Emergency Contacts Section
                  _buildEmergencyContactsSection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 5. Safety Guidelines
                  _buildSafetyGuidelinesSection(),
                  const SizedBox(height: AppDimensions.space20),

                  // 6. Report Safety Issue
                  _buildReportSafetyIssueSection(),
                  const SizedBox(height: AppDimensions.space24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveEmergencyBanner(FirestoreEmergencyIncidentModel emergency) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: const Color(0xFFEF4444), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMERGENCY ALERT ACTIVE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEF4444),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'ID: ${emergency.emergencyId}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emergency.isAcknowledged ? Colors.amber : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  emergency.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'QuickRide Operations Desk is receiving live location telemetry. If there is immediate threat to your life or vehicle, call 112 directly.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimaryDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _makePhoneCall('112'),
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Call 112 Helpline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Partner Safety & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '24/7 incident response, instant distress dispatch, and verified emergency contact routing for captains.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 8),
              Text(
                'Captain Emergency SOS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Feeling in danger, dealing with an abusive rider, accident, or medical emergency during a ride?',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimaryDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _showSOSConfirmationDialog,
            icon: const Icon(Icons.warning_amber_rounded, size: 20),
            label: const Text(
              'Trigger Emergency SOS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    final captainId = _stateService.account.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Keep family or depot managers handy for instant 1-tap call during distress.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<FirestoreEmergencyContactModel>>(
            stream: CaptainFirebaseService().streamEmergencyContacts(captainId),
            builder: (context, snapshot) {
              final contacts = snapshot.data ?? [];
              if (contacts.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, color: AppColors.textSecondaryDark, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No emergency contacts saved yet.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ),
                      TextButton(
                        onPressed: _showAddContactDialog,
                        child: const Text('Add Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: contacts.map((contact) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    contact.name,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardDark,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      contact.relationship ?? 'Contact',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                contact.phone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                          tooltip: 'Call ${contact.name}',
                          onPressed: () => _makePhoneCall(contact.phone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondaryDark, size: 18),
                          tooltip: 'Remove',
                          onPressed: () async {
                            await CaptainFirebaseService().deleteEmergencyContact(captainId, contact.contactId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed ${contact.name} from emergency contacts')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyGuidelinesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.rule_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Captain Safety Protocols',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildProtocolCard(
            title: 'Night Rides & Isolated Drop-offs',
            bullets: const [
              'Stay in well-lit public areas whenever possible.',
              'Avoid taking unverified route diversions suggested by riders.',
              'Trigger Emergency SOS immediately if forced into an unfamiliar location.',
            ],
          ),
          const SizedBox(height: 8),
          _buildProtocolCard(
            title: 'Accident & Vehicle Breakdown',
            bullets: const [
              'Ensure rider safety first and move to the curb/footpath.',
              'Turn on hazard lights and place vehicle in neutral.',
              'Call 112 if medical assistance is needed; notify QuickRide via SOS.',
            ],
          ),
          const SizedBox(height: 8),
          _buildProtocolCard(
            title: 'Disruptive or Threatening Behavior',
            bullets: const [
              'Do not engage in verbal or physical confrontation.',
              'Safely stop near a police booth, fuel station, or crowded area.',
              'Use the Emergency SOS button to dispatch live telemetry to QuickRide.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({required String title, required List<String> bullets}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondaryDark,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryDark,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: bullets.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('â€¢ ', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondaryDark,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportSafetyIssueSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Report Safety Incident',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Encountered rider harassment, fraud, or route hazards? Log an official report with QuickRide Partner Safety Support.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CaptainCreateComplaintScreen(
                    
                    preselectedRideId: _stateService.currentRequest?.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 18),
            label: const Text(
              'Submit Safety Report',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}