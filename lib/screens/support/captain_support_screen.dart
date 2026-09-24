import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/firestore_models.dart';
import '../../services/captain_state_service.dart';
import 'captain_create_complaint_screen.dart';
import 'captain_complaint_details_screen.dart';

class CaptainSupportScreen extends StatefulWidget {
  const CaptainSupportScreen({super.key});

  @override
  State<CaptainSupportScreen> createState() => _CaptainSupportScreenState();
}

class _CaptainSupportScreenState extends State<CaptainSupportScreen> {
  String _selectedStatusFilter = 'ALL';
  int _expandedFaqIndex = -1;

  final List<Map<String, String>> _captainFaqs = const [
    {
      'question': 'When are weekly earnings and incentives settled?',
      'answer':
          'Earnings are settled every Monday by 12:00 PM directly to your registered bank account or UPI ID. Daily instant payouts can be requested from the Earnings screen up to 3 times per day.',
    },
    {
      'question': 'How do passenger cancellation fees work?',
      'answer':
          'If a passenger cancels after 3 minutes from booking, or fails to arrive at the pickup spot within 5 minutes of your arrival, a cancellation fee of ₹30 - ₹50 is credited directly to your captain balance.',
    },
    {
      'question': 'What should I do if a passenger misbehaves or damages the vehicle?',
      'answer':
          'Ensure your safety first. If you are in immediate danger, use the SOS Emergency button (112). For non-emergencies, complete or cancel the ride and file a complaint under "Rider Misconduct / Damage" with photos of any damages.',
    },
    {
      'question': 'Why is my ride fare different from the estimate?',
      'answer':
          'Fares are recalculated based on actual GPS distance travelled and total trip duration. High traffic or passenger-requested route deviations will increase the final fare.',
    },
    {
      'question': 'How does the QuickRide Captain commission rate work?',
      'answer':
          'QuickRide operates on a low flat commission of 10% per ride. During peak incentive windows, commission is waived or subsidised with bonus earnings.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final stateService = CaptainStateService();

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final allComplaints = stateService.complaints;
        final filteredComplaints = _getFilteredComplaints(allComplaints);

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
              'Captain Help & Support',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_comment_rounded),
            label: const Text(
              'File Complaint',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CaptainCreateComplaintScreen(),
                ),
              );
            },
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            children: [
              // Emergency Helpline Banner
              _buildHelplineCard(),
              const SizedBox(height: AppDimensions.space20),

              // Complaints & Support Tickets Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Tickets & Complaints',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${allComplaints.length} Total',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: AppDimensions.space12),

              // Tickets List
              if (filteredComplaints.isEmpty)
                _buildEmptyTicketsView()
              else
                ...filteredComplaints.map(_buildComplaintCard),

              const SizedBox(height: AppDimensions.space24),

              // Frequently Asked Questions
              const Text(
                'Captain FAQs',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              ..._captainFaqs.asMap().entries.map((entry) {
                final idx = entry.key;
                final faq = entry.value;
                return _buildFaqItem(idx, faq['question']!, faq['answer']!);
              }),

              const SizedBox(height: 80), // Fab clearance
            ],
          ),
        );
      },
    );
  }

  List<FirestoreComplaintModel> _getFilteredComplaints(List<FirestoreComplaintModel> list) {
    if (_selectedStatusFilter == 'ALL') return list;
    return list.where((c) => c.status.toUpperCase() == _selectedStatusFilter).toList();
  }

  Widget _buildHelplineCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                '24/7 Captain Assistance',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Need urgent on-trip support or dispute resolution? Our captain partner desk is active 24/7.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHelplineButton(
                  icon: Icons.call_rounded,
                  label: '1800-QR-CAPTAIN',
                  color: AppColors.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling QuickRide Captain Desk: 1800-772-2782')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHelplineButton(
                  icon: Icons.emergency_rounded,
                  label: 'Police SOS (112)',
                  color: AppColors.error,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting to Emergency Services: 112')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ALL', 'OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'];
    final labels = {
      'ALL': 'All',
      'OPEN': 'Open',
      'IN_REVIEW': 'In Review',
      'RESOLVED': 'Resolved',
      'CLOSED': 'Closed',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((status) {
          final isSelected = _selectedStatusFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[status] ?? status),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedStatusFilter = status);
              },
              backgroundColor: AppColors.surfaceDark,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppColors.textSecondaryDark,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.borderDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyTicketsView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 44,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No tickets found',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You do not have any complaints in this status category.',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(FirestoreComplaintModel complaint) {
    final statusColor = _getStatusColor(complaint.status);
    final priorityColor = _getPriorityColor(complaint.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaptainComplaintDetailsScreen(complaint: complaint),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${complaint.complaintId}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        if (complaint.priority == 'HIGH' || complaint.priority == 'URGENT') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: priorityColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              complaint.priority,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            complaint.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.subject,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  complaint.description,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, size: 14, color: AppColors.textSecondaryDark),
                        const SizedBox(width: 4),
                        Text(
                          complaint.category,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (complaint.rideId != null && complaint.rideId!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.two_wheeler_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            complaint.rideId!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index, String question, String answer) {
    final isExpanded = _expandedFaqIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              ListTile(
              onTap: () {
                setState(() {
                  _expandedFaqIndex = isExpanded ? -1 : index;
                });
              },
              title: Text(
                question,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: AppColors.primary,
              ),
            ),
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_REVIEW':
        return Colors.blue;
      case 'RESOLVED':
        return AppColors.onlineGreen;
      case 'CLOSED':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return AppColors.error;
      case 'HIGH':
        return Colors.deepOrange;
      case 'NORMAL':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }
}
