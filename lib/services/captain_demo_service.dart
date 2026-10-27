import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/captain_models.dart';

/// Centralized service managing Demo Captain mode, simulated ride lifecycle,
/// demo earnings, and demo ride history in QuickRide Captain App.
///
/// Keeps all simulated demo records strictly separated from production Firestore collections,
/// production earnings, and production completed rides.
class CaptainDemoService extends ChangeNotifier {
  static final CaptainDemoService _instance = CaptainDemoService._internal();
  factory CaptainDemoService() => _instance;
  CaptainDemoService._internal() {
    loadState();
  }

  static const String demoModeKey = 'quickride_captain_demo_mode';
  static const String demoCompletedRidesKey = 'quickride_captain_demo_completed_rides';
  static const String demoBusKey = 'quickride_demo_bus';
  static const String demoActiveBookingKey = 'quickride_demo_active_booking';

  bool _isDemoMode = true; // Default to true for academic viva & presentation demonstration
  bool get isDemoMode => _isDemoMode;

  String _demoRideLifecycleStatus = 'IDLE'; // IDLE, REQUESTED, ACCEPTED, NAVIGATING_TO_PICKUP, ARRIVED_AT_PICKUP, RIDE_IN_PROGRESS, COMPLETED, REJECTED
  String get demoRideLifecycleStatus => _demoRideLifecycleStatus;

  RideRequestItem? _activeDemoRide;
  RideRequestItem? get activeDemoRide => _activeDemoRide;

  List<CompletedRideRecord> _demoCompletedRides = [];
  List<CompletedRideRecord> get demoCompletedRides => List.unmodifiable(_demoCompletedRides);

  // Set of completed demo ride IDs to guarantee idempotent (exactly once) earnings update
  final Set<String> _processedCompletedRideIds = {};

