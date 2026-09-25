import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../screens/safety/captain_safety_center_screen.dart';
import '../screens/chat/captain_chat_screen.dart';
import '../services/captain_state_service.dart';

class RideInProgressCard extends StatelessWidget {
  final RideRequestItem request;
  final String formattedTimer;
  final VoidCallback onCompleteRide;

  const RideInProgressCard({
    super.key,
    required this.request,
    required this.formattedTimer,
    required this.onCompleteRide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.secondary,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge & Live Ride Stopwatch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_bike_rounded, size: 14, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text(
                      'RIDE IN PROGRESS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Live Ride Timer Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      formattedTimer,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimaryDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Passenger info & Live metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceElevatedDark,
                    ),
                    child: const Icon(Icons.person_rounded, size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.passengerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            request.passengerPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                    '${request.distanceKm} km total',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 22),

          // Destination Address Focus
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINATION IN PROGRESS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.dropAddress,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Chat & Safety Center Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CaptainChatScreen(
                          rideId: request.id,
                          currentCaptainId: CaptainStateService().account.id,
                          currentCaptainName: CaptainStateService().account.name.isNotEmpty
                              ? CaptainStateService().account.name
                              : 'Captain',
                          passengerId: request.passengerId,
                          passengerName: request.passengerName,
                          passengerPhone: request.passengerPhone,
                          pickupAddress: request.pickupAddress,
                          dropAddress: request.dropAddress,
                          rideStatus: 'IN_PROGRESS',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.secondary, size: 16),
                  label: const Text(
                    'Chat',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.secondary, width: 1.2),
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CaptainSafetyCenterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 16),
                  label: const Text(
                    'SOS Safety',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button: Complete Ride
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
              ),
              icon: const Icon(Icons.flag_rounded, size: 22),
              label: const Text(
                'Complete Ride',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              onPressed: onCompleteRide,
            ),
          ),
        ],
      ),
    );
  }
}
