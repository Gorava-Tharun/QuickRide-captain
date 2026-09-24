import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../../services/captain_state_service.dart';

class RideCompletedCard extends StatefulWidget {
  final CompletedRideRecord record;
  final VoidCallback onBackToHome;

  const RideCompletedCard({
    super.key,
    required this.record,
    required this.onBackToHome,
  });

  @override
  State<RideCompletedCard> createState() => _RideCompletedCardState();
}

class _RideCompletedCardState extends State<RideCompletedCard> {
  int _selectedStars = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitRating() async {
    if (_selectedStars < 1 || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final rideId = widget.record.rideId ?? widget.record.id;
    final success = await CaptainStateService().ratePassenger(
      rideId,
      _selectedStars,
      review: _reviewController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Passenger rating submitted successfully!' : 'Rating saved locally.',
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final isAlreadyRated = record.isRated || _submitted;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.onlineGreen,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onlineGreen.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Header: Success Icon & Message
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onlineGreen.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIDE COMPLETED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onlineGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ride completed successfully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 26),

          // Fare Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FINAL EARNING / FARE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.paymentStatus == 'PAID'
                          ? 'Payment received (${record.paymentMethod ?? 'Online'})'
                          : 'Payment Pending • Collect Cash',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: record.paymentStatus == 'PAID'
                            ? AppColors.onlineGreen
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${record.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Trip Details
          _buildDetailRow(
            icon: Icons.person_rounded,
            iconColor: AppColors.primary,
            label: 'Passenger',
            value: '${record.passengerName} (${record.passengerPhone})',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.circle,
            iconColor: AppColors.onlineGreen,
            label: 'Pickup',
            value: record.pickupAddress,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: 'Destination',
            value: record.dropAddress,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.speed_rounded,
            iconColor: AppColors.secondary,
            label: 'Distance & Duration',
            value: '${record.distanceKm} km  •  ${record.formattedDuration}',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            iconColor: AppColors.textSecondaryDark,
            label: 'Completion Time',
            value: _formatTime(record.completionTime),
          ),
          const SizedBox(height: 16),

          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 16),

          // Rate Passenger Section
          if (isAlreadyRated) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger Rated (${record.rating ?? _selectedStars}★)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        if ((record.reviewText ?? _reviewController.text).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '"${record.reviewText ?? _reviewController.text}"',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Saved',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.onlineGreen),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Rate Passenger (${record.passengerName})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),

            // 1–5 Star Rating Row
            Row(
              children: List.generate(5, (index) {
                final starVal = index + 1;
                final isSelected = starVal <= _selectedStars;
                return IconButton(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSelected ? Colors.amber : AppColors.textMutedDark,
                    size: 32,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _selectedStars = starVal),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Optional Review Input
            TextField(
              controller: _reviewController,
              enabled: !_isSubmitting,
              maxLines: 2,
              maxLength: 500,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Optional written review about passenger...',
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                filled: true,
                fillColor: AppColors.surfaceElevatedDark,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
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
            const SizedBox(height: 10),

            // Submit Rating Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onlineGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.star_rate_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Rating',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                onPressed: _isSubmitting ? null : _handleSubmitRating,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Return Home Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderDark),
                foregroundColor: AppColors.textPrimaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text(
                'Back to Home',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              onPressed: widget.onBackToHome,
            ),
          ),
        ],
      ),
      ),
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondaryDark),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
