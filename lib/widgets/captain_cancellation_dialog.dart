import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Common cancellation reasons for captains
const List<String> kCaptainCancellationReasons = [
  'Cannot reach pickup',
  'Vehicle issue',
  'Passenger unavailable',
  'Other',
];

/// Result returned when captain cancels an active ride
class CaptainCancellationResult {
  final String reason;
  final String? description;

  const CaptainCancellationResult({
    required this.reason,
    this.description,
  });
}

/// Interactive dialog for captains to select cancellation reason before canceling
class CaptainCancellationDialog extends StatefulWidget {
  final String rideId;

  const CaptainCancellationDialog({
    super.key,
    required this.rideId,
  });

  static Future<CaptainCancellationResult?> show(
    BuildContext context, {
    required String rideId,
  }) {
    return showDialog<CaptainCancellationResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CaptainCancellationDialog(rideId: rideId),
    );
  }

  @override
  State<CaptainCancellationDialog> createState() => _CaptainCancellationDialogState();
}

class _CaptainCancellationDialogState extends State<CaptainCancellationDialog> {
  String _selectedReason = kCaptainCancellationReasons.first;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cancel Ride',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The passenger will not be charged. If paid online, a 100% refund will be granted automatically.',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason for cancellation:',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...kCaptainCancellationReasons.map((reason) {
              final isSelected = _selectedReason == reason;
              return InkWell(
                onTap: () => setState(() => _selectedReason = reason),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.textSecondaryDark,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: isSelected ? AppColors.textPrimaryDark : AppColors.textSecondaryDark,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13),
              decoration: InputDecoration(
                hintText: _selectedReason == 'Other' ? 'Describe reason (required)...' : 'Additional notes (optional)...',
                hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: const EdgeInsets.all(10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            'Keep Ride',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedReason == 'Other' && _notesController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please describe the reason for "Other"')),
              );
              return;
            }
            Navigator.of(context).pop(
              CaptainCancellationResult(
                reason: _selectedReason,
                description: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
          child: const Text(
            'Confirm Cancel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
