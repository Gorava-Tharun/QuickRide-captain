import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Global Reactive Connectivity Service for QuickRide Captain App.
///
/// Monitors network status, dispatches connectivity change events,
/// handles automatic reconnection synchronization, and supports
/// testable mock offline simulation.
class CaptainConnectivityService {
  static final CaptainConnectivityService _instance =
      CaptainConnectivityService._internal();
  factory CaptainConnectivityService() => _instance;
  CaptainConnectivityService._internal();

  bool _isOnline = true;
  bool _isMocked = false;
  Timer? _checkTimer;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final List<Future<void> Function()> _reconnectionListeners = [];

  /// Current network status
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  /// Broadcast stream of connectivity changes (emits true when online, false when offline)
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Register a listener to execute when internet connection is restored
  void addReconnectionListener(Future<void> Function() listener) {
    if (!_reconnectionListeners.contains(listener)) {
      _reconnectionListeners.add(listener);
    }
  }

  /// Unregister a reconnection listener
  void removeReconnectionListener(Future<void> Function() listener) {
    _reconnectionListeners.remove(listener);
  }

  /// Explicitly set network status (used for offline testing & simulation)
  void setMockOnlineState(bool online) {
    _isMocked = true;
    _updateOnlineState(online);
  }

  /// Reset mock state to automatic network detection
  void resetMockState() {
    _isMocked = false;
    checkConnectivity();
  }

  /// Start periodic background connectivity monitoring
  void startMonitoring({Duration interval = const Duration(seconds: 15)}) {
    _checkTimer?.cancel();
    checkConnectivity();
    _checkTimer = Timer.periodic(interval, (_) => checkConnectivity());
  }

  /// Stop background monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Actively verify network reachability
  Future<bool> checkConnectivity() async {
    if (_isMocked) return _isOnline;

    try {
      if (kIsWeb) {
        _updateOnlineState(true);
        return true;
      }

      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateOnlineState(hasConnection);
      return hasConnection;
    } catch (_) {
      _updateOnlineState(false);
      return false;
    }
  }

  void _updateOnlineState(bool newStatus) {
    if (_isOnline == newStatus) return;

    final wasOffline = !_isOnline;
    _isOnline = newStatus;
    _connectivityController.add(_isOnline);

    debugPrint('[CaptainConnectivityService] Network status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');

    // Trigger reconnection handlers when internet returns
    if (wasOffline && _isOnline) {
      _notifyReconnectionListeners();
    }
  }

  Future<void> _notifyReconnectionListeners() async {
    debugPrint('[CaptainConnectivityService] Internet restored. Executing ${_reconnectionListeners.length} sync listeners...');
    for (final listener in List.of(_reconnectionListeners)) {
      try {
        await listener();
      } catch (e) {
        debugPrint('[CaptainConnectivityService] Error in reconnection listener: $e');
      }
    }
  }

  void dispose() {
    _checkTimer?.cancel();
    _connectivityController.close();
    _reconnectionListeners.clear();
  }
}