  /// Set Demo Mode on or off and persist
  Future<void> setDemoMode(bool enabled) async {
    _isDemoMode = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(demoModeKey, enabled);
    } catch (_) {}
    notifyListeners();
  }

  /// Toggle Demo Mode
  void toggleDemoMode() {
    setDemoMode(!_isDemoMode);
  }

  /// Load persisted demo mode and completed demo rides
  Future<void> loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDemoMode = prefs.getBool(demoModeKey) ?? true;

      final listJson = prefs.getStringList(demoCompletedRidesKey) ?? [];
      _demoCompletedRides = listJson.map((e) => CompletedRideRecord.fromJson(e)).toList();
      _demoCompletedRides.sort((a, b) => b.completionTime.compareTo(a.completionTime));

      for (final r in _demoCompletedRides) {
        _processedCompletedRideIds.add(r.id);
        if (r.rideId != null) {
          _processedCompletedRideIds.add(r.rideId!);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[CaptainDemoService] Error loading state: $e');
    }
  }

  static int _demoRideCounter = 100;

  /// Generates a realistic sample demo request for independent testing
  RideRequestItem createSampleDemoRequest({
    String? id,
    String? passengerName,
    String? vehicleType,
    double? fare,
    double? distanceKm,
    String? pickupAddress,
    String? dropAddress,
  }) {
    final now = DateTime.now();
    final count = ++_demoRideCounter;
    return RideRequestItem(
      id: id ?? 'DEMO-REQ-$count-${now.millisecondsSinceEpoch}',
      passengerId: 'DEMO-RIDER-01',
      passengerName: passengerName ?? 'Rahul (Demo Rider)',
      passengerPhone: '+91 98450 77123',
      passengerRating: 4.9,
      pickupAddress: pickupAddress ?? 'Dharmavaram RTC Bus Stand, Main Road',
      pickupLatitude: 14.4137,
      pickupLongitude: 77.7126,
      dropAddress: dropAddress ?? 'Dharmavaram Railway Station, Station Road',
      dropLatitude: 14.4230,
      dropLongitude: 77.7280,
      distanceKm: distanceKm ?? 3.5,
      estimatedMinutes: 12,
      vehicleType: vehicleType ?? 'Bike (QuickRide)',
      estimatedFare: fare ?? 55.0,
      paymentMode: 'Cash / UPI',
      isDemo: true,
    );
  }

  /// Checks if User App created an active demo booking, or provides sample request
  Future<RideRequestItem> getDemoRideRequest({String? preferredVehicleType}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingJson = prefs.getString(demoActiveBookingKey);
      if (bookingJson != null && bookingJson.isNotEmpty) {
        final map = json.decode(bookingJson) as Map<String, dynamic>;
        if (map['status'] == 'REQUESTED' || map['status'] == 'searchingForCaptain') {
          return RideRequestItem(
            id: map['rideId'] ?? 'DEMO-REQ-USER',
            passengerId: map['userId'] ?? 'DEMO-USER-01',
            passengerName: map['passengerName'] ?? 'Rahul (Demo Rider)',
            passengerPhone: map['passengerPhone'] ?? '+91 98450 77123',
            passengerRating: 4.9,
            pickupAddress: map['pickupAddress'] ?? 'Dharmavaram RTC Bus Stand, Main Road',
            pickupLatitude: (map['pickupLat'] as num?)?.toDouble() ?? 14.4137,
            pickupLongitude: (map['pickupLng'] as num?)?.toDouble() ?? 77.7126,
            dropAddress: map['dropAddress'] ?? 'Dharmavaram Railway Station, Station Road',
            dropLatitude: (map['dropLat'] as num?)?.toDouble() ?? 14.4230,
            dropLongitude: (map['dropLng'] as num?)?.toDouble() ?? 77.7280,
            distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 3.5,
            estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 12,
            vehicleType: map['vehicleType'] ?? preferredVehicleType ?? 'Bike (QuickRide)',
            estimatedFare: (map['fare'] as num?)?.toDouble() ?? 55.0,
            paymentMode: map['paymentMode'] ?? 'Cash / UPI',
            isDemo: true,
          );
        }
      }
    } catch (_) {}

    return createSampleDemoRequest(vehicleType: preferredVehicleType);
  }

  // --- Cross-App Synchronization Broadcast ---
  Future<void> _broadcastDemoEvent(String status, {Map<String, dynamic>? extra}) async {
    _demoRideLifecycleStatus = status;
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'status': status,
        'rideId': _activeDemoRide?.id,
        'timestamp': DateTime.now().toIso8601String(),
        ...?extra,
      };
      await prefs.setString(demoBusKey, json.encode(payload));
    } catch (_) {}
    notifyListeners();
  }

  // --- Demo Lifecycle Transition Handlers ---

  void onDemoRidePresented(RideRequestItem request) {
    _activeDemoRide = request;
    _demoRideLifecycleStatus = 'REQUESTED';
    _broadcastDemoEvent('REQUESTED');
  }

  void onDemoRideAccepted(RideRequestItem request) {
    _activeDemoRide = request;
    _demoRideLifecycleStatus = 'ACCEPTED';
    _broadcastDemoEvent('ACCEPTED', extra: {
      'captainName': 'Demo Captain (Rajesh Kumar)',
      'vehicleNumber': 'AP 09 CB 1234',
    });
  }

  void onDemoRideRejected(RideRequestItem request) {
    _demoRideLifecycleStatus = 'REJECTED';
    _activeDemoRide = null;
    _broadcastDemoEvent('REJECTED');
  }

  void onDemoRideNavigating() {
    _demoRideLifecycleStatus = 'NAVIGATING_TO_PICKUP';
    _broadcastDemoEvent('NAVIGATING_TO_PICKUP');
  }

  void onDemoRideArrived() {
    _demoRideLifecycleStatus = 'ARRIVED_AT_PICKUP';
    _broadcastDemoEvent('ARRIVED_AT_PICKUP');
  }

  void onDemoRideStarted() {
    _demoRideLifecycleStatus = 'RIDE_IN_PROGRESS';
    _broadcastDemoEvent('RIDE_IN_PROGRESS');
  }

  void onDemoRideCompleted() {
    _demoRideLifecycleStatus = 'COMPLETED';
    _broadcastDemoEvent('COMPLETED');
  }

  void resetDemoRideLifecycle() {
    _demoRideLifecycleStatus = 'IDLE';
    _activeDemoRide = null;
    _broadcastDemoEvent('IDLE');
  }

  // --- Demo Earnings & History (Separated from Real Data) ---

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

  List<CompletedRideRecord> get todayDemoRides {
    final now = DateTime.now();
    return _demoCompletedRides.where((r) => _isSameDay(r.completionTime, now)).toList();
  }

  double get todayDemoEarningsTotal => todayDemoRides.fold(0.0, (sum, r) => sum + r.fare);
  double get todayDemoCaptainEarningsNet => todayDemoRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  double get todayDemoPlatformFeeTotal => todayDemoRides.fold(0.0, (sum, r) => sum + r.platformFee);
  int get todayDemoCompletedRidesCount => todayDemoRides.length;

  List<CompletedRideRecord> get weeklyDemoRides {
    final now = DateTime.now();
    return _demoCompletedRides.where((r) => _isSameWeek(r.completionTime, now)).toList();
  }

  double get weeklyDemoEarningsTotal => weeklyDemoRides.fold(0.0, (sum, r) => sum + r.fare);
  double get weeklyDemoCaptainEarningsNet => weeklyDemoRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  double get weeklyDemoPlatformFeeTotal => weeklyDemoRides.fold(0.0, (sum, r) => sum + r.platformFee);
  int get weeklyDemoCompletedRidesCount => weeklyDemoRides.length;

  List<CompletedRideRecord> get monthlyDemoRides {
    final now = DateTime.now();
    return _demoCompletedRides.where((r) => _isSameMonth(r.completionTime, now)).toList();
  }

  double get monthlyDemoEarningsTotal => monthlyDemoRides.fold(0.0, (sum, r) => sum + r.fare);
  double get monthlyDemoCaptainEarningsNet => monthlyDemoRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  double get monthlyDemoPlatformFeeTotal => monthlyDemoRides.fold(0.0, (sum, r) => sum + r.platformFee);
  int get monthlyDemoCompletedRidesCount => monthlyDemoRides.length;

  double get totalDemoEarnings => _demoCompletedRides.fold(0.0, (sum, r) => sum + r.fare);
  double get totalDemoCaptainEarningsNet => _demoCompletedRides.fold(0.0, (sum, r) => sum + r.captainEarning);
  double get totalDemoPlatformFeeTotal => _demoCompletedRides.fold(0.0, (sum, r) => sum + r.platformFee);
  int get totalDemoCompletedRidesCount => _demoCompletedRides.length;

  double get averageDemoFare {
    if (_demoCompletedRides.isEmpty) return 0.0;
    return totalDemoEarnings / _demoCompletedRides.length;
  }

  /// Records a completed demo ride record idempotently (exactly once)
  Future<bool> recordCompletedDemoRide(CompletedRideRecord record) async {
    final key = (record.rideId != null && record.rideId!.isNotEmpty) ? record.rideId! : record.id;
    if (_processedCompletedRideIds.contains(key)) {
      debugPrint('[CaptainDemoService] Demo ride $key already processed. Duplicate ignored.');
      return false; // Already added
    }

    _processedCompletedRideIds.add(key);
    _processedCompletedRideIds.add(record.id);
    if (record.rideId != null) {
      _processedCompletedRideIds.add(record.rideId!);
    }

    _demoCompletedRides.insert(0, record);
    _demoCompletedRides.sort((a, b) => b.completionTime.compareTo(a.completionTime));

    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = _demoCompletedRides.map((e) => e.toJson()).toList();
      await prefs.setStringList(demoCompletedRidesKey, listJson);
    } catch (e) {
      debugPrint('[CaptainDemoService] Error saving demo completed rides: $e');
    }

    notifyListeners();
    return true;
  }

  /// Clears demo completed rides (for testing / demo data reset)
  Future<void> clearDemoCompletedRides() async {
    _demoCompletedRides.clear();
    _processedCompletedRideIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(demoCompletedRidesKey);
    } catch (_) {}
    notifyListeners();
  }
}
