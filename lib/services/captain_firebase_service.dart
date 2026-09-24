import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firestore_models.dart';

class CaptainFirebaseService {
  static final CaptainFirebaseService _instance =
      CaptainFirebaseService._internal();
  factory CaptainFirebaseService() => _instance;
  CaptainFirebaseService._internal();

  static final List<FirestoreComplaintModel> _localComplaints = [
    FirestoreComplaintModel(
      complaintId: 'CPT-1001',
      captainId: 'captain_seed_01',
      complainantRole: 'CAPTAIN',
      complainantName: 'Vikram Singh',
      complainantPhone: '+91 98765 43210',
      category: 'PAYMENT',
      subject: 'Weekly Incentive Calculation',
      description: 'The peak hour surge bonus for 10 rides completed on Sunday was not reflected in the payout statement.',
      rideId: 'DEMO-101',
      priority: 'NORMAL',
      status: 'RESOLVED',
      adminNotes: 'Verified trip logs. Added incentive adjustment of ₹250.',
      resolutionSummary: 'Bonus has been credited to your wallet balance and will be settled in Monday batch.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final Map<String, List<FirestoreComplaintReplyModel>> _localReplies = {
    'CPT-1001': [
      FirestoreComplaintReplyModel(
        replyId: 'rep_cpt_01',
        complaintId: 'CPT-1001',
        senderId: 'captain_seed_01',
        senderName: 'Vikram Singh',
        senderRole: 'CAPTAIN',
        message: 'Hello, my Sunday incentive of ₹250 for 10 rides is missing from the payout statement.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      FirestoreComplaintReplyModel(
        replyId: 'rep_adm_01',
        complaintId: 'CPT-1001',
        senderId: 'admin_support_01',
        senderName: 'QuickRide Support',
        senderRole: 'ADMIN',
        message: 'Hi Vikram, we have audited your Sunday rides and credited the ₹250 adjustment. It will be settled in Monday batch.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  bool _isFirebaseAvailable = false;
  String _statusMessage = 'Uninitialized';

  bool get isFirebaseAvailable => _isFirebaseAvailable;
  String get statusMessage => _statusMessage;

  /// Safe initialization that catches missing configuration without crashing.
  Future<bool> initialize() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isFirebaseAvailable = true;
        _statusMessage = 'Firebase connected (Default App)';
        debugPrint('[$statusMessage]');
        return true;
      }

      await Firebase.initializeApp();
      _isFirebaseAvailable = true;
      _statusMessage = 'Firebase initialized successfully';
      debugPrint('[$statusMessage]');
      return true;
    } catch (e) {
      _isFirebaseAvailable = false;
      _statusMessage = 'Firebase Offline / Local Fallback Mode: $e';
      debugPrint('[Captain Firebase] Note: $statusMessage');
      return false;
    }
  }

  /// Sync Captain profile to Firestore with fallback
  Future<bool> syncCaptainProfile(FirestoreCaptainModel captain) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Captain profile saved locally.');
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('captains')
          .doc(captain.captainId)
          .set(captain.toMap(), SetOptions(merge: true));
      debugPrint('[QuickRide Captain] Successfully synced captain to Firestore: ${captain.captainId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Firestore sync error (using local fallback): $e');
      return false;
    }
  }

  /// Fetch captain profile from Cloud Firestore
  Future<FirestoreCaptainModel?> fetchCaptainProfile(String captainId) async {
    if (!_isFirebaseAvailable || captainId.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .get();
      if (doc.exists && doc.data() != null) {
        return FirestoreCaptainModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching captain profile: $e');
    }
    return null;
  }

  /// Stream captain profile updates in real time
  Stream<FirestoreCaptainModel?> streamCaptainProfile(String captainId) {
    if (!_isFirebaseAvailable || captainId.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('captains')
        .doc(captainId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FirestoreCaptainModel.fromMap(doc.data()!, id: doc.id);
    });
  }

  /// Update Online/Offline duty status in Firestore
  Future<bool> updateDutyStatus(
    String captainId,
    bool isOnline, {
    Map<String, double>? location,
  }) async {
    if (!_isFirebaseAvailable) return false;

    try {
      final updates = <String, dynamic>{
        'online': isOnline,
      };
      if (location != null) {
        updates['currentLocation'] = location;
      }

      await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .update(updates);
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Duty status sync error: $e');
      return false;
    }
  }

  /// Stream assigned ride requests for this captain with status REQUESTED
  Stream<List<SharedRideModel>> streamAssignedRequests(String captainId) {
    if (!_isFirebaseAvailable) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('rides')
        .where('captainId', isEqualTo: captainId)
        .where('status', isEqualTo: SharedRideStatus.requested.firestoreValue)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedRideModel.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Accept an assigned ride request in Cloud Firestore using atomic transaction (Step 44)
  Future<bool> acceptRide(String rideId, {String? captainId, String? userId}) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Ride $rideId accepted locally.');
      return true;
    }

    try {
      final rideDocRef = FirebaseFirestore.instance.collection('rides').doc(rideId);

      // Concurrency lock: use transaction to prevent two captains accepting same ride
      final success = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(rideDocRef);
        if (!snapshot.exists) {
          debugPrint('[QuickRide Captain] Ride $rideId does not exist');
          return false;
        }

        final data = snapshot.data() ?? {};
        final currentStatus = data['status'] as String?;

        // Only allow transition from REQUESTED
        if (currentStatus != SharedRideStatus.requested.firestoreValue) {
          debugPrint('[QuickRide Captain] Ride $rideId cannot be accepted from state $currentStatus');
          return false;
        }

        final updateData = <String, dynamic>{
          'status': SharedRideStatus.accepted.firestoreValue,
          'acceptedAt': DateTime.now().toIso8601String(),
        };
        if (captainId != null) {
          updateData['captainId'] = captainId;
        }

        transaction.update(rideDocRef, updateData);
        return true;
      });

      if (!success) return false;

      if (captainId != null) {
        final captainUpdates = <String, dynamic>{
          'activeRideId': rideId,
        };
        if (userId != null) {
          captainUpdates['currentRiderId'] = userId;
        }
        await FirebaseFirestore.instance
            .collection('captains')
            .doc(captainId)
            .update(captainUpdates);
      }

      debugPrint('[QuickRide Captain] Ride $rideId accepted atomically in Firestore');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error accepting ride: $e');
      return false;
    }
  }

  /// Reject an assigned ride request in Cloud Firestore
  Future<bool> rejectRide(String rideId, String captainId) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Ride $rideId rejected locally.');
      return true;
    }

    try {
      await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
        'captainId': null,
        'rejectedCaptains': FieldValue.arrayUnion([captainId]),
      });
      debugPrint('[QuickRide Captain] Ride $rideId rejected by $captainId in Firestore');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error rejecting ride: $e');
      return false;
    }
  }

  /// Update Captain live location in Firestore (both in captains and active ride doc)
  Future<bool> updateCaptainLocation(
    String captainId,
    double latitude,
    double longitude, {
    String? rideId,
  }) async {
    if (!_isFirebaseAvailable) return true;

    try {
      final loc = {'lat': latitude, 'lng': longitude};
      await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .update({'currentLocation': loc});

      if (rideId != null && rideId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rides')
            .doc(rideId)
            .update({'captainLocation': loc});
      }
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error updating location: $e');
      return false;
    }
  }

  /// Fetch active assigned ride for this captain during app restart recovery
  Future<SharedRideModel?> fetchActiveRideForCaptain(String captainId) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('captainId', isEqualTo: captainId)
          .where('status', whereIn: [
            SharedRideStatus.accepted.firestoreValue,
            SharedRideStatus.arrived.firestoreValue,
            SharedRideStatus.inProgress.firestoreValue,
          ])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return SharedRideModel.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching active ride: $e');
    }
    return null;
  }

  /// Stream single active ride document updates for real-time lifecycle and cancellation sync
  Stream<SharedRideModel?> streamRide(String rideId) {
    if (!_isFirebaseAvailable) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return SharedRideModel.fromMap(snapshot.data()!, id: snapshot.id);
    });
  }

  /// Update ride status during lifecycle transitions (ARRIVED, IN_PROGRESS, COMPLETED, CANCELLED)
  /// Strictly validates transitions before writing to Firestore.
  Future<bool> updateRideStatus(
    String rideId,
    SharedRideStatus status, {
    String? captainId,
    String? cancelledBy,
    String? cancellationReason,
    String? cancellationDescription,
  }) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Ride $rideId status set to ${status.firestoreValue}');
      return true;
    }

    try {
      final docRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
      final docSnap = await docRef.get();
      if (!docSnap.exists || docSnap.data() == null) {
        debugPrint('[QuickRide Captain] Ride $rideId not found in Firestore.');
        return false;
      }

      final currentStatusStr = docSnap.data()?['status'] as String? ?? 'REQUESTED';
      final currentStatus = SharedRideStatus.fromString(currentStatusStr);

      if (!isValidRideTransition(currentStatus, status)) {
        debugPrint('[QuickRide Captain] Invalid transition rejected: ${currentStatus.firestoreValue} -> ${status.firestoreValue}');
        return false;
      }

      final updates = <String, dynamic>{
        'status': status.firestoreValue,
      };

      if (status == SharedRideStatus.arrived) {
        updates['arrivedAt'] = DateTime.now().toIso8601String();
      } else if (status == SharedRideStatus.inProgress) {
        updates['startedAt'] = DateTime.now().toIso8601String();
      } else if (status == SharedRideStatus.completed) {
        updates['completedAt'] = DateTime.now().toIso8601String();
      } else if (status == SharedRideStatus.cancelled) {
        updates['cancelledAt'] = DateTime.now().toIso8601String();
        updates['cancelledBy'] = cancelledBy ?? 'captain';
        if (cancellationReason != null && cancellationReason.isNotEmpty) {
          updates['cancellationReason'] = cancellationReason;
        }
        if (cancellationDescription != null && cancellationDescription.isNotEmpty) {
          updates['cancellationDescription'] = cancellationDescription;
        }
      }

      await docRef.update(updates);

      // If completed or cancelled, clear active rider reference on captain
      if ((status == SharedRideStatus.completed || status == SharedRideStatus.cancelled) &&
          captainId != null) {
        await FirebaseFirestore.instance
            .collection('captains')
            .doc(captainId)
            .update({
          'currentRiderId': null,
          'activeRideId': null,
        });
      }

      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error updating ride status: $e');
      return false;
    }
  }

  /// Submit a post-ride rating and review (Captain -> User)
  /// Checks whether a rating document already exists for this ride and ratedBy
  /// to strictly prevent duplicate ratings.
  Future<bool> submitRating(FirestoreRatingModel rating) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Rating for ${rating.rideId} saved locally.');
      return true;
    }

    try {
      final docId = rating.ratingId.isNotEmpty ? rating.ratingId : '${rating.rideId}_captain';
      final ratingRef = FirebaseFirestore.instance.collection('ratings').doc(docId);

      // Check if already rated
      final existing = await ratingRef.get();
      if (existing.exists) {
        debugPrint('[QuickRide Captain] Ride ${rating.rideId} has already been rated by captain.');
        return false;
      }

      // Save rating document
      final modelToSave = FirestoreRatingModel(
        ratingId: docId,
        rideId: rating.rideId,
        userId: rating.userId,
        captainId: rating.captainId,
        ratedBy: 'captain',
        ratedUserId: rating.userId,
        ratedCaptainId: rating.captainId,
        stars: rating.stars,
        rating: rating.rating,
        review: rating.review,
        createdAt: rating.createdAt,
      );

      await ratingRef.set(modelToSave.toMap());

      // Update User's average rating in Firestore if userId is provided
      if (rating.userId.isNotEmpty) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(rating.userId);
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final userDoc = await transaction.get(userRef);
            if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data()!;
              final currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
              final currentCount = (data['totalRatings'] as num?)?.toInt() ?? 1;
              final newCount = currentCount + 1;
              final newRating = double.parse(
                (((currentRating * currentCount) + rating.stars) / newCount).toStringAsFixed(2),
              );

              transaction.update(userRef, {
                'rating': newRating,
                'totalRatings': newCount,
              });
            }
          });
        } catch (txError) {
          debugPrint('[QuickRide Captain] Note: Could not update user stats: $txError');
        }
      }

      debugPrint('[QuickRide Captain] Rating $docId successfully saved.');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error submitting rating: $e');
      return false;
    }
  }

  /// Check if the captain has already rated a ride in Firestore
  Future<bool> hasRated(String rideId, {String ratedBy = 'captain'}) async {
    if (!_isFirebaseAvailable) return false;

    try {
      final docId = '${rideId}_$ratedBy';
      final doc = await FirebaseFirestore.instance.collection('ratings').doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error checking rating status: $e');
      return false;
    }
  }

  /// Fetch rating document for a ride
  Future<FirestoreRatingModel?> fetchRating(String rideId, {String ratedBy = 'captain'}) async {
    if (!_isFirebaseAvailable) return null;

    try {
      final docId = '${rideId}_$ratedBy';
      final doc = await FirebaseFirestore.instance.collection('ratings').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return FirestoreRatingModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching rating: $e');
    }
    return null;
  }

  /// Update device FCM push token in Firestore captain profile
  Future<bool> updateCaptainFcmToken(String captainId, String? token) async {
    if (!_isFirebaseAvailable || captainId.isEmpty) {
      debugPrint('[QuickRide Captain] Offline mode: FCM token update skipped.');
      return false;
    }

    try {
      await FirebaseFirestore.instance.collection('captains').doc(captainId).set({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[QuickRide Captain] FCM token updated in Firestore for captain: $captainId');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error updating FCM token in Firestore: $e');
      return false;
    }
  }

  /// Create a notification record in Firestore
  Future<bool> createNotification(FirestoreNotificationModel notification) async {
    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: Notification record saved locally.');
      return false;
    }

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap(), SetOptions(merge: true));
      debugPrint('[QuickRide Captain] Notification saved: ${notification.notificationId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error saving notification: $e');
      return false;
    }
  }

  /// Stream notifications for this captain in real time
  Stream<List<FirestoreNotificationModel>> streamCaptainNotifications(String captainId) {
    if (!_isFirebaseAvailable || captainId.isEmpty) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: captainId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreNotificationModel.fromMap(doc.data(), id: doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Mark a notification as read in Firestore
  Future<bool> markNotificationRead(String notificationId) async {
    if (!_isFirebaseAvailable || notificationId.isEmpty) return false;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error marking notification read: $e');
      return false;
    }
  }

  // ===========================================================================
  // STEP 39: CAPTAIN CUSTOMER SUPPORT & COMPLAINTS MANAGEMENT
  // ===========================================================================

  /// Stream all complaints filed by a Captain
  Stream<List<FirestoreComplaintModel>> streamCaptainComplaints(String captainId) {
    if (!_isFirebaseAvailable) {
      final list = _localComplaints.where((c) => c.captainId == captainId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream.value(list);
    }

    return FirebaseFirestore.instance
        .collection('complaints')
        .where('captainId', isEqualTo: captainId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreComplaintModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch all complaints filed by a Captain once
  Future<List<FirestoreComplaintModel>> fetchCaptainComplaints(String captainId) async {
    if (!_isFirebaseAvailable) {
      final list = _localComplaints.where((c) => c.captainId == captainId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('captainId', isEqualTo: captainId)
          .get();

      final list = snapshot.docs
          .map((doc) => FirestoreComplaintModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching captain complaints: $e');
      final list = _localComplaints.where((c) => c.captainId == captainId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
  }

  /// Fetch single complaint by ID
  Future<FirestoreComplaintModel?> fetchComplaintById(String complaintId) async {
    if (!_isFirebaseAvailable) {
      return _localComplaints.cast<FirestoreComplaintModel?>().firstWhere(
            (c) => c?.complaintId == complaintId,
            orElse: () => null,
          );
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .get();

      if (doc.exists && doc.data() != null) {
        return FirestoreComplaintModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching complaint $complaintId: $e');
      return _localComplaints.cast<FirestoreComplaintModel?>().firstWhere(
            (c) => c?.complaintId == complaintId,
            orElse: () => null,
          );
    }
  }

  /// Create a new complaint filed by Captain in Firestore
  Future<bool> createComplaint(FirestoreComplaintModel complaint) async {
    _localComplaints.removeWhere((c) => c.complaintId == complaint.complaintId);
    _localComplaints.insert(0, complaint);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: complaint stored locally: ${complaint.complaintId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaint.complaintId)
          .set(complaint.toMap(), SetOptions(merge: true));
      debugPrint('[QuickRide Captain] Successfully created complaint in Firestore: ${complaint.complaintId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error creating complaint in Firestore: $e');
      return false;
    }
  }

  /// Stream conversation replies for a complaint
  Stream<List<FirestoreComplaintReplyModel>> streamComplaintReplies(String complaintId) {
    if (!_isFirebaseAvailable) {
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return Stream.value(list);
    }

    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('replies')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreComplaintReplyModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  /// Fetch conversation replies once
  Future<List<FirestoreComplaintReplyModel>> fetchComplaintReplies(String complaintId) async {
    if (!_isFirebaseAvailable) {
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .collection('replies')
          .get();

      final list = snapshot.docs
          .map((doc) => FirestoreComplaintReplyModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching complaint replies: $e');
      final list = List<FirestoreComplaintReplyModel>.from(_localReplies[complaintId] ?? []);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }
  }

  /// Add a reply message to a complaint thread
  Future<bool> addComplaintReply(FirestoreComplaintReplyModel reply) async {
    _localReplies.putIfAbsent(reply.complaintId, () => []);
    _localReplies[reply.complaintId]!.add(reply);

    final cIndex = _localComplaints.indexWhere((c) => c.complaintId == reply.complaintId);
    if (cIndex != -1) {
      _localComplaints[cIndex] = _localComplaints[cIndex].copyWith(updatedAt: DateTime.now());
    }

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: complaint reply stored locally: ${reply.replyId}');
      return true;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      final replyRef = FirebaseFirestore.instance
          .collection('complaints')
          .doc(reply.complaintId)
          .collection('replies')
          .doc(reply.replyId);
      final complaintRef = FirebaseFirestore.instance
          .collection('complaints')
          .doc(reply.complaintId);

      batch.set(replyRef, reply.toMap());
      batch.update(complaintRef, {'updatedAt': DateTime.now().toIso8601String()});
      await batch.commit();

      debugPrint('[QuickRide Captain] Successfully added reply to complaint: ${reply.complaintId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error adding reply to complaint: $e');
      return false;
    }
  }

  // ==========================================================================
  // STEP 40: SAFETY CENTER & EMERGENCY (SOS) MANAGEMENT
  // ==========================================================================

  final List<FirestoreEmergencyIncidentModel> _localEmergencies = [];
  final List<FirestoreEmergencyContactModel> _localEmergencyContacts = [
    FirestoreEmergencyContactModel(
      contactId: 'contact_cpt_1',
      ownerId: 'captain_seed_01',
      name: 'Captain Helpline / Family',
      phone: '9876543210',
      relationship: 'Family',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  /// Create a new emergency incident
  Future<bool> createEmergencyIncident(FirestoreEmergencyIncidentModel emergency) async {
    final existingIdx = _localEmergencies.indexWhere(
      (e) => e.rideId == emergency.rideId && e.isActive,
    );
    if (existingIdx != -1) {
      debugPrint('[QuickRide Captain] Active emergency already exists for ride: ${emergency.rideId}');
      return true;
    }

    _localEmergencies.add(emergency);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: emergency incident stored locally: ${emergency.emergencyId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('emergencies')
          .doc(emergency.emergencyId)
          .set(emergency.toMap());
      debugPrint('[QuickRide Captain] Emergency incident saved to Firestore: ${emergency.emergencyId}');
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error saving emergency incident: $e');
      return false;
    }
  }

  /// Update current coordinates for an active emergency incident
  Future<bool> updateEmergencyLocation(String emergencyId, double latitude, double longitude) async {
    final idx = _localEmergencies.indexWhere((e) => e.emergencyId == emergencyId);
    if (idx != -1) {
      _localEmergencies[idx] = _localEmergencies[idx].copyWith(
        latitude: latitude,
        longitude: longitude,
        updatedAt: DateTime.now(),
      );
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance.collection('emergencies').doc(emergencyId).update({
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error updating emergency location: $e');
      return false;
    }
  }

  /// Stream active emergency incident for a specific captain
  Stream<FirestoreEmergencyIncidentModel?> streamActiveEmergency(String captainId) {
    if (!_isFirebaseAvailable || captainId.isEmpty) {
      final active = _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
        (e) => (e?.captainId == captainId || captainId == 'captain_seed_01') && e?.isActive == true,
        orElse: () => null,
      );
      return Stream.value(active);
    }

    return FirebaseFirestore.instance
        .collection('emergencies')
        .where('captainId', isEqualTo: captainId)
        .where('status', isEqualTo: 'ACTIVE')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FirestoreEmergencyIncidentModel.fromMap(doc.data(), id: doc.id);
    });
  }

  /// Fetch active emergency for captain once
  Future<FirestoreEmergencyIncidentModel?> fetchActiveEmergency(String captainId) async {
    if (!_isFirebaseAvailable || captainId.isEmpty) {
      return _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
        (e) => (e?.captainId == captainId || captainId == 'captain_seed_01') && e?.isActive == true,
        orElse: () => null,
      );
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('emergencies')
          .where('captainId', isEqualTo: captainId)
          .where('status', isEqualTo: 'ACTIVE')
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return FirestoreEmergencyIncidentModel.fromMap(doc.data(), id: doc.id);
      }
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching active emergency: $e');
    }

    return _localEmergencies.cast<FirestoreEmergencyIncidentModel?>().firstWhere(
      (e) => (e?.captainId == captainId || captainId == 'captain_seed_01') && e?.isActive == true,
      orElse: () => null,
    );
  }

  /// Stream emergency contacts for captain
  Stream<List<FirestoreEmergencyContactModel>> streamEmergencyContacts(String captainId) {
    if (!_isFirebaseAvailable || captainId.isEmpty) {
      return Stream.value(List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts));
    }

    return FirebaseFirestore.instance
        .collection('captains')
        .doc(captainId)
        .collection('emergency_contacts')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FirestoreEmergencyContactModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Fetch emergency contacts once
  Future<List<FirestoreEmergencyContactModel>> fetchEmergencyContacts(String captainId) async {
    if (!_isFirebaseAvailable || captainId.isEmpty) {
      return List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .collection('emergency_contacts')
          .get();
      final list = snapshot.docs
          .map((doc) => FirestoreEmergencyContactModel.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching emergency contacts: $e');
      return List<FirestoreEmergencyContactModel>.from(_localEmergencyContacts);
    }
  }

  /// Add emergency contact
  Future<bool> addEmergencyContact(FirestoreEmergencyContactModel contact) async {
    _localEmergencyContacts.removeWhere((c) => c.contactId == contact.contactId);
    _localEmergencyContacts.add(contact);

    if (!_isFirebaseAvailable) {
      debugPrint('[QuickRide Captain] Offline mode: emergency contact stored locally: ${contact.contactId}');
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('captains')
          .doc(contact.ownerId)
          .collection('emergency_contacts')
          .doc(contact.contactId)
          .set(contact.toMap());
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error adding emergency contact: $e');
      return false;
    }
  }

  /// Update emergency contact
  Future<bool> updateEmergencyContact(FirestoreEmergencyContactModel contact) async {
    final idx = _localEmergencyContacts.indexWhere((c) => c.contactId == contact.contactId);
    if (idx != -1) {
      _localEmergencyContacts[idx] = contact;
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('captains')
          .doc(contact.ownerId)
          .collection('emergency_contacts')
          .doc(contact.contactId)
          .set(contact.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error updating emergency contact: $e');
      return false;
    }
  }

  /// Delete emergency contact
  Future<bool> deleteEmergencyContact(String captainId, String contactId) async {
    _localEmergencyContacts.removeWhere((c) => c.contactId == contactId);

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('captains')
          .doc(captainId)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error deleting emergency contact: $e');
      return false;
    }
  }

  // ==========================================================================
  // STEP 45: REAL-TIME CHAT
  // ==========================================================================

  final Map<String, List<FirestoreChatMessageModel>> _localChatMessages = {};
  final Map<String, StreamController<List<FirestoreChatMessageModel>>> _chatControllers = {};

  StreamController<List<FirestoreChatMessageModel>> _getChatController(String rideId) {
    return _chatControllers.putIfAbsent(
      rideId,
      () => StreamController<List<FirestoreChatMessageModel>>.broadcast(),
    );
  }

  /// Stream real-time chat messages for a ride
  Stream<List<FirestoreChatMessageModel>> streamChatMessages(String rideId) {
    if (!_isFirebaseAvailable) {
      final controller = _getChatController(rideId);
      final messages = _localChatMessages[rideId] ?? [];
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(messages));
        }
      });
      return controller.stream;
    }

    try {
      return FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => FirestoreChatMessageModel.fromMap(doc.data(), id: doc.id))
              .toList());
    } catch (e) {
      debugPrint('[QuickRide Captain] Error streaming chat messages for ride $rideId: $e');
      final controller = _getChatController(rideId);
      final messages = _localChatMessages[rideId] ?? [];
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(messages));
        }
      });
      return controller.stream;
    }
  }

  /// Fetch one-time chat message list
  Future<List<FirestoreChatMessageModel>> fetchChatMessages(String rideId) async {
    if (!_isFirebaseAvailable) {
      return List.unmodifiable(_localChatMessages[rideId] ?? []);
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreChatMessageModel.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('[QuickRide Captain] Error fetching chat messages: $e');
      return List.unmodifiable(_localChatMessages[rideId] ?? []);
    }
  }

  /// Send a chat message
  Future<bool> sendChatMessage(FirestoreChatMessageModel message) async {
    final list = _localChatMessages.putIfAbsent(message.rideId, () => []);
    list.add(message);
    _getChatController(message.rideId).add(List.unmodifiable(list));

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(message.rideId)
          .collection('messages')
          .doc(message.messageId)
          .set(message.toMap());
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error sending chat message: $e');
      return false;
    }
  }

  /// Mark message as read
  Future<bool> markChatMessageAsRead(String rideId, String messageId) async {
    final list = _localChatMessages[rideId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.messageId == messageId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(read: true);
        _getChatController(rideId).add(List.unmodifiable(list));
      }
    }

    if (!_isFirebaseAvailable) return true;

    try {
      await FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
      return true;
    } catch (e) {
      debugPrint('[QuickRide Captain] Error marking chat message as read: $e');
      return false;
    }
  }

  /// Reset in-memory chat messages (for hermetic testing)
  void clearLocalChatMessages([String? rideId]) {
    if (rideId != null) {
      _localChatMessages.remove(rideId);
      _getChatController(rideId).add([]);
    } else {
      _localChatMessages.clear();
      for (final controller in _chatControllers.values) {
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }
  }

  /// Reset in-memory emergencies (for hermetic testing)
  void clearLocalEmergencies() {
    _localEmergencies.clear();
  }

  /// Reset in-memory complaints (for hermetic testing)
  void clearLocalComplaints() {
    _localComplaints.clear();
    _localReplies.clear();
  }

  /// Diagnostic test helper
  Future<Map<String, dynamic>> testConnection() async {
    return {
      'isFirebaseAvailable': _isFirebaseAvailable,
      'status': _statusMessage,
      'appId': 'com.quickride.captain',
      'firestoreTarget': 'captains, rides, ratings, notifications, complaints, emergencies',
    };
  }
}

