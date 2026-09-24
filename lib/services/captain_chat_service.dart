import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/firestore_models.dart';
import 'captain_firebase_service.dart';

/// Captain-side real-time chat service for communicating with riders on active trips.
class CaptainChatService extends ChangeNotifier {
  CaptainChatService._internal();

  static final CaptainChatService _instance = CaptainChatService._internal();
  factory CaptainChatService() => _instance;

  /// Validates if chat is available for the given ride status
  static bool isChatEnabledForStatus(String? status) {
    if (status == null) return false;
    final s = status.toUpperCase().replaceAll(' ', '_');
    return s == 'ACCEPTED' || s == 'ARRIVED' || s == 'IN_PROGRESS';
  }

  /// Check if ride is in terminal state
  static bool isTerminalStatus(String? status) {
    if (status == null) return false;
    final s = status.toUpperCase().replaceAll(' ', '_');
    return s == 'COMPLETED' || s == 'CANCELLED';
  }

  /// Streams real-time chat messages for a ride
  Stream<List<FirestoreChatMessageModel>> streamMessages(String rideId) {
    return CaptainFirebaseService().streamChatMessages(rideId);
  }

  /// Fetches one-time message list
  Future<List<FirestoreChatMessageModel>> fetchMessages(String rideId) {
    return CaptainFirebaseService().fetchChatMessages(rideId);
  }

  /// Sends a message from the Captain
  Future<bool> sendMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String message,
    String senderRole = 'CAPTAIN',
    String? rideStatus,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      debugPrint('[CaptainChatService] Cannot send empty message');
      return false;
    }

    if (trimmed.length > 500) {
      debugPrint('[CaptainChatService] Message exceeds 500 character limit');
      return false;
    }

    if (rideStatus != null && isTerminalStatus(rideStatus)) {
      debugPrint('[CaptainChatService] Chat is closed for status $rideStatus');
      return false;
    }

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode.abs().toString().padLeft(4, '0')}';
    final chatMessage = FirestoreChatMessageModel(
      messageId: messageId,
      rideId: rideId,
      senderId: senderId,
      senderRole: senderRole.toUpperCase(),
      senderName: senderName,
      message: trimmed,
      createdAt: DateTime.now(),
      read: false,
    );

    final success = await CaptainFirebaseService().sendChatMessage(chatMessage);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  /// Marks a specific message as read
  Future<bool> markAsRead(String rideId, String messageId) async {
    return CaptainFirebaseService().markChatMessageAsRead(rideId, messageId);
  }

  /// Marks all unread messages from opposite party as read
  Future<void> markAllReceivedAsRead({
    required String rideId,
    required String currentCaptainId,
    required List<FirestoreChatMessageModel> messages,
  }) async {
    for (final msg in messages) {
      if (!msg.read && msg.senderId != currentCaptainId) {
        await markAsRead(rideId, msg.messageId);
      }
    }
  }

  /// Clears local messages (for hermetic unit testing)
  void reset([String? rideId]) {
    CaptainFirebaseService().clearLocalChatMessages(rideId);
    notifyListeners();
  }
}
