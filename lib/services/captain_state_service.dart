import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/captain_models.dart';
import '../models/firestore_models.dart';
import 'captain_auth_service.dart';
import 'captain_firebase_service.dart';
import 'captain_push_notification_service.dart';
import 'captain_connectivity_service.dart';
import 'location_service.dart';

class CaptainStateService extends ChangeNotifier {
  static final CaptainStateService _instance = CaptainStateService._internal();
  factory CaptainStateService() => _instance;
  CaptainStateService._internal() {
    loadCompletedRides();
    recoverActiveRide();
    recoverActiveEmergency();
    initComplaintsListener();
    if (_account.isOnline) {
      _startFirestoreRequestListener();
    }
    CaptainConnectivityService().addReconnectionListener(() async {
      debugPrint('[CaptainStateService] Reconnected: syncing captain state');
      await recoverActiveRide();
      if (_account.isOnline) {
        _startFirestoreRequestListener();
      }
    });
  }

  static const String _completedRidesKey = 'quickride_captain_completed_rides';

  CaptainAccount _account = CaptainAuthService.defaultSeedCaptain;

  // Step 40: Emergency State & Telemetry
  FirestoreEmergencyIncidentModel? _activeEmergency;
  FirestoreEmergencyIncidentModel? get activeEmergency => _activeEmergency;
  bool get isEmergencyActive => _activeEmergency != null && _activeEmergency!.isActive;
  StreamSubscription<FirestoreEmergencyIncidentModel?>? _emergencySub;

  // Ride State Machine: IDLE, REQUEST_RECEIVED, ACCEPTED, NAVIGATING_TO_PICKUP, ARRIVED_AT_PICKUP, RIDE_IN_PROGRESS, COMPLETED
  CaptainRideState _rideState = CaptainRideState.idle;

  // Current active request or accepted ride
  RideRequestItem? _currentRequest;
  int _requestSecondsRemaining = 30;
  StreamSubscription<List<SharedRideModel>>? _requestSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<SharedRideModel?>? _activeRideSubscription;
  String? _lastCancellationNotice;

  String? get lastCancellationNotice => _lastCancellationNotice;
  void clearCancellationNotice() => _lastCancellationNotice = null;

  // Ride in progress timer
  int _rideDurationSeconds = 0;

  // Last completed ride and saved records history
  CompletedRideRecord? _lastCompletedRide;
  List<CompletedRideRecord> _completedRides = [];

  static const List<RideRequestItem> _mockRequestPool = [
    RideRequestItem(
      id: 'REQ-101',
      passengerName: 'Rahul',
      passengerPhone: '+91 98450 77123',
      passengerRating: 4.85,
      pickupAddress: 'Main Road, 100 Feet Corner, Indiranagar',
      pickupLatitude: 12.9785,
      pickupLongitude: 77.6405,
      dropAddress: 'Railway Station, City Center Platform 1',
      dropLatitude: 12.9772,
      dropLongitude: 77.5695,
      distanceKm: 4.2,
      estimatedMinutes: 12,
      vehicleType: 'Bike',
      estimatedFare: 75.0,
      paymentMode: 'Cash / UPI',
    ),
    RideRequestItem(
      id: 'REQ-102',
      passengerName: 'Priya',
      passengerPhone: '+91 99801 22334',
      passengerRating: 4.92,
      pickupAddress: 'Koramangala 4th Block, 80 Feet Road',
      pickupLatitude: 12.9345,
      pickupLongitude: 77.6265,
      dropAddress: 'MG Road Metro Station, Gate 3',
      dropLatitude: 12.9756,
      dropLongitude: 77.6066,
      distanceKm: 5.8,
      estimatedMinutes: 16,
      vehicleType: 'Bike',
      estimatedFare: 95.0,
      paymentMode: 'Online / UPI',
    ),
  ];

  int _poolIndex = 0;

  CaptainAccount get account => _account;
  CaptainAccount get profile => _account;

  void updateAccount(CaptainAccount account) {
    _account = account;
    notifyListeners();
  }

  bool get isOnline => _account.isOnline;
  CaptainRideState get rideState => _rideState;
  RideRequestItem? get currentRequest => _currentRequest;
  RideRequestItem? get acceptedRide => hasActiveAcceptedRide ? _currentRequest : null;
  int get requestSecondsRemaining => _requestSecondsRemaining;

  bool get hasActiveAcceptedRide =>
      _rideState == CaptainRideState.accepted ||
      _rideState == CaptainRideState.navigatingToPickup ||
      _rideState == CaptainRideState.arrivedAtPickup ||
      _rideState == CaptainRideState.rideInProgress ||
      _rideState == CaptainRideState.completed;

  int get rideDurationSeconds => _rideDurationSeconds;
  CompletedRideRecord? get lastCompletedRide => _lastCompletedRide;
  List<CompletedRideRecord> get completedRides => List.unmodifiable(_completedRides);

