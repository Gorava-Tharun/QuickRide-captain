import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'captain_firebase_service.dart';

/// Top-level background message handler for Captain FCM
@pragma('vm:entry-point')
Future<void> captainFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
  debugPrint('[Captain FCM Background] Message received: ${message.messageId}, data: ${message.data}');
}

class CaptainPushNotificationService {
  static final CaptainPushNotificationService _instance =
      CaptainPushNotificationService._internal();
  factory CaptainPushNotificationService() => _instance;
  CaptainPushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Set<String> _processedEventKeys = {};

  bool _isInitialized = false;
  String? _fcmToken;
  String? _currentCaptainId;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;

  Function(String rideId, String type, [Map<String, dynamic>? data])? onNotificationTap;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Android high-importance notification channel for Captains
  static const AndroidNotificationChannel _captainChannel =
      AndroidNotificationChannel(
    'quickride_captain_rides',
    'QuickRide Captain Alerts',
    description: 'Alerts for incoming ride requests, cancellations, and status updates.',
    importance: Importance.high,
  );

  /// Initialize Firebase Messaging & Local Notifications safely
  Future<bool> initialize({
    String? captainId,
    Function(String rideId, String type, [Map<String, dynamic>? data])? onNotificationTap,
  }) async {
    if (onNotificationTap != null) {
      this.onNotificationTap = onNotificationTap;
    }
    if (captainId != null && captainId.isNotEmpty) {
      _currentCaptainId = captainId;
    }

    if (_isInitialized) {
      if (captainId != null && captainId.isNotEmpty && _fcmToken != null) {
        await CaptainFirebaseService().updateCaptainFcmToken(captainId, _fcmToken);
      }
      return true;
    }

    try {
      // 1. Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            final parts = payload.split('|');
            final rideId = parts.isNotEmpty ? parts[0] : '';
            final type = parts.length > 1 ? parts[1] : '';
            if (this.onNotificationTap != null) {
              this.onNotificationTap!(rideId, type, {'rideId': rideId, 'type': type});
            }
          }
        },
      );

      // Create Android channel
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(_captainChannel);
      }

      // Check if Firebase is available
      if (Firebase.apps.isEmpty) {
        debugPrint('[CaptainPushNotificationService] Firebase not initialized, skipping remote FCM.');
        _isInitialized = true;
        return false;
      }

      // 2. Request Notification Permissions politely
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: true,
        sound: true,
      );

      debugPrint('[CaptainPushNotificationService] Permission status: ${settings.authorizationStatus}');

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(captainFirebaseMessagingBackgroundHandler);

      // 3. Retrieve FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[CaptainPushNotificationService] Retrieved FCM token: ${_fcmToken != null ? "YES (masked)" : "NONE"}');
        if (_currentCaptainId != null && _currentCaptainId!.isNotEmpty && _fcmToken != null) {
          await CaptainFirebaseService().updateCaptainFcmToken(_currentCaptainId!, _fcmToken);
        }
      } catch (e) {
        debugPrint('[CaptainPushNotificationService] Error retrieving token (offline/fallback): $e');
      }

      // 4. Listen for Token Refreshes
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_currentCaptainId != null && _currentCaptainId!.isNotEmpty) {
          CaptainFirebaseService().updateCaptainFcmToken(_currentCaptainId!, newToken);
        }
      });

      // 5. Handle Foreground Messages
      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 6. Handle App Opened from Background Notification Tap
      _onMessageOpenedAppSub?.cancel();
      _onMessageOpenedAppSub =
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      // 7. Check if App was Launched from a Terminated Notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('[CaptainPushNotificationService] Initialization error (using local fallback): $e');
      _isInitialized = true;
      return false;
    }
  }

  /// Register or update captain ID on login
  Future<void> registerCaptain(String captainId) async {
    _currentCaptainId = captainId;
    if (_fcmToken != null) {
      await CaptainFirebaseService().updateCaptainFcmToken(captainId, _fcmToken);
    }
  }

  /// Clear token on logout
  Future<void> clearCaptain() async {
    if (_currentCaptainId != null && _currentCaptainId!.isNotEmpty) {
      await CaptainFirebaseService().updateCaptainFcmToken(_currentCaptainId!, null);
    }
    _currentCaptainId = null;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    _fcmToken = null;
  }

  /// Deduplication guard: returns true if event should be processed, false if duplicate
  bool shouldProcessRideEvent(String rideId, String status) {
    final key = '${rideId}_$status';
    if (_processedEventKeys.contains(key)) {
      return false;
    }
    _processedEventKeys.add(key);
    if (_processedEventKeys.length > 200) {
      _processedEventKeys.remove(_processedEventKeys.first);
    }
    return true;
  }

  /// Handle incoming foreground push message
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? 'QuickRide Captain';
    final body = notification?.body ?? data['message'] ?? '';
    final rideId = data['rideId'] ?? '';
    final typeStr = data['type'] ?? '';

    // Check deduplication
    if (rideId.isNotEmpty && typeStr.isNotEmpty) {
      if (!shouldProcessRideEvent(rideId, typeStr)) {
        return;
      }
    }

    // Show local notification banner
    showLocalNotification(
      title: title,
      body: body,
      payload: '$rideId|$typeStr',
    );
  }

  /// Show a foreground heads-up banner notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'quickride_captain_rides',
        'QuickRide Captain Alerts',
        channelDescription: 'Alerts for incoming ride requests, cancellations, and status updates.',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('[CaptainPushNotificationService] Local notification show error: $e');
    }
  }

  /// Deep linking route based on tapped notification data payload
  void _handleNotificationTap(Map<String, dynamic> data) {
    final rideId = data['rideId'] as String? ?? data['complaintId'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    if (onNotificationTap != null) {
      onNotificationTap!(rideId, type, data);
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedAppSub?.cancel();
  }
}
