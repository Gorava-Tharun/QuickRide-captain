import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../screens/safety/captain_safety_center_screen.dart';
import '../screens/chat/captain_chat_screen.dart';

class AcceptedRideCard extends StatelessWidget {
  final RideRequestItem request;
  final CaptainRideState rideState;
  final VoidCallback onNavigateToPickup;
  final VoidCallback? onArrivedAtPickup;
  final VoidCallback? onStartRide;
  final VoidCallback onCancel;

  const AcceptedRideCard({
    super.key,
    required this.request,
    required this.rideState,
    required this.onNavigateToPickup,
    this.onArrivedAtPickup,
    this.onStartRide,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isNavigating = rideState == CaptainRideState.navigatingToPickup;
    final isArrived = rideState == CaptainRideState.arrivedAtPickup;

    final statusColor = isArrived
        ? AppColors.onlineGreen
        : (isNavigating ? AppColors.secondary : AppColors.primary);

    final statusText = isArrived
        ? 'ARRIVED AT PICKUP'
        : (isNavigating ? 'GO TO PICKUP' : 'RIDE ACCEPTED');

    final statusIcon = isArrived
        ? Icons.place_rounded
        : (isNavigating ? Icons.navigation_rounded : Icons.check_circle_rounded);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: statusColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge and DEMO tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: const Text(
                  'ACTIVE DEMO RIDE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Passenger Info Row & Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceElevatedDark,
                    ),
                    child: const Icon(Icons.person_rounded, size: 28, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.passengerName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            request.passengerPhone,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text('• ${request.vehicleType}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '${request.distanceKm} km • ~${request.estimatedMinutes}m',
                    style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.borderDark, height: 24),

          // Pickup Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: AppColors.onlineGreen, size: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PICKUP LOCATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondaryDark)),
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

          // Destination
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

          // Guidance Banner (if navigating or arrived)
          if (isNavigating) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.navigation_rounded, color: AppColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Go to Pickup: Follow map route towards passenger pickup point',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isArrived) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.onlineGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Captain has arrived at pickup. Passenger notified.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                          currentCaptainId: 'captain_seed_01',
                          currentCaptainName: 'Captain',
                          passengerId: request.passengerId,
                          passengerName: request.passengerName,
                          passengerPhone: request.passengerPhone,
                          pickupAddress: request.pickupAddress,
                          dropAddress: request.dropAddress,
                          rideStatus: isArrived ? 'ARRIVED' : 'ACCEPTED',
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

          // Buttons: Cancel Ride & Dynamic Action Button (Navigate / I've Arrived / Start Ride)
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
                  onPressed: onCancel,
                  child: const Text(
                    'Cancel Ride',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: isArrived
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onlineGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Start Ride',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        onPressed: onStartRide,
                      )
                    : isNavigating
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.pin_drop_rounded, size: 20),
                            label: const Text(
                              "I've Arrived",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            onPressed: onArrivedAtPickup,
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.directions_rounded, size: 20),
                            label: const Text(
                              'Navigate to Pickup',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            onPressed: onNavigateToPickup,
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