  String get formattedRideDuration {
    final minutes = _rideDurationSeconds ~/ 60;
    final seconds = _rideDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // --- Reusable Earnings & History Calculations (Step 28) ---
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isSameWeek(DateTime date, DateTime now) {
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return (date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek)) &&
        date.isBefore(endOfWeek);
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  List<CompletedRideRecord> _deduplicatePaidRides(Iterable<CompletedRideRecord> rides) {
    final seen = <String>{};
    final list = <CompletedRideRecord>[];
    for (final r in rides) {
      if (!r.isPaid) continue;
      final key = (r.rideId != null && r.rideId!.isNotEmpty) ? r.rideId! : r.id;
      if (seen.add(key)) {
        list.add(r);
      }
    }
    return list;
  }

  // Today's Stats
  List<CompletedRideRecord> get todayRides {
    final now = DateTime.now();
    return _completedRides.where((r) => _isSameDay(r.completionTime, now)).toList();
  }

  List<CompletedRideRecord> get todayPaidRides => _deduplicatePaidRides(todayRides);

  double get todayEarningsTotal {
    return todayPaidRides.fold(0.0, (sum, r) => sum + r.fare);
  }

  double get todayCaptainEarningsNet {
    return todayPaidRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  }

  double get todayPlatformFeeTotal {
    return todayPaidRides.fold(0.0, (sum, r) => sum + r.platformFee);
  }

  int get todayCompletedRidesCount => todayPaidRides.length;

  // Weekly Stats
  List<CompletedRideRecord> get weeklyRides {
    final now = DateTime.now();
    return _completedRides.where((r) => _isSameWeek(r.completionTime, now)).toList();
  }

  List<CompletedRideRecord> get weeklyPaidRides => _deduplicatePaidRides(weeklyRides);

  double get weeklyEarningsTotal {
    return weeklyPaidRides.fold(0.0, (sum, r) => sum + r.fare);
  }

  double get weeklyCaptainEarningsNet {
    return weeklyPaidRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  }

  double get weeklyPlatformFeeTotal {
    return weeklyPaidRides.fold(0.0, (sum, r) => sum + r.platformFee);
  }

  int get weeklyCompletedRidesCount => weeklyPaidRides.length;

  // Monthly Stats
  List<CompletedRideRecord> get monthlyRides {
    final now = DateTime.now();
    return _completedRides.where((r) => _isSameMonth(r.completionTime, now)).toList();
  }

  List<CompletedRideRecord> get monthlyPaidRides => _deduplicatePaidRides(monthlyRides);

  double get monthlyEarningsTotal {
    return monthlyPaidRides.fold(0.0, (sum, r) => sum + r.fare);
  }

  double get monthlyCaptainEarningsNet {
    return monthlyPaidRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  }

  double get monthlyPlatformFeeTotal {
    return monthlyPaidRides.fold(0.0, (sum, r) => sum + r.platformFee);
  }

  int get monthlyCompletedRidesCount => monthlyPaidRides.length;

  // Overall / Total Stats
  List<CompletedRideRecord> get totalPaidRides => _deduplicatePaidRides(_completedRides);

  double get totalEarnings {
    return totalPaidRides.fold(0.0, (sum, r) => sum + r.fare);
  }

  double get totalCaptainEarningsNet {
    return totalPaidRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  }

  double get totalPlatformFeeTotal {
    return totalPaidRides.fold(0.0, (sum, r) => sum + r.platformFee);
  }

  int get totalCompletedRidesCount => totalPaidRides.length;

  // Average Fare
  double get averageFare {
    if (totalPaidRides.isEmpty) return 0.0;
    return totalEarnings / totalPaidRides.length;
  }

  void setAccount(CaptainAccount newAccount) {
    _account = newAccount;
    notifyListeners();
  }

  bool toggleOnlineStatus(bool status) {
    if (status && _account.verificationStatus != 'APPROVED') {
      debugPrint('[CaptainStateService] Duty blocked: Captain verification is ${_account.verificationStatus}');
      notifyListeners();
      return false;
    }

    _account = _account.copyWith(isOnline: status);
    CaptainAuthService().updateActiveCaptain(_account);

    final fb = CaptainFirebaseService();
    if (fb.isFirebaseAvailable) {
      fb.syncCaptainProfile(
        FirestoreCaptainModel(
          captainId: _account.id,
          name: _account.name,
          phone: _account.phone,
          email: _account.email,
          vehicleNumber: _account.vehicleNumber,
          vehicleType: _account.vehicleType,
          drivingLicenseNumber: _account.licenseNumber,
          rating: _account.rating,
          online: status,
          profileImage: _account.profileImageUrl,
          vehicleImage: _account.vehicleImageUrl,
          verificationStatus: _account.verificationStatus,
          vehicleVerificationStatus: _account.vehicleVerificationStatus,
          documentsSubmittedAt: _account.documentsSubmittedAt,
          verifiedAt: _account.verifiedAt,
          rejectionReason: _account.rejectionReason,
          drivingLicenseImageUrl: _account.drivingLicenseImageUrl,
          vehicleDocumentImageUrl: _account.vehicleDocumentImageUrl,
          createdAt: DateTime.now(),
        ),
      );
      fb.updateDutyStatus(_account.id, status);
    }

    if (status) {
      _startFirestoreRequestListener();
    } else {
      _requestSubscription?.cancel();
      // Safe handling: If going offline without an active accepted ride, clear request.
      // If a ride is already accepted, do not silently delete the ride!
      if (!hasActiveAcceptedRide) {
        _currentRequest = null;
        _rideState = CaptainRideState.idle;
        _stopActiveGpsTracking();
      }
    }
    notifyListeners();
    return true;
  }

  /// Submit or update verification documents for admin review
  Future<bool> submitVerificationDocuments({
    String? licenseImageUrl,
    String? vehicleDocumentImageUrl,
    String? vehicleImageUrl,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
  }) async {
    final now = DateTime.now();
    _account = _account.copyWith(
      drivingLicenseImageUrl: licenseImageUrl ?? _account.drivingLicenseImageUrl,
      vehicleDocumentImageUrl:
          vehicleDocumentImageUrl ?? _account.vehicleDocumentImageUrl,
      vehicleImageUrl: vehicleImageUrl ?? _account.vehicleImageUrl,
      vehicleType: vehicleType ?? _account.vehicleType,
      vehicleNumber: vehicleNumber ?? _account.vehicleNumber,
      licenseNumber: licenseNumber ?? _account.licenseNumber,
      verificationStatus: 'PENDING',
      vehicleVerificationStatus: 'PENDING',
      documentsSubmittedAt: now,
      rejectionReason: null,
      isOnline: false,
    );
    await CaptainAuthService().updateActiveCaptain(_account);

    final fb = CaptainFirebaseService();
    if (fb.isFirebaseAvailable) {
      await fb.syncCaptainProfile(
        FirestoreCaptainModel(
          captainId: _account.id,
          name: _account.name,
          phone: _account.phone,
          email: _account.email,
          vehicleNumber: _account.vehicleNumber,
          vehicleType: _account.vehicleType,
          drivingLicenseNumber: _account.licenseNumber,
          rating: _account.rating,
          online: _account.isOnline,
          profileImage: _account.profileImageUrl,
          vehicleImage: _account.vehicleImageUrl,
          verificationStatus: 'PENDING',
          vehicleVerificationStatus: 'PENDING',
          documentsSubmittedAt: now,
          drivingLicenseImageUrl: _account.drivingLicenseImageUrl,
          vehicleDocumentImageUrl: _account.vehicleDocumentImageUrl,
          createdAt: now,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void _startFirestoreRequestListener() {
    _requestSubscription?.cancel();
    final fb = CaptainFirebaseService();
    if (!fb.isFirebaseAvailable) return;

    _requestSubscription =
        fb.streamAssignedRequests(_account.id).listen((rides) {
      if (rides.isNotEmpty && _rideState == CaptainRideState.idle && isOnline) {
        final ride = rides.first;
        _currentRequest = RideRequestItem(
          id: ride.rideId,
          passengerId: ride.userId,
          passengerName: ride.userName,
          passengerPhone: '+91 98450 77123',
          passengerRating: 4.85,
          pickupAddress: ride.pickup,
          pickupLatitude: ride.pickupLocation['lat'] ?? 12.9785,
          pickupLongitude: ride.pickupLocation['lng'] ?? 77.6405,
          dropAddress: ride.destination,
          dropLatitude: ride.destinationLocation['lat'] ?? 12.9772,
          dropLongitude: ride.destinationLocation['lng'] ?? 77.5695,
          distanceKm: ride.distance,
          estimatedMinutes: ride.estimatedTime,
          vehicleType: ride.vehicleType,
          estimatedFare: ride.fare,
          paymentMode: 'Cash / UPI',
        );
        _requestSecondsRemaining = 30;
        _rideState = CaptainRideState.requestReceived;
        if (CaptainPushNotificationService().shouldProcessRideEvent(ride.rideId, 'NEW_RIDE_REQUEST')) {
          CaptainPushNotificationService().showLocalNotification(
            title: 'New Ride Request',
            body: '${ride.vehicleType} • ₹${ride.fare.toStringAsFixed(0)} • ${ride.pickup} to ${ride.destination}',
            payload: '${ride.rideId}|NEW_RIDE_REQUEST',
          );
        }
        notifyListeners();
      }
    });
  }

  /// App Restart Recovery: check if an active ride exists in Firestore and restore state
  Future<void> recoverActiveRide() async {
    final fb = CaptainFirebaseService();
    if (!fb.isFirebaseAvailable) return;

    final active = await fb.fetchActiveRideForCaptain(_account.id);
    if (active != null) {
      _currentRequest = RideRequestItem(
        id: active.rideId,
        passengerId: active.userId,
        passengerName: active.userName,
        passengerPhone: '+91 98450 77123',
        passengerRating: 4.85,
        pickupAddress: active.pickup,
        pickupLatitude: active.pickupLocation['lat'] ?? 12.9785,
        pickupLongitude: active.pickupLocation['lng'] ?? 77.6405,
        dropAddress: active.destination,
        dropLatitude: active.destinationLocation['lat'] ?? 12.9772,
        dropLongitude: active.destinationLocation['lng'] ?? 77.5695,
        distanceKm: active.distance,
        estimatedMinutes: active.estimatedTime,
        vehicleType: active.vehicleType,
        estimatedFare: active.fare,
        paymentMode: 'Cash / UPI',
      );

      switch (active.status) {
        case SharedRideStatus.accepted:
          _rideState = CaptainRideState.accepted;
          break;
        case SharedRideStatus.arrived:
          _rideState = CaptainRideState.arrivedAtPickup;
          break;
        case SharedRideStatus.inProgress:
          _rideState = CaptainRideState.rideInProgress;
          break;
        default:
          _rideState = CaptainRideState.accepted;
      }

      _startActiveGpsTracking();
      _startActiveRideSync(active.rideId);
      notifyListeners();
    }
  }

  void _startActiveRideSync(String rideId) {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = CaptainFirebaseService().streamRide(rideId).listen((remoteRide) {
      if (remoteRide == null) return;

      if (remoteRide.status == SharedRideStatus.cancelled && hasActiveAcceptedRide) {
        _stopActiveGpsTracking();
        _stopActiveRideSync();
        _currentRequest = null;
        _rideState = CaptainRideState.idle;
        _rideDurationSeconds = 0;
        final reasonStr = (remoteRide.cancellationReason != null && remoteRide.cancellationReason!.isNotEmpty)
            ? ' (Reason: ${remoteRide.cancellationReason})'
            : '';
        _lastCancellationNotice = remoteRide.cancelledBy == 'user'
            ? 'The passenger has cancelled this ride.$reasonStr'
            : 'This ride has been cancelled.$reasonStr';
        if (CaptainPushNotificationService().shouldProcessRideEvent(remoteRide.rideId, 'RIDE_CANCELLED')) {
          CaptainPushNotificationService().showLocalNotification(
            title: 'Ride Cancelled',
            body: _lastCancellationNotice!,
            payload: '${remoteRide.rideId}|RIDE_CANCELLED',
          );
        }
        notifyListeners();
      }
    });
  }

  void _stopActiveRideSync() {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = null;
  }

  void _startActiveGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription =
        LocationService.getPositionStream(distanceFilter: 10).listen(
      (pos) {
        if (hasActiveAcceptedRide && _currentRequest != null) {
          CaptainFirebaseService().updateCaptainLocation(
            _account.id,
            pos.latitude,
            pos.longitude,
            rideId: _currentRequest!.id,
          );
        }
      },
      onError: (err) {
        debugPrint('[QuickRide Captain] Live GPS stream note: $err');
      },
    );
  }

  void _stopActiveGpsTracking() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  /// Load captain profile from Firestore and sync with active account state
  Future<void> loadCaptainProfile() async {
    final session = await CaptainAuthService().getActiveSession();
    if (session != null) {
      _account = session;
    }

    final fb = CaptainFirebaseService();
    if (fb.isFirebaseAvailable && _account.id.isNotEmpty) {
      final remoteDoc = await fb.fetchCaptainProfile(_account.id);
      if (remoteDoc != null) {
        _account = _account.copyWith(
          name: remoteDoc.name.isNotEmpty ? remoteDoc.name : _account.name,
          phone: remoteDoc.phone.isNotEmpty ? remoteDoc.phone : _account.phone,
          email: remoteDoc.email.isNotEmpty ? remoteDoc.email : _account.email,
          vehicleNumber: remoteDoc.vehicleNumber.isNotEmpty ? remoteDoc.vehicleNumber : _account.vehicleNumber,
          vehicleType: remoteDoc.vehicleType.isNotEmpty ? remoteDoc.vehicleType : _account.vehicleType,
          licenseNumber: remoteDoc.drivingLicenseNumber.isNotEmpty ? remoteDoc.drivingLicenseNumber : _account.licenseNumber,
          rating: remoteDoc.rating,
          isOnline: remoteDoc.online,
          profileImageUrl: remoteDoc.profileImage ?? _account.profileImageUrl,
          vehicleImageUrl: remoteDoc.vehicleImage ?? _account.vehicleImageUrl,
          verificationStatus: remoteDoc.verificationStatus,
          vehicleVerificationStatus: remoteDoc.vehicleVerificationStatus,
          documentsSubmittedAt: remoteDoc.documentsSubmittedAt,
          verifiedAt: remoteDoc.verifiedAt,
          rejectionReason: remoteDoc.rejectionReason,
          drivingLicenseImageUrl: remoteDoc.drivingLicenseImageUrl ?? _account.drivingLicenseImageUrl,
          vehicleDocumentImageUrl: remoteDoc.vehicleDocumentImageUrl ?? _account.vehicleDocumentImageUrl,
        );
        await CaptainAuthService().updateActiveCaptain(_account);
        notifyListeners();
      }
    }
  }

  void updateProfile({
    String? name,
    String? phone,
    String? email,
    String? vehicleNumber,
    String? vehicleType,
    String? licenseNumber,
    String? profileImageUrl,
    String? vehicleImageUrl,
  }) {
    _account = _account.copyWith(
      name: name,
      phone: phone,
      email: email,
      vehicleNumber: vehicleNumber,
      vehicleType: vehicleType,
      licenseNumber: licenseNumber,
      profileImageUrl: profileImageUrl,
      vehicleImageUrl: vehicleImageUrl,
    );
    CaptainAuthService().updateActiveCaptain(_account);

    final fb = CaptainFirebaseService();
    if (fb.isFirebaseAvailable) {
      fb.syncCaptainProfile(
        FirestoreCaptainModel(
          captainId: _account.id,
          name: _account.name,
          phone: _account.phone,
          email: _account.email,
          vehicleNumber: _account.vehicleNumber,
          vehicleType: _account.vehicleType,
          drivingLicenseNumber: _account.licenseNumber,
          rating: _account.rating,
          online: _account.isOnline,
          profileImage: _account.profileImageUrl,
          vehicleImage: _account.vehicleImageUrl,
          verificationStatus: _account.verificationStatus,
          vehicleVerificationStatus: _account.vehicleVerificationStatus,
          documentsSubmittedAt: _account.documentsSubmittedAt,
          verifiedAt: _account.verifiedAt,
          rejectionReason: _account.rejectionReason,
          drivingLicenseImageUrl: _account.drivingLicenseImageUrl,
          vehicleDocumentImageUrl: _account.vehicleDocumentImageUrl,
          createdAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  /// Generate or trigger a mock ride request (allowed only when ONLINE and IDLE)
  bool triggerTestRideRequest() {
    if (!isOnline || hasActiveAcceptedRide) {
      return false;
    }

    _currentRequest = _mockRequestPool[_poolIndex % _mockRequestPool.length];
    _poolIndex++;
    _requestSecondsRemaining = 30;
    _rideState = CaptainRideState.requestReceived;
    notifyListeners();
    return true;
  }

  /// Decrement timer every second while request is received
  void tickTimer() {
    if (_rideState != CaptainRideState.requestReceived || _currentRequest == null) return;

    if (_requestSecondsRemaining > 1) {
      _requestSecondsRemaining--;
      notifyListeners();
    } else {
      expireRequest();
    }
  }

  /// Expire request when countdown hits 0
  void expireRequest() {
    if (_rideState == CaptainRideState.requestReceived) {
      _currentRequest = null;
      _requestSecondsRemaining = 0;
      _rideState = CaptainRideState.idle;
      notifyListeners();
    }
  }

  /// Reject current incoming request
  void rejectCurrentRequest() {
    if (_rideState == CaptainRideState.requestReceived) {
      final reqId = _currentRequest?.id;
      if (reqId != null) {
        CaptainFirebaseService().rejectRide(reqId, _account.id);
      }
      _currentRequest = null;
      _requestSecondsRemaining = 0;
      _rideState = CaptainRideState.idle;
      notifyListeners();
    }
  }

  /// Accept incoming ride request (Transitions to ACCEPTED)
  bool acceptCurrentRequest() {
    if (_rideState == CaptainRideState.requestReceived && _currentRequest != null) {
      final reqId = _currentRequest!.id;
      _rideState = CaptainRideState.accepted;
      _requestSecondsRemaining = 0; // stop countdown
      _startActiveGpsTracking();
      _startActiveRideSync(reqId);
      CaptainFirebaseService().acceptRide(
        reqId,
        captainId: _account.id,
        userId: _currentRequest?.passengerName,
      );
      notifyListeners();
      return true;
    }
    return false; // prevent duplicate acceptance
  }

  /// Navigate to pickup (Transitions to NAVIGATING_TO_PICKUP)
  void startNavigationToPickup() {
    if (_rideState == CaptainRideState.accepted) {
      _rideState = CaptainRideState.navigatingToPickup;
      notifyListeners();
    }
  }

  /// Arrived at pickup (Transitions to ARRIVED_AT_PICKUP)
  /// Guard: Allowed from navigatingToPickup or directly from accepted
  bool arriveAtPickup() {
    if ((_rideState == CaptainRideState.navigatingToPickup ||
         _rideState == CaptainRideState.accepted) &&
        _currentRequest != null) {
      _rideState = CaptainRideState.arrivedAtPickup;
      CaptainFirebaseService().updateRideStatus(
        _currentRequest!.id,
        SharedRideStatus.arrived,
        captainId: _account.id,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Start Ride (Transitions to RIDE_IN_PROGRESS)
  /// Guard: Allowed ONLY from arrivedAtPickup
  bool startRide() {
    if (_rideState == CaptainRideState.arrivedAtPickup && _currentRequest != null) {
      _rideState = CaptainRideState.rideInProgress;
      _rideDurationSeconds = 0;
      CaptainFirebaseService().updateRideStatus(
        _currentRequest!.id,
        SharedRideStatus.inProgress,
        captainId: _account.id,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Increment ride progress timer by 1 second
  void tickRideTimer() {
    if (_rideState == CaptainRideState.rideInProgress) {
      _rideDurationSeconds++;
      notifyListeners();
    }
  }

  /// Complete Ride (Transitions to COMPLETED)
  /// Guard: Allowed ONLY from rideInProgress
  Future<bool> completeRide() async {
    if (_rideState == CaptainRideState.rideInProgress && _currentRequest != null) {
      final reqId = _currentRequest!.id;
      _stopActiveGpsTracking();
      _stopActiveRideSync();

      final duration = _rideDurationSeconds > 0
          ? _rideDurationSeconds
          : (_currentRequest!.estimatedMinutes * 60);

      final record = CompletedRideRecord(
        id: reqId,
        rideId: reqId,
        userId: _currentRequest!.passengerId,
        passengerName: _currentRequest!.passengerName,
        passengerPhone: _currentRequest!.passengerPhone,
        pickupAddress: _currentRequest!.pickupAddress,
        dropAddress: _currentRequest!.dropAddress,
        vehicleType: _currentRequest!.vehicleType,
        fare: _currentRequest!.estimatedFare,
        distanceKm: _currentRequest!.distanceKm,
        durationSeconds: duration,
        completionTime: DateTime.now(),
      );

      _lastCompletedRide = record;
      _rideState = CaptainRideState.completed;

      // Update Captain cumulative stats
      _account = _account.copyWith(
        todayEarnings: _account.todayEarnings + record.fare,
        totalRides: _account.totalRides + 1,
      );
      await CaptainAuthService().updateActiveCaptain(_account);
      await _saveCompletedRide(record);
      await CaptainFirebaseService().updateRideStatus(
        reqId,
        SharedRideStatus.completed,
        captainId: _account.id,
      );

      notifyListeners();
      return true;
    }
    return false;
  }

  /// Rate passenger for a completed ride
  Future<bool> ratePassenger(String rideId, int stars, {String review = ''}) async {
    if (stars < 1 || stars > 5) return false;

    final CompletedRideRecord target = (_lastCompletedRide != null &&
            (_lastCompletedRide!.id == rideId || _lastCompletedRide!.rideId == rideId))
        ? _lastCompletedRide!
        : _completedRides.firstWhere(
            (r) => r.id == rideId || r.rideId == rideId,
            orElse: () => _lastCompletedRide ?? CompletedRideRecord(
              id: rideId,
              rideId: rideId,
              passengerName: 'Passenger',
              passengerPhone: '',
              pickupAddress: '',
              dropAddress: '',
              vehicleType: 'QuickRide Bike',
              fare: 0,
              distanceKm: 0,
              durationSeconds: 0,
              completionTime: DateTime.now(),
            ),
          );

    final passengerId = target.userId ?? 'user_quickride_01';

    // Submit to Firestore
    final success = await CaptainFirebaseService().submitRating(
      FirestoreRatingModel(
        ratingId: '${rideId}_captain',
        rideId: rideId,
        userId: passengerId,
        captainId: _account.id,
        ratedBy: 'captain',
        stars: stars,
        rating: stars.toDouble(),
        review: review,
        createdAt: DateTime.now(),
      ),
    );

    // Update local record
    final updated = target.copyWith(
      isRated: true,
      rating: stars,
      reviewText: review,
    );

    if (_lastCompletedRide != null && (_lastCompletedRide!.id == rideId || _lastCompletedRide!.rideId == rideId)) {
      _lastCompletedRide = updated;
    }

    final index = _completedRides.indexWhere((r) => r.id == rideId || r.rideId == rideId);
    if (index != -1) {
      _completedRides[index] = updated;
    }
    await _persistAllCompletedRides();

    notifyListeners();
    return success;
  }

  /// Return back to Home after completion
  void finishCompletedRideAndReturnHome() {
    _stopActiveGpsTracking();
    _stopActiveRideSync();
    _currentRequest = null;
    _rideState = CaptainRideState.idle;
    _rideDurationSeconds = 0;
    notifyListeners();
  }

  /// Load completed rides from SharedPreferences
  Future<void> loadCompletedRides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_completedRidesKey) ?? [];
      _completedRides = listJson.map((e) => CompletedRideRecord.fromJson(e)).toList();
      _completedRides.sort((a, b) => b.completionTime.compareTo(a.completionTime));
      notifyListeners();
    } catch (_) {}
  }

  /// Save completed ride locally to SharedPreferences
  Future<void> _saveCompletedRide(CompletedRideRecord record) async {
    try {
      _completedRides.insert(0, record);
      _completedRides.sort((a, b) => b.completionTime.compareTo(a.completionTime));
      await _persistAllCompletedRides();
    } catch (_) {}
  }

  /// Persist all completed rides to SharedPreferences
  Future<void> _persistAllCompletedRides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _completedRides.map((e) => e.toJson()).toList();
      await prefs.setStringList(_completedRidesKey, listJson);
    } catch (_) {}
  }

  /// Seed sample completed rides for development/testing when history is empty (Requirement 14)
  Future<void> seedDemoCompletedRides() async {
    final now = DateTime.now();
    final demoRides = [
      CompletedRideRecord(
        id: 'DEMO-101',
        passengerName: 'Rahul (DEMO)',
        passengerPhone: '+91 98450 77123',
        pickupAddress: 'Main Road, 100 Feet Corner, Indiranagar',
        dropAddress: 'Railway Station, City Center Platform 1',
        vehicleType: 'QuickRide Bike',
        fare: 75.0,
        distanceKm: 4.2,
        durationSeconds: 720,
        completionTime: now.subtract(const Duration(hours: 2)),
      ),
      CompletedRideRecord(
        id: 'DEMO-102',
        passengerName: 'Pooja (DEMO)',
        passengerPhone: '+91 99801 22334',
        pickupAddress: 'Koramangala 4th Block, 80 Feet Road',
        dropAddress: 'MG Road Metro Station, Gate 3',
        vehicleType: 'QuickRide Bike',
        fare: 95.0,
        distanceKm: 5.8,
        durationSeconds: 960,
        completionTime: now.subtract(const Duration(hours: 5)),
      ),
      CompletedRideRecord(
        id: 'DEMO-103',
        passengerName: 'Amit (DEMO)',
        passengerPhone: '+91 98111 55443',
        pickupAddress: 'HSR Layout Sector 2, 27th Main',
        dropAddress: 'Bellandur EcoSpace Tech Park',
        vehicleType: 'QuickRide Bike',
        fare: 110.0,
        distanceKm: 6.5,
        durationSeconds: 1100,
        completionTime: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];

    _completedRides.insertAll(0, demoRides);
    _completedRides.sort((a, b) => b.completionTime.compareTo(a.completionTime));
    final prefs = await SharedPreferences.getInstance();
    final listJson = _completedRides.map((e) => e.toJson()).toList();
    await prefs.setStringList(_completedRidesKey, listJson);
    notifyListeners();
  }

  /// Clear completed rides (for testing / data reset)
  Future<void> clearCompletedRides() async {
    _completedRides.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedRidesKey);
    notifyListeners();
  }

  /// Cancel accepted ride (Returns to IDLE, keeping Captain Online)
  void cancelAcceptedRide({String? cancellationReason, String? cancellationDescription}) {
    final reqId = _currentRequest?.id;
    _stopActiveGpsTracking();
    _stopActiveRideSync();
    if (reqId != null) {
      CaptainFirebaseService().updateRideStatus(
        reqId,
        SharedRideStatus.cancelled,
        captainId: _account.id,
        cancelledBy: 'captain',
        cancellationReason: cancellationReason,
        cancellationDescription: cancellationDescription,
      );
    }
    _currentRequest = null;
    _rideState = CaptainRideState.idle;
    _rideDurationSeconds = 0;
    notifyListeners();
  }

  // ===========================================================================
  // STEP 39: CAPTAIN CUSTOMER SUPPORT & COMPLAINTS MANAGEMENT
  // ===========================================================================

  List<FirestoreComplaintModel> _complaints = [];
  StreamSubscription<List<FirestoreComplaintModel>>? _complaintSubscription;

  List<FirestoreComplaintModel> get complaints => List.unmodifiable(_complaints);

  void initComplaintsListener() {
    _complaintSubscription?.cancel();
    _complaintSubscription = CaptainFirebaseService()
        .streamCaptainComplaints(_account.id)
        .listen((list) {
      _complaints = list;
      notifyListeners();
    });
  }

  Future<FirestoreComplaintModel> createComplaint({
    required String category,
    required String subject,
    required String description,
    String? rideId,
    String priority = 'NORMAL',
    String? attachmentUrl,
  }) async {
    final now = DateTime.now();
    final complaintId = 'CPT-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final complaint = FirestoreComplaintModel(
      complaintId: complaintId,
      captainId: _account.id,
      complainantRole: 'CAPTAIN',
      complainantName: _account.name,
      complainantPhone: _account.phone,
      category: category,
      subject: subject,
      description: description,
      rideId: rideId,
      attachmentUrl: attachmentUrl,
      priority: priority,
      status: 'OPEN',
      createdAt: now,
      updatedAt: now,
    );

    await CaptainFirebaseService().createComplaint(complaint);

    final exists = _complaints.any((c) => c.complaintId == complaintId);
    if (!exists) {
      _complaints.insert(0, complaint);
      notifyListeners();
    }

    return complaint;
  }

  Future<bool> sendComplaintReply({
    required String complaintId,
    required String message,
  }) async {
    final now = DateTime.now();
    final replyId = 'rep_${now.millisecondsSinceEpoch}';

    final reply = FirestoreComplaintReplyModel(
      replyId: replyId,
      complaintId: complaintId,
      senderId: _account.id,
      senderName: _account.name,
      senderRole: 'CAPTAIN',
      message: message.trim(),
      createdAt: now,
    );

    return await CaptainFirebaseService().addComplaintReply(reply);
  }

  Stream<List<FirestoreComplaintReplyModel>> streamComplaintReplies(String complaintId) {
    return CaptainFirebaseService().streamComplaintReplies(complaintId);
  }

  // ==========================================================================
  // STEP 40: CAPTAIN EMERGENCY SOS & TELEMETRY
  // ==========================================================================

  void recoverActiveEmergency() {
    _emergencySub?.cancel();
    _emergencySub = CaptainFirebaseService().streamActiveEmergency(_account.id).listen((emergency) {
      _activeEmergency = emergency;
      notifyListeners();
    });
  }

  Future<bool> triggerSOS({String? reason}) async {
    final rideId = _currentRequest?.id ?? 'RIDE_CPT_${DateTime.now().millisecondsSinceEpoch}';
    double lat = _currentRequest?.pickupLatitude ?? 12.9716;
    double lng = _currentRequest?.pickupLongitude ?? 77.5946;

    try {
      final locResult = await LocationService.getCurrentLocation();
      if (locResult.position != null) {
        lat = locResult.position!.latitude;
        lng = locResult.position!.longitude;
      }
    } catch (_) {}

    final incident = FirestoreEmergencyIncidentModel(
      emergencyId: 'EMG_${rideId}_${DateTime.now().millisecondsSinceEpoch}',
      rideId: rideId,
      userId: _currentRequest?.passengerPhone ?? 'rider_contact',
      captainId: _account.id,
      latitude: lat,
      longitude: lng,
      status: EmergencyStatus.active,
      triggeredBy: 'captain',
      userName: _currentRequest?.passengerName ?? 'Rider',
      userPhone: _currentRequest?.passengerPhone ?? '',
      captainName: _account.name,
      captainPhone: _account.phone,
      vehicleNumber: _account.vehicleNumber,
      vehicleType: _account.vehicleType,
      pickup: _currentRequest?.pickupAddress ?? 'Pickup Point',
      destination: _currentRequest?.dropAddress ?? 'Destination',
      adminNotes: reason ?? 'Emergency SOS triggered by Captain via QuickRide Partner App',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await CaptainFirebaseService().createEmergencyIncident(incident);
    if (success) {
      _activeEmergency = incident;
      recoverActiveEmergency();
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateEmergencyLocation(double latitude, double longitude) async {
    if (_activeEmergency == null || !_activeEmergency!.isActive) return false;
    _activeEmergency = _activeEmergency!.copyWith(
      latitude: latitude,
      longitude: longitude,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return CaptainFirebaseService().updateEmergencyLocation(
      _activeEmergency!.emergencyId,
      latitude,
      longitude,
    );
  }

  void clearActiveEmergency() {
    _emergencySub?.cancel();
    _emergencySub = null;
    _activeEmergency = null;
    notifyListeners();
  }

  /// Clean up all active subscriptions and GPS tracking
  void stopAllSubscriptions() {
    _stopActiveGpsTracking();
    _stopActiveRideSync();
    _requestSubscription?.cancel();
    _requestSubscription = null;
    _complaintSubscription?.cancel();
    _complaintSubscription = null;
    _emergencySub?.cancel();
    _emergencySub = null;
  }
}
