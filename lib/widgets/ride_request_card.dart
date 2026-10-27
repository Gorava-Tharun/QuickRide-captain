import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';

class RideRequestCard extends StatelessWidget {
  final RideRequestItem request;
  final int secondsRemaining;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestCard({
    super.key,
    required this.request,
    required this.secondsRemaining,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsRemaining <= 10;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.isDemo ? Colors.amber : AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (request.isDemo) ...[
                          const Icon(Icons.bolt_rounded, size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          request.isDemo ? 'DEMO REQUEST' : 'NEW RIDE REQUEST',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: request.isDemo ? Colors.amber.withValues(alpha: 0.5) : AppColors.borderDark,
                      ),
                    ),
                    child: Text(
                      request.isDemo ? 'DEMO MODE' : 'REAL-TIME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: request.isDemo ? Colors.amber : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUrgent ? AppColors.error : AppColors.secondary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: isUrgent ? AppColors.error : AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${secondsRemaining}s remaining',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isUrgent ? AppColors.error : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceElevatedDark,
                ),
                child: const Icon(Icons.person_rounded, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimaryDark),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        Text('${request.passengerRating}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600)),
                        Text('• ${request.vehicleType}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${request.estimatedFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    'Est. ${request.distanceKm} km (${request.estimatedMinutes}m)',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: AppColors.primary, size: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 2),
                    Text(
                      request.pickupAddress,
                      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondaryDark)),
                    const SizedBox(height: 2),
                    Text(
                      request.dropAddress,
                      style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onReject,
                  child: const Text('Reject Ride', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Accept Ride', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
