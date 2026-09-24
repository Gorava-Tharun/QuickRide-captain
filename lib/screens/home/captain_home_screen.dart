import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/captain_state_service.dart';
import '../../services/location_service.dart';
import '../../models/captain_models.dart';
import '../../widgets/ride_request_card.dart';
import '../../widgets/accepted_ride_card.dart';
import '../../widgets/ride_in_progress_card.dart';
import '../../widgets/ride_completed_card.dart';
import '../../widgets/captain_cancellation_dialog.dart';
import '../../services/captain_push_notification_service.dart';
import '../safety/captain_safety_center_screen.dart';
import '../profile/captain_verification_screen.dart';
import '../chat/captain_chat_screen.dart';
import '../earnings/captain_earnings_screen.dart';
import '../support/captain_support_screen.dart';
import '../../widgets/captain_offline_banner.dart';

class CaptainHomeScreen extends StatefulWidget {
  const CaptainHomeScreen({super.key});

  @override
  State<CaptainHomeScreen> createState() => _CaptainHomeScreenState();
}

class _CaptainHomeScreenState extends State<CaptainHomeScreen> {
  GoogleMapController? _mapController;
  LatLng _currentCaptainLatLng = const LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude);
  bool _isLocating = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchCaptainLocation();
    _startTimerTicker();
    CaptainPushNotificationService().initialize(
      captainId: CaptainStateService().account.id,
      onNotificationTap: (rideId, type, [data]) {
        if (!mounted) return;
        if (type == 'RIDE_CANCELLED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The user cancelled the ride.')),
          );
        } else if (type == 'CHAT_MESSAGE') {
          final service = CaptainStateService();
          final req = service.currentRequest;
          final passengerName = req?.passengerName ?? 'Passenger';
          final passengerPhone = req?.passengerPhone ?? '9876543210';
          final pickupAddress = req?.pickupAddress ?? '';
          final dropAddress = req?.dropAddress ?? '';
          final rideStatus = service.rideState == CaptainRideState.rideInProgress ? 'IN_PROGRESS' : 'ACCEPTED';

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaptainChatScreen(
                rideId: rideId.isNotEmpty ? rideId : (req?.id ?? 'REQ-101'),
                currentCaptainId: service.account.id,
                currentCaptainName: service.account.name,
                passengerId: req?.passengerName ?? 'USER_PASSENGER',
                passengerName: passengerName,
                passengerPhone: passengerPhone,
                pickupAddress: pickupAddress,
                dropAddress: dropAddress,
                rideStatus: rideStatus,
              ),
            ),
          );
        } else if (type == 'PAYMENT_RECEIVED' || type == 'PAYMENT_SUCCESS') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment received for completed trip.')),
          );
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaptainEarningsScreen()),
          );
        } else if (type == 'EMERGENCY_ALERT' || type == 'EMERGENCY_STATUS') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaptainSafetyCenterScreen()),
          );
        } else if (type == 'COMPLAINT_STATUS_UPDATE' || type == 'COMPLAINT_REPLY') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaptainSupportScreen()),
          );
        }
      },
    );
  }

  void _startTimerTicker() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final service = CaptainStateService();
      if (service.rideState == CaptainRideState.requestReceived && service.currentRequest != null) {
        if (service.requestSecondsRemaining <= 1) {
          service.expireRequest();
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.timer_off_rounded, color: Colors.amberAccent),
                    SizedBox(width: 10),
                    Text('Ride request expired', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                backgroundColor: AppColors.surfaceDark,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          service.tickTimer();
        }
      } else if (service.rideState == CaptainRideState.rideInProgress) {
        service.tickRideTimer();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCaptainLocation() async {
    setState(() => _isLocating = true);
    final result = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (result.isPermissionGranted && result.position != null) {
      final newLatLng = LatLng(result.position!.latitude, result.position!.longitude);
      setState(() {
        _currentCaptainLatLng = newLatLng;
        _isLocating = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: newLatLng, zoom: 15.5)),
      );
    } else {
      setState(() => _isLocating = false);
    }
  }

  void _onToggleOnline(bool val, CaptainStateService service) {
    if (val && !service.account.isApproved) {
      _showVerificationRequiredDialog(service.account);
      return;
    }

    final success = service.toggleOnlineStatus(val);
    if (!success && val) {
      _showVerificationRequiredDialog(service.account);
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              val ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
              color: val ? AppColors.onlineGreen : Colors.amberAccent,
            ),
            const SizedBox(width: 10),
            Text(val ? 'Captain is now Online' : 'Captain is now Offline', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVerificationRequiredDialog(CaptainAccount account) {
    final isRejected = account.isRejected;
    final status = account.verificationStatus;
    final reason = account.rejectionReason;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: Row(
          children: [
            Icon(
              isRejected ? Icons.highlight_off_rounded : Icons.hourglass_top_rounded,
              color: isRejected ? const Color(0xFFEF4444) : Colors.amberAccent,
            ),
            const SizedBox(width: 10),
            const Text(
              'Verification Required',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          isRejected
              ? 'Your document verification was rejected by Admin.\n\nReason: ${reason ?? "Invalid documents"}\n\nPlease submit updated documents to start receiving rides.'
              : 'Your captain account and vehicle documents are currently $status.\n\nYou cannot go online until an Admin reviews and approves your documents.',
          style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CaptainVerificationScreen(),
                ),
              );
            },
            child: const Text('View Documents',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(RideRequestItem? request, CaptainRideState state, CompletedRideRecord? lastCompleted) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('captain_vehicle_marker'),
        position: _currentCaptainLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(
          title: 'Captain Vehicle Location',
          snippet: 'Your current location',
        ),
      ),
    };

    if (request != null) {
      final pickupLatLng = LatLng(request.pickupLatitude, request.pickupLongitude);
      final dropLatLng = LatLng(request.dropLatitude, request.dropLongitude);

      markers.add(
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Pickup: ${request.passengerName}',
            snippet: request.pickupAddress,
          ),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: dropLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: request.dropAddress,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(RideRequestItem? request, CaptainRideState state) {
    if (request == null) {
      return {};
    }

    // When navigating to pickup or accepted, route from Captain to Pickup
    if (state == CaptainRideState.accepted || state == CaptainRideState.navigatingToPickup) {
      return {
        Polyline(
          polylineId: const PolylineId('captain_to_pickup_route'),
          points: [
            _currentCaptainLatLng,
            LatLng(request.pickupLatitude, request.pickupLongitude),
          ],
          color: state == CaptainRideState.navigatingToPickup ? AppColors.secondary : AppColors.primary,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    // When arrived or in progress, route from Captain/Pickup to Destination
    if (state == CaptainRideState.arrivedAtPickup || state == CaptainRideState.rideInProgress) {
      return {
        Polyline(
          polylineId: const PolylineId('trip_route_to_destination'),
          points: [
            LatLng(request.pickupLatitude, request.pickupLongitude),
            LatLng(request.dropLatitude, request.dropLongitude),
          ],
          color: state == CaptainRideState.rideInProgress ? AppColors.onlineGreen : AppColors.secondary,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    return {};
  }

  void _handleAcceptRide(CaptainStateService service) {
    final success = service.acceptCurrentRequest();
    if (!success) return; // Prevent duplicate acceptance

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
            SizedBox(width: 10),
            Text(
              'Ride accepted successfully',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleNavigateToPickup(CaptainStateService service) {
    service.startNavigationToPickup();

    final req = service.currentRequest;
    if (req != null && _mapController != null) {
      // Fit bounds so both Captain and Pickup locations are visible
      final pickupLatLng = LatLng(req.pickupLatitude, req.pickupLongitude);
      final southWestLat = _currentCaptainLatLng.latitude < pickupLatLng.latitude ? _currentCaptainLatLng.latitude : pickupLatLng.latitude;
      final southWestLng = _currentCaptainLatLng.longitude < pickupLatLng.longitude ? _currentCaptainLatLng.longitude : pickupLatLng.longitude;
      final northEastLat = _currentCaptainLatLng.latitude > pickupLatLng.latitude ? _currentCaptainLatLng.latitude : pickupLatLng.latitude;
      final northEastLng = _currentCaptainLatLng.longitude > pickupLatLng.longitude ? _currentCaptainLatLng.longitude : pickupLatLng.longitude;

      final bounds = LatLngBounds(
        southwest: LatLng(southWestLat - 0.002, southWestLng - 0.002),
        northeast: LatLng(northEastLat + 0.002, northEastLng + 0.002),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.navigation_rounded, color: AppColors.secondary),
            SizedBox(width: 10),
            Text(
              'Navigating to pickup location...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleRejectRide(CaptainStateService service) {
    service.rejectCurrentRequest();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 10),
            Text('Ride request rejected', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCancelRideDialog(CaptainStateService service) async {
    final rideId = service.currentRequest?.id ?? 'active_ride';
    final result = await CaptainCancellationDialog.show(context, rideId: rideId);
    if (result != null && mounted) {
      service.cancelAcceptedRide(
        cancellationReason: result.reason,
        cancellationDescription: result.description,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride cancelled. You are still Online and ready for rides.'),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleArrivedAtPickup(CaptainStateService service) {
    final success = service.arriveAtPickup();
    if (!success) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.place_rounded, color: AppColors.onlineGreen),
            SizedBox(width: 10),
            Text(
              'Captain has arrived at pickup',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showStartRideDialog(CaptainStateService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: const Text('Start Ride', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to start this ride?',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.onlineGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final started = service.startRide();
              if (started) {
                _animateToTripBounds(service.currentRequest);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.play_arrow_rounded, color: AppColors.onlineGreen),
                        SizedBox(width: 10),
                        Text(
                          'Ride started. Heading to destination.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surfaceDark,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Start Ride', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showCompleteRideDialog(CaptainStateService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: const Text('Complete Ride', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to complete this ride?',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final completed = await service.completeRide();
              if (completed && mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
                        SizedBox(width: 10),
                        Text(
                          'Ride completed successfully',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.surfaceDark,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Complete Ride', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _animateToTripBounds(RideRequestItem? req) {
    if (req != null && _mapController != null) {
      final pickupLatLng = LatLng(req.pickupLatitude, req.pickupLongitude);
      final dropLatLng = LatLng(req.dropLatitude, req.dropLongitude);
      final southWestLat = pickupLatLng.latitude < dropLatLng.latitude ? pickupLatLng.latitude : dropLatLng.latitude;
      final southWestLng = pickupLatLng.longitude < dropLatLng.longitude ? pickupLatLng.longitude : dropLatLng.longitude;
      final northEastLat = pickupLatLng.latitude > dropLatLng.latitude ? pickupLatLng.latitude : dropLatLng.latitude;
      final northEastLng = pickupLatLng.longitude > dropLatLng.longitude ? pickupLatLng.longitude : dropLatLng.longitude;

      final bounds = LatLngBounds(
        southwest: LatLng(southWestLat - 0.003, southWestLng - 0.003),
        northeast: LatLng(northEastLat + 0.003, northEastLng + 0.003),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  void _handleTestRequest(CaptainStateService service) {
    if (!service.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please go ONLINE first to receive ride requests.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = service.triggerTestRideRequest();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New mock ride request received!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CaptainStateService(),
      builder: (context, _) {
        final stateService = CaptainStateService();
        final account = stateService.account;
        final currentRequest = stateService.currentRequest;
        final rideState = stateService.rideState;
        final secondsRemaining = stateService.requestSecondsRemaining;

        if (stateService.lastCancellationNotice != null) {
          final notice = stateService.lastCancellationNotice!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              stateService.clearCancellationNotice();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.cancel_outlined, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          notice,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.surfaceDark,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CaptainOfflineBanner(),
                  const SizedBox(height: AppDimensions.space8),
                  if (stateService.isEmergencyActive && stateService.activeEmergency != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        border: Border.all(color: const Color(0xFFEF4444), width: 1.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMERGENCY SOS ACTIVE (${stateService.activeEmergency!.statusLabel})',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                                const Text(
                                  'Live coordinates transmitting to Safety Desk',
                                  style: TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CaptainSafetyCenterScreen(),
                                ),
                              );
                            },
                            child: const Text('VIEW', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _buildHeaderCard(account),
                  const SizedBox(height: AppDimensions.space14),
                  _buildOnlineToggleCard(account.isOnline, stateService),
                  const SizedBox(height: AppDimensions.space14),
                  _buildStatsRow(account, stateService),
                  const SizedBox(height: AppDimensions.space16),
                  _buildMapCard(account.isOnline, currentRequest, rideState, stateService.lastCompletedRide),
                  const SizedBox(height: AppDimensions.space16),

                  // Dev test button (visible only when online and idle)
                  if (account.isOnline && rideState == CaptainRideState.idle && kDebugMode) ...[
                    _buildTestRequestButton(stateService),
                    const SizedBox(height: AppDimensions.space14),
                  ],

                  // Ride Section: Request Received / Accepted / Idle
                  _buildActiveRideSection(
                    currentRequest,
                    rideState,
                    secondsRemaining,
                    account.isOnline,
                    stateService,
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(CaptainAccount account) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.two_wheeler_rounded, size: 28, color: Colors.black),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.onlineGreen),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${account.vehicleType} • ${account.vehicleNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: account.isOnline ? AppColors.onlineGreen.withValues(alpha: 0.15) : AppColors.offlineGrey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: account.isOnline ? AppColors.onlineGreen : AppColors.offlineGrey,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: account.isOnline ? AppColors.onlineGreen : AppColors.offlineGrey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  account.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: account.isOnline ? AppColors.onlineGreen : AppColors.textSecondaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.shield_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Partner Safety Center',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CaptainSafetyCenterScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggleCard(bool isOnline, CaptainStateService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space14),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF0D251D) : const Color(0xFF161F2C),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isOnline ? AppColors.onlineGreen.withValues(alpha: 0.5) : AppColors.borderDark,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.onlineGreen.withValues(alpha: 0.2) : AppColors.offlineGrey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
              color: isOnline ? AppColors.onlineGreen : AppColors.offlineGrey,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'You are Online' : 'You are Offline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isOnline ? AppColors.onlineGreen : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'Waiting for ride requests'
                      : 'Go online to start receiving passenger ride requests',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.1,
            child: Switch(
              value: isOnline,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.onlineGreen,
              inactiveThumbColor: AppColors.offlineGrey,
              inactiveTrackColor: AppColors.surfaceElevatedDark,
              onChanged: (val) => _onToggleOnline(val, service),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(CaptainAccount account, CaptainStateService service) {
    final todayEarnings = service.todayEarningsTotal;
    final todayRides = service.todayCompletedRidesCount;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: "Today's Earnings",
            value: '₹${todayEarnings.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Expanded(
          child: _buildStatCard(
            label: 'Completed Rides',
            value: '$todayRides',
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Expanded(
          child: _buildStatCard(
            label: 'Captain Rating',
            value: '${account.rating}',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(bool isOnline, RideRequestItem? request, CaptainRideState state, CompletedRideRecord? lastCompleted) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCaptainLatLng,
                zoom: 15.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: _buildMarkers(request, state, lastCompleted),
              polylines: _buildPolylines(request, state),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state == CaptainRideState.navigatingToPickup
                            ? AppColors.secondary
                            : isOnline ? AppColors.onlineGreen : AppColors.offlineGrey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state == CaptainRideState.navigatingToPickup
                          ? 'Navigation Live: To Pickup'
                          : isOnline ? 'Captain Live Radar Active' : 'Radar Inactive (Offline)',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: 'captain_locate_fab',
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: AppColors.primary,
                onPressed: _fetchCaptainLocation,
                child: _isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestRequestButton(CaptainStateService service) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () => _handleTestRequest(service),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Test Ride Request (Demo/Dev)',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRideSection(
    RideRequestItem? request,
    CaptainRideState rideState,
    int secondsRemaining,
    bool isOnline,
    CaptainStateService service,
  ) {
    // 1. If RIDE COMPLETED
    if (rideState == CaptainRideState.completed && service.lastCompletedRide != null) {
      return RideCompletedCard(
        record: service.lastCompletedRide!,
        onBackToHome: () {
          service.finishCompletedRideAndReturnHome();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ready for next ride.'),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        },
      );
    }

    // 2. If RIDE IN PROGRESS
    if (rideState == CaptainRideState.rideInProgress && request != null) {
      return RideInProgressCard(
        request: request,
        formattedTimer: service.formattedRideDuration,
        onCompleteRide: () => _showCompleteRideDialog(service),
      );
    }

    // 3. If an active ride is ACCEPTED, NAVIGATING_TO_PICKUP, or ARRIVED_AT_PICKUP
    if (request != null &&
        (rideState == CaptainRideState.accepted ||
            rideState == CaptainRideState.navigatingToPickup ||
            rideState == CaptainRideState.arrivedAtPickup)) {
      return AcceptedRideCard(
        request: request,
        rideState: rideState,
        onNavigateToPickup: () => _handleNavigateToPickup(service),
        onArrivedAtPickup: () => _handleArrivedAtPickup(service),
        onStartRide: () => _showStartRideDialog(service),
        onCancel: () => _showCancelRideDialog(service),
      );
    }

    // 2. If OFFLINE
    if (!isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bedtime_rounded, size: 36, color: AppColors.textMutedDark),
              const SizedBox(height: 8),
              const Text(
                'You are Offline',
                style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Go Online to start receiving incoming passenger ride requests.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.onlineGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Go Online Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                onPressed: () => _onToggleOnline(true, service),
              ),
            ],
          ),
        ),
      );
    }

    // 3. If an incoming request is pending (REQUEST_RECEIVED)
    if (request != null && rideState == CaptainRideState.requestReceived) {
      return RideRequestCard(
        request: request,
        secondsRemaining: secondsRemaining,
        onAccept: () => _handleAcceptRide(service),
        onReject: () => _handleRejectRide(service),
      );
    }

    // 4. Default Waiting for rides (IDLE)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.radar_rounded, size: 36, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'Waiting for ride requests...',
              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'You are Online and visible to nearby QuickRide passengers.',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
