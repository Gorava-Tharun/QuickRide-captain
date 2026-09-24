class FirestoreUserModel {
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String? profileImage;
  final String status;
  final double rating;
  final int totalRatings;
  final String? fcmToken;
  final DateTime createdAt;

  const FirestoreUserModel({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.profileImage,
    this.status = 'ACTIVE',
    this.rating = 5.0,
    this.totalRatings = 1,
    this.fcmToken,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'phone': phone,
    'email': email,
    'profileImage': profileImage,
    'status': status,
    'rating': rating,
    'totalRatings': totalRatings,
    if (fcmToken != null) 'fcmToken': fcmToken,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FirestoreUserModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreUserModel(
        userId: id ?? (map['userId'] as String? ?? ''),
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        profileImage: map['profileImage'] as String?,
        status: map['status'] as String? ?? 'ACTIVE',
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        totalRatings: (map['totalRatings'] as num?)?.toInt() ?? 1,
        fcmToken: map['fcmToken'] as String?,
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      );

  FirestoreUserModel copyWith({
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? profileImage,
    String? status,
    double? rating,
    int? totalRatings,
    String? fcmToken,
    DateTime? createdAt,
  }) =>
      FirestoreUserModel(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        profileImage: profileImage ?? this.profileImage,
        status: status ?? this.status,
        rating: rating ?? this.rating,
        totalRatings: totalRatings ?? this.totalRatings,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt ?? this.createdAt,
      );
}

class FirestoreCaptainModel {
  final String captainId;
  final String name;
  final String phone;
  final String email;
  final String vehicleNumber;
  final String vehicleType;
  final String drivingLicenseNumber;
  final double rating;
  final int totalRatings;
  final bool online;
  final String? fcmToken;
  final Map<String, double>? currentLocation;
  final String? profileImage;
  final String? vehicleImage;
  final String verificationStatus;
  final String vehicleVerificationStatus;
  final DateTime? documentsSubmittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? drivingLicenseImageUrl;
  final String? vehicleDocumentImageUrl;
  final DateTime createdAt;

  bool get isApproved => verificationStatus == 'APPROVED';
  bool get isPending => verificationStatus == 'PENDING';
  bool get isRejected => verificationStatus == 'REJECTED';

  const FirestoreCaptainModel({
    required this.captainId,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.drivingLicenseNumber,
    this.rating = 5.0,
    this.totalRatings = 1,
    this.online = false,
    this.fcmToken,
    this.currentLocation,
    this.profileImage,
    this.vehicleImage,
    this.verificationStatus = 'PENDING',
    this.vehicleVerificationStatus = 'PENDING',
    this.documentsSubmittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.drivingLicenseImageUrl,
    this.vehicleDocumentImageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'captainId': captainId,
    'name': name,
    'phone': phone,
    'email': email,
    'vehicleNumber': vehicleNumber,
    'vehicleType': vehicleType,
    'drivingLicenseNumber': drivingLicenseNumber,
    'rating': rating,
    'totalRatings': totalRatings,
    'online': online,
    if (fcmToken != null) 'fcmToken': fcmToken,
    'currentLocation': currentLocation,
    'profileImage': profileImage,
    'profilePhotoUrl': profileImage,
    'vehicleImage': vehicleImage,
    'vehiclePhotoUrl': vehicleImage,
    'verificationStatus': verificationStatus,
    'vehicleVerificationStatus': vehicleVerificationStatus,
    if (documentsSubmittedAt != null)
      'documentsSubmittedAt': documentsSubmittedAt!.toIso8601String(),
    if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    if (drivingLicenseImageUrl != null)
      'drivingLicenseImageUrl': drivingLicenseImageUrl,
    if (vehicleDocumentImageUrl != null)
      'vehicleDocumentImageUrl': vehicleDocumentImageUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FirestoreCaptainModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreCaptainModel(
        captainId: id ?? (map['captainId'] as String? ?? ''),
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        vehicleNumber: map['vehicleNumber'] as String? ?? '',
        vehicleType: map['vehicleType'] as String? ?? '',
        drivingLicenseNumber: map['drivingLicenseNumber'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
        totalRatings: (map['totalRatings'] as num?)?.toInt() ?? 1,
        online: map['online'] as bool? ?? false,
        fcmToken: map['fcmToken'] as String?,
        currentLocation: map['currentLocation'] != null
            ? Map<String, double>.from(map['currentLocation'] as Map)
            : null,
        profileImage: (map['profilePhotoUrl'] ?? map['profileImage']) as String?,
        vehicleImage: (map['vehiclePhotoUrl'] ?? map['vehicleImage']) as String?,
        verificationStatus: map['verificationStatus'] as String? ?? 'PENDING',
        vehicleVerificationStatus:
            map['vehicleVerificationStatus'] as String? ?? 'PENDING',
        documentsSubmittedAt:
            _parseSharedDateTime(map['documentsSubmittedAt']),
        verifiedAt: _parseSharedDateTime(map['verifiedAt']),
        rejectionReason: map['rejectionReason'] as String?,
        drivingLicenseImageUrl: (map['drivingLicenseImageUrl'] ??
            map['licenseDocumentUrl']) as String?,
        vehicleDocumentImageUrl: (map['vehicleDocumentImageUrl'] ??
            map['vehicleRcImageUrl']) as String?,
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      );

  FirestoreCaptainModel copyWith({
    String? captainId,
    String? name,
    String? phone,
    String? email,
    String? vehicleNumber,
    String? vehicleType,
    String? drivingLicenseNumber,
    double? rating,
    int? totalRatings,
    bool? online,
    String? fcmToken,
    Map<String, double>? currentLocation,
    String? profileImage,
    String? vehicleImage,
    String? verificationStatus,
    String? vehicleVerificationStatus,
    DateTime? documentsSubmittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? drivingLicenseImageUrl,
    String? vehicleDocumentImageUrl,
    DateTime? createdAt,
  }) =>
      FirestoreCaptainModel(
        captainId: captainId ?? this.captainId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        vehicleNumber: vehicleNumber ?? this.vehicleNumber,
        vehicleType: vehicleType ?? this.vehicleType,
        drivingLicenseNumber: drivingLicenseNumber ?? this.drivingLicenseNumber,
        rating: rating ?? this.rating,
        totalRatings: totalRatings ?? this.totalRatings,
        online: online ?? this.online,
        fcmToken: fcmToken ?? this.fcmToken,
        currentLocation: currentLocation ?? this.currentLocation,
        profileImage: profileImage ?? this.profileImage,
        vehicleImage: vehicleImage ?? this.vehicleImage,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        vehicleVerificationStatus:
            vehicleVerificationStatus ?? this.vehicleVerificationStatus,
        documentsSubmittedAt: documentsSubmittedAt ?? this.documentsSubmittedAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        drivingLicenseImageUrl:
            drivingLicenseImageUrl ?? this.drivingLicenseImageUrl,
        vehicleDocumentImageUrl:
            vehicleDocumentImageUrl ?? this.vehicleDocumentImageUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}

enum SharedRideStatus {
  requested,
  accepted,
  arrived,
  inProgress,
  completed,
  cancelled;

  String get firestoreValue {
    switch (this) {
      case SharedRideStatus.requested:
        return 'REQUESTED';
      case SharedRideStatus.accepted:
        return 'ACCEPTED';
      case SharedRideStatus.arrived:
        return 'ARRIVED';
      case SharedRideStatus.inProgress:
        return 'IN_PROGRESS';
      case SharedRideStatus.completed:
        return 'COMPLETED';
      case SharedRideStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static SharedRideStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'REQUESTED':
        return SharedRideStatus.requested;
      case 'ACCEPTED':
        return SharedRideStatus.accepted;
      case 'ARRIVED':
        return SharedRideStatus.arrived;
      case 'IN_PROGRESS':
        return SharedRideStatus.inProgress;
      case 'COMPLETED':
        return SharedRideStatus.completed;
      case 'CANCELLED':
        return SharedRideStatus.cancelled;
      default:
        return SharedRideStatus.requested;
    }
  }
}

/// Enforces strict valid status transitions according to Step 33:
/// REQUESTED → ACCEPTED | CANCELLED
/// ACCEPTED → ARRIVED | CANCELLED
/// ARRIVED → IN_PROGRESS | CANCELLED
/// IN_PROGRESS → COMPLETED | CANCELLED
bool isValidRideTransition(SharedRideStatus from, SharedRideStatus to) {
  switch (from) {
    case SharedRideStatus.requested:
      return to == SharedRideStatus.accepted || to == SharedRideStatus.cancelled;
    case SharedRideStatus.accepted:
      return to == SharedRideStatus.arrived || to == SharedRideStatus.cancelled;
    case SharedRideStatus.arrived:
      return to == SharedRideStatus.inProgress || to == SharedRideStatus.cancelled;
    case SharedRideStatus.inProgress:
      return to == SharedRideStatus.completed || to == SharedRideStatus.cancelled;
    case SharedRideStatus.completed:
    case SharedRideStatus.cancelled:
      return false; // Terminal states
  }
}

DateTime? _parseSharedDateTime(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val);
  try {
    return (val as dynamic).toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}

class SharedRideModel {
  final String rideId;
  final String userId;
  final String userName;
  final String? captainId;
  final String pickup;
  final String destination;
  final Map<String, double> pickupLocation;
  final Map<String, double> destinationLocation;
  final String vehicleType;
  final double fare;
  final double distance;
  final int estimatedTime;
  final SharedRideStatus status;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final String? cancellationDescription;
  final double? cancellationFee;
  final double? refundAmount;
  final String? refundStatus; // 'PENDING', 'COMPLETED', 'FAILED'
  final String? refundId;
  final DateTime? refundedAt;
  final Map<String, double>? captainLocation;
  final List<String> rejectedCaptains;
  final String? offerId;
  final String? couponCode;
  final double? originalFare;
  final double? discountAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentId;

  bool get isCancelled => status == SharedRideStatus.cancelled;
  bool get isRefunded => refundStatus == 'COMPLETED' || paymentStatus == 'REFUNDED';

  const SharedRideModel({
    required this.rideId,
    required this.userId,
    this.userName = 'Rider',
    this.captainId,
    required this.pickup,
    required this.destination,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.vehicleType,
    required this.fare,
    required this.distance,
    required this.estimatedTime,
    this.status = SharedRideStatus.requested,
    required this.requestedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancellationReason,
    this.cancellationDescription,
    this.cancellationFee,
    this.refundAmount,
    this.refundStatus,
    this.refundId,
    this.refundedAt,
    this.captainLocation,
    this.rejectedCaptains = const [],
    this.offerId,
    this.couponCode,
    this.originalFare,
    this.discountAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentId,
  });

  SharedRideModel copyWith({
    String? rideId,
    String? userId,
    String? userName,
    String? captainId,
    String? pickup,
    String? destination,
    Map<String, double>? pickupLocation,
    Map<String, double>? destinationLocation,
    String? vehicleType,
    double? fare,
    double? distance,
    int? estimatedTime,
    SharedRideStatus? status,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancelledBy,
    String? cancellationReason,
    String? cancellationDescription,
    double? cancellationFee,
    double? refundAmount,
    String? refundStatus,
    String? refundId,
    DateTime? refundedAt,
    Map<String, double>? captainLocation,
    List<String>? rejectedCaptains,
    String? offerId,
    String? couponCode,
    double? originalFare,
    double? discountAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentId,
  }) {
    return SharedRideModel(
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      captainId: captainId ?? this.captainId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      vehicleType: vehicleType ?? this.vehicleType,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationDescription: cancellationDescription ?? this.cancellationDescription,
      cancellationFee: cancellationFee ?? this.cancellationFee,
      refundAmount: refundAmount ?? this.refundAmount,
      refundStatus: refundStatus ?? this.refundStatus,
      refundId: refundId ?? this.refundId,
      refundedAt: refundedAt ?? this.refundedAt,
      captainLocation: captainLocation ?? this.captainLocation,
      rejectedCaptains: rejectedCaptains ?? this.rejectedCaptains,
      offerId: offerId ?? this.offerId,
      couponCode: couponCode ?? this.couponCode,
      originalFare: originalFare ?? this.originalFare,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  Map<String, dynamic> toMap() => {
    'rideId': rideId,
    'userId': userId,
    'userName': userName,
    'captainId': captainId,
    'pickup': pickup,
    'destination': destination,
    'pickupLocation': pickupLocation,
    'destinationLocation': destinationLocation,
    'vehicleType': vehicleType,
    'fare': fare,
    'distance': distance,
    'estimatedTime': estimatedTime,
    'status': status.firestoreValue,
    'requestedAt': requestedAt.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'arrivedAt': arrivedAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'cancelledAt': cancelledAt?.toIso8601String(),
    'cancelledBy': cancelledBy,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    if (cancellationDescription != null)
      'cancellationDescription': cancellationDescription,
    if (cancellationFee != null) 'cancellationFee': cancellationFee,
    if (refundAmount != null) 'refundAmount': refundAmount,
    if (refundStatus != null) 'refundStatus': refundStatus,
    if (refundId != null) 'refundId': refundId,
    if (refundedAt != null) 'refundedAt': refundedAt!.toIso8601String(),
    'captainLocation': captainLocation,
    'rejectedCaptains': rejectedCaptains,
    if (offerId != null) 'offerId': offerId,
    if (couponCode != null) 'couponCode': couponCode,
    if (originalFare != null) 'originalFare': originalFare,
    if (discountAmount != null) 'discountAmount': discountAmount,
    if (paymentMethod != null) 'paymentMethod': paymentMethod,
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
    if (paymentId != null) 'paymentId': paymentId,
  };

  factory SharedRideModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      SharedRideModel(
        rideId: id ?? (map['rideId'] as String? ?? ''),
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? 'Rider',
        captainId: map['captainId'] as String?,
        pickup: map['pickup'] as String? ?? '',
        destination: map['destination'] as String? ?? '',
        pickupLocation: map['pickupLocation'] != null
            ? Map<String, double>.from(map['pickupLocation'] as Map)
            : {'lat': 0.0, 'lng': 0.0},
        destinationLocation: map['destinationLocation'] != null
            ? Map<String, double>.from(map['destinationLocation'] as Map)
            : {'lat': 0.0, 'lng': 0.0},
        vehicleType: map['vehicleType'] as String? ?? 'Bike',
        fare: (map['fare'] as num?)?.toDouble() ?? 0.0,
        distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
        estimatedTime: (map['estimatedTime'] as num?)?.toInt() ?? 0,
        status: SharedRideStatus.fromString(map['status'] as String? ?? 'REQUESTED'),
        requestedAt: _parseSharedDateTime(map['requestedAt']) ?? DateTime.now(),
        acceptedAt: _parseSharedDateTime(map['acceptedAt']),
        arrivedAt: _parseSharedDateTime(map['arrivedAt']),
        startedAt: _parseSharedDateTime(map['startedAt']),
        completedAt: _parseSharedDateTime(map['completedAt']),
        cancelledAt: _parseSharedDateTime(map['cancelledAt']),
        cancelledBy: map['cancelledBy'] as String?,
        cancellationReason: map['cancellationReason'] as String?,
        cancellationDescription: map['cancellationDescription'] as String?,
        cancellationFee: (map['cancellationFee'] as num?)?.toDouble(),
        refundAmount: (map['refundAmount'] as num?)?.toDouble(),
        refundStatus: map['refundStatus'] as String?,
        refundId: map['refundId'] as String?,
        refundedAt: _parseSharedDateTime(map['refundedAt']),
        captainLocation: map['captainLocation'] != null
            ? Map<String, double>.from(map['captainLocation'] as Map)
            : null,
        rejectedCaptains: map['rejectedCaptains'] != null
            ? List<String>.from(map['rejectedCaptains'] as List)
            : const [],
        offerId: map['offerId'] as String?,
        couponCode: map['couponCode'] as String?,
        originalFare: (map['originalFare'] as num?)?.toDouble(),
        discountAmount: (map['discountAmount'] as num?)?.toDouble(),
        paymentMethod: map['paymentMethod'] as String?,
        paymentStatus: map['paymentStatus'] as String?,
        paymentId: map['paymentId'] as String?,
      );
}

class FirestoreRatingModel {
  final String ratingId;
  final String rideId;
  final String userId;
  final String captainId;
  final String ratedBy; // 'user' or 'captain'
  final String ratedUserId;
  final String ratedCaptainId;
  final int stars;
  final double rating;
  final String review;
  final DateTime createdAt;

  FirestoreRatingModel({
    required this.ratingId,
    required this.rideId,
    required this.userId,
    required this.captainId,
    this.ratedBy = 'user',
    String? ratedUserId,
    String? ratedCaptainId,
    int? stars,
    double? rating,
    this.review = '',
    required this.createdAt,
  })  : ratedUserId = ratedUserId ?? (ratedBy == 'captain' ? userId : ''),
        ratedCaptainId = ratedCaptainId ?? (ratedBy == 'user' ? captainId : ''),
        stars = stars ?? (rating != null ? rating.toInt() : 5),
        rating = rating ?? (stars != null ? stars.toDouble() : 5.0);

  Map<String, dynamic> toMap() => {
    'ratingId': ratingId,
    'rideId': rideId,
    'userId': userId,
    'captainId': captainId,
    'ratedBy': ratedBy,
    'ratedUserId': ratedUserId,
    'ratedCaptainId': ratedCaptainId,
    'stars': stars,
    'rating': rating,
    'review': review,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FirestoreRatingModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final ratedByVal = map['ratedBy'] as String? ?? 'user';
    final parsedStars = (map['stars'] as num?)?.toInt() ??
        ((map['rating'] as num?)?.toInt() ?? 5);
    final parsedRating = (map['rating'] as num?)?.toDouble() ??
        parsedStars.toDouble();

    return FirestoreRatingModel(
      ratingId: id ?? (map['ratingId'] as String? ?? ''),
      rideId: map['rideId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      captainId: map['captainId'] as String? ?? '',
      ratedBy: ratedByVal,
      ratedUserId: map['ratedUserId'] as String?,
      ratedCaptainId: map['ratedCaptainId'] as String?,
      stars: parsedStars,
      rating: parsedRating,
      review: map['review'] as String? ?? '',
      createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }
}

class FirestoreComplaintModel {
  final String complaintId;
  final String? userId;
  final String? captainId;
  final String complainantRole; // 'USER' or 'CAPTAIN'
  final String complainantName;
  final String complainantPhone;
  final String category;
  final String subject;
  final String description;
  final String? rideId;
  final String? paymentId;
  final String? attachmentUrl;
  final String status; // 'OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'
  final String priority; // 'LOW', 'NORMAL', 'HIGH', 'URGENT'
  final String? adminNotes;
  final String? resolutionSummary;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const FirestoreComplaintModel({
    required this.complaintId,
    this.userId,
    this.captainId,
    this.complainantRole = 'CAPTAIN',
    this.complainantName = '',
    this.complainantPhone = '',
    this.category = 'OTHER',
    required this.subject,
    required this.description,
    this.rideId,
    this.paymentId,
    this.attachmentUrl,
    this.status = 'OPEN',
    this.priority = 'NORMAL',
    this.adminNotes,
    this.resolutionSummary,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
    'complaintId': complaintId,
    if (userId != null) 'userId': userId,
    if (captainId != null) 'captainId': captainId,
    'complainantRole': complainantRole,
    'complainantName': complainantName,
    'complainantPhone': complainantPhone,
    'category': category,
    'subject': subject,
    'description': description,
    if (rideId != null) 'rideId': rideId,
    if (paymentId != null) 'paymentId': paymentId,
    if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    'status': status,
    'priority': priority,
    if (adminNotes != null) 'adminNotes': adminNotes,
    if (resolutionSummary != null) 'resolutionSummary': resolutionSummary,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
  };

  factory FirestoreComplaintModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreComplaintModel(
        complaintId: id ?? (map['complaintId'] as String? ?? ''),
        userId: map['userId'] as String?,
        captainId: map['captainId'] as String?,
        complainantRole: map['complainantRole'] as String? ??
            ((map['captainId'] != null && (map['captainId'] as String).isNotEmpty && map['userId'] == null)
                ? 'CAPTAIN'
                : 'USER'),
        complainantName: map['complainantName'] as String? ?? '',
        complainantPhone: map['complainantPhone'] as String? ?? '',
        category: map['category'] as String? ?? 'OTHER',
        subject: map['subject'] as String? ?? '',
        description: map['description'] as String? ?? '',
        rideId: map['rideId'] as String?,
        paymentId: map['paymentId'] as String?,
        attachmentUrl: map['attachmentUrl'] as String?,
        status: (map['status'] as String? ?? 'OPEN').toUpperCase(),
        priority: (map['priority'] as String? ?? 'NORMAL').toUpperCase(),
        adminNotes: map['adminNotes'] as String?,
        resolutionSummary: map['resolutionSummary'] as String?,
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseSharedDateTime(map['updatedAt']),
        resolvedAt: _parseSharedDateTime(map['resolvedAt']),
      );

  FirestoreComplaintModel copyWith({
    String? complaintId,
    String? userId,
    String? captainId,
    String? complainantRole,
    String? complainantName,
    String? complainantPhone,
    String? category,
    String? subject,
    String? description,
    String? rideId,
    String? paymentId,
    String? attachmentUrl,
    String? status,
    String? priority,
    String? adminNotes,
    String? resolutionSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) =>
      FirestoreComplaintModel(
        complaintId: complaintId ?? this.complaintId,
        userId: userId ?? this.userId,
        captainId: captainId ?? this.captainId,
        complainantRole: complainantRole ?? this.complainantRole,
        complainantName: complainantName ?? this.complainantName,
        complainantPhone: complainantPhone ?? this.complainantPhone,
        category: category ?? this.category,
        subject: subject ?? this.subject,
        description: description ?? this.description,
        rideId: rideId ?? this.rideId,
        paymentId: paymentId ?? this.paymentId,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        adminNotes: adminNotes ?? this.adminNotes,
        resolutionSummary: resolutionSummary ?? this.resolutionSummary,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'Open';
      case 'IN_REVIEW':
        return 'In Review';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isInReview => status.toUpperCase() == 'IN_REVIEW';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';
  bool get isClosed => status.toUpperCase() == 'CLOSED';
}

class FirestoreComplaintReplyModel {
  final String replyId;
  final String complaintId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'USER', 'CAPTAIN', 'ADMIN'
  final String message;
  final DateTime createdAt;

  const FirestoreComplaintReplyModel({
    required this.replyId,
    required this.complaintId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'replyId': replyId,
    'complaintId': complaintId,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FirestoreComplaintReplyModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreComplaintReplyModel(
        replyId: id ?? (map['replyId'] as String? ?? ''),
        complaintId: map['complaintId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        senderName: map['senderName'] as String? ?? '',
        senderRole: (map['senderRole'] as String? ?? 'CAPTAIN').toUpperCase(),
        message: map['message'] as String? ?? '',
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      );
}

class FirestoreOfferModel {
  final String offerId;
  final String title;
  final String description;
  final String couponCode;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double? maxDiscount;
  final double minimumFare;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? usageLimit;
  final int? perUserLimit;
  final int usedCount;
  final Map<String, int> userUsage;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FirestoreOfferModel({
    required this.offerId,
    required this.title,
    required this.description,
    required this.couponCode,
    this.discountType = 'percentage',
    required this.discountValue,
    this.maxDiscount,
    this.minimumFare = 0.0,
    required this.validFrom,
    required this.validUntil,
    this.usageLimit,
    this.perUserLimit,
    this.usedCount = 0,
    this.userUsage = const {},
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Legacy compatibility getter for discount
  double get discount => discountValue;

  bool get isValid {
    final now = DateTime.now();
    return active && now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  /// Calculates discount for a given fare
  double calculateDiscount(double originalFare) {
    if (originalFare < minimumFare) return 0.0;
    if (discountType == 'fixed') {
      return discountValue.clamp(0.0, originalFare);
    }
    final raw = originalFare * (discountValue / 100.0);
    if (maxDiscount != null) {
      return raw.clamp(0.0, maxDiscount!);
    }
    return raw.clamp(0.0, originalFare);
  }

  Map<String, dynamic> toMap() => {
    'offerId': offerId,
    'title': title,
    'description': description,
    'couponCode': couponCode.toUpperCase(),
    'discountType': discountType,
    'discountValue': discountValue,
    'discount': discountValue, // compatibility
    'maxDiscount': maxDiscount,
    'minimumFare': minimumFare,
    'validFrom': validFrom.toIso8601String(),
    'validUntil': validUntil.toIso8601String(),
    'usageLimit': usageLimit,
    'perUserLimit': perUserLimit,
    'usedCount': usedCount,
    'userUsage': userUsage,
    'active': active,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FirestoreOfferModel.fromMap(Map<String, dynamic> map, {String? id}) {
    Map<String, int> parsedUserUsage = {};
    if (map['userUsage'] != null && map['userUsage'] is Map) {
      (map['userUsage'] as Map).forEach((k, v) {
        if (v is num) {
          parsedUserUsage[k.toString()] = v.toInt();
        }
      });
    }

    final val = (map['discountValue'] as num?)?.toDouble() ??
        (map['discount'] as num?)?.toDouble() ??
        0.0;

    return FirestoreOfferModel(
      offerId: id ?? (map['offerId'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      couponCode: (map['couponCode'] as String? ?? '').toUpperCase(),
      discountType: map['discountType'] as String? ?? 'percentage',
      discountValue: val,
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      minimumFare: (map['minimumFare'] as num?)?.toDouble() ?? 0.0,
      validFrom: _parseSharedDateTime(map['validFrom']) ??
          DateTime.now().subtract(const Duration(days: 1)),
      validUntil: _parseSharedDateTime(map['validUntil']) ??
          DateTime.now().add(const Duration(days: 30)),
      usageLimit: (map['usageLimit'] as num?)?.toInt(),
      perUserLimit: (map['perUserLimit'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
      userUsage: parsedUserUsage,
      active: map['active'] as bool? ?? true,
      createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseSharedDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  FirestoreOfferModel copyWith({
    String? offerId,
    String? title,
    String? description,
    String? couponCode,
    String? discountType,
    double? discountValue,
    double? maxDiscount,
    double? minimumFare,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? perUserLimit,
    int? usedCount,
    Map<String, int>? userUsage,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirestoreOfferModel(
      offerId: offerId ?? this.offerId,
      title: title ?? this.title,
      description: description ?? this.description,
      couponCode: couponCode ?? this.couponCode,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      minimumFare: minimumFare ?? this.minimumFare,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      usedCount: usedCount ?? this.usedCount,
      userUsage: userUsage ?? this.userUsage,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FirestoreNotificationModel {
  final String notificationId;
  final String recipientId;
  final String recipientRole; // 'user' or 'captain'
  final String? userId;
  final String? captainId;
  final String? rideId;
  final String title;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const FirestoreNotificationModel({
    required this.notificationId,
    String? recipientId,
    String? recipientRole,
    this.userId,
    this.captainId,
    this.rideId,
    required this.title,
    required this.message,
    this.type = 'GENERAL',
    this.read = false,
    required this.createdAt,
    this.data,
  })  : recipientId = recipientId ?? (userId ?? captainId ?? ''),
        recipientRole = recipientRole ??
            (captainId != null && captainId != '' && (userId == null || userId == '')
                ? 'captain'
                : 'user');

  Map<String, dynamic> toMap() => {
    'notificationId': notificationId,
    'recipientId': recipientId,
    'recipientRole': recipientRole,
    if (userId != null) 'userId': userId,
    if (captainId != null) 'captainId': captainId,
    if (rideId != null) 'rideId': rideId,
    'title': title,
    'message': message,
    'type': type,
    'read': read,
    'createdAt': createdAt.toIso8601String(),
    if (data != null) 'data': data,
  };

  factory FirestoreNotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final uId = map['userId'] as String?;
    final cId = map['captainId'] as String?;
    final rId = map['recipientId'] as String? ?? (uId ?? cId ?? '');
    final role = map['recipientRole'] as String? ??
        (cId != null && cId.isNotEmpty && (uId == null || uId.isEmpty)
            ? 'captain'
            : 'user');

    return FirestoreNotificationModel(
      notificationId: id ?? (map['notificationId'] as String? ?? ''),
      recipientId: rId,
      recipientRole: role,
      userId: uId,
      captainId: cId,
      rideId: map['rideId'] as String?,
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'GENERAL',
      read: map['read'] as bool? ?? false,
      createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      data: map['data'] != null ? Map<String, dynamic>.from(map['data'] as Map) : null,
    );
  }

  FirestoreNotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? recipientRole,
    String? userId,
    String? captainId,
    String? rideId,
    String? title,
    String? message,
    String? type,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return FirestoreNotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      userId: userId ?? this.userId,
      captainId: captainId ?? this.captainId,
      rideId: rideId ?? this.rideId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}

/// Standardized payment status
enum FirestorePaymentStatus {
  pending,
  processing,
  paid,
  failed,
  cancelled,
  refunded;

  String get firestoreValue {
    switch (this) {
      case FirestorePaymentStatus.pending:
        return 'PENDING';
      case FirestorePaymentStatus.processing:
        return 'PROCESSING';
      case FirestorePaymentStatus.paid:
        return 'PAID';
      case FirestorePaymentStatus.failed:
        return 'FAILED';
      case FirestorePaymentStatus.cancelled:
        return 'CANCELLED';
      case FirestorePaymentStatus.refunded:
        return 'REFUNDED';
    }
  }

  static FirestorePaymentStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'PENDING':
        return FirestorePaymentStatus.pending;
      case 'PROCESSING':
        return FirestorePaymentStatus.processing;
      case 'PAID':
        return FirestorePaymentStatus.paid;
      case 'FAILED':
        return FirestorePaymentStatus.failed;
      case 'CANCELLED':
        return FirestorePaymentStatus.cancelled;
      case 'REFUNDED':
        return FirestorePaymentStatus.refunded;
      default:
        return FirestorePaymentStatus.pending;
    }
  }
}

/// Standardized payment model across QuickRide
class FirestorePaymentModel {
  final String paymentId;
  final String rideId;
  final String userId;
  final String? captainId;
  final double originalFare;
  final double discountAmount;
  final double finalAmount;
  final String currency;
  final String paymentMethod; // 'cash', 'online', 'upi', 'card', 'netbanking'
  final FirestorePaymentStatus paymentStatus;
  final String? gatewayOrderId;
  final String? gatewayPaymentId;
  final String? gatewaySignature;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final String? pickupAddress;
  final String? dropAddress;
  final String? vehicleType;
  final double? distanceKm;
  final String? couponCode;
  final String? passengerName;
  final String? captainName;
  final double? refundAmount;
  final String? refundId;
  final String? refundReason;
  final DateTime? refundedAt;
  final double? cancellationFee;

  const FirestorePaymentModel({
    required this.paymentId,
    required this.rideId,
    required this.userId,
    this.captainId,
    required this.originalFare,
    this.discountAmount = 0.0,
    required this.finalAmount,
    this.currency = 'INR',
    required this.paymentMethod,
    this.paymentStatus = FirestorePaymentStatus.pending,
    this.gatewayOrderId,
    this.gatewayPaymentId,
    this.gatewaySignature,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.pickupAddress,
    this.dropAddress,
    this.vehicleType,
    this.distanceKm,
    this.couponCode,
    this.passengerName,
    this.captainName,
    this.refundAmount,
    this.refundId,
    this.refundReason,
    this.refundedAt,
    this.cancellationFee,
  });

  bool get isPaid => paymentStatus == FirestorePaymentStatus.paid;
  bool get isFailed => paymentStatus == FirestorePaymentStatus.failed;
  bool get isPending => paymentStatus == FirestorePaymentStatus.pending;
  bool get isRefunded => paymentStatus == FirestorePaymentStatus.refunded;
  bool get isCancelled => paymentStatus == FirestorePaymentStatus.cancelled;

  Map<String, dynamic> toMap() => {
    'paymentId': paymentId,
    'rideId': rideId,
    'userId': userId,
    if (captainId != null) 'captainId': captainId,
    'originalFare': originalFare,
    'discountAmount': discountAmount,
    'finalAmount': finalAmount,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus.firestoreValue,
    if (gatewayOrderId != null) 'gatewayOrderId': gatewayOrderId,
    if (gatewayPaymentId != null) 'gatewayPaymentId': gatewayPaymentId,
    if (gatewaySignature != null) 'gatewaySignature': gatewaySignature,
    if (errorMessage != null) 'errorMessage': errorMessage,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
    if (pickupAddress != null) 'pickupAddress': pickupAddress,
    if (dropAddress != null) 'dropAddress': dropAddress,
    if (vehicleType != null) 'vehicleType': vehicleType,
    if (distanceKm != null) 'distanceKm': distanceKm,
    if (couponCode != null) 'couponCode': couponCode,
    if (passengerName != null) 'passengerName': passengerName,
    if (captainName != null) 'captainName': captainName,
    if (refundAmount != null) 'refundAmount': refundAmount,
    if (refundId != null) 'refundId': refundId,
    if (refundReason != null) 'refundReason': refundReason,
    if (refundedAt != null) 'refundedAt': refundedAt!.toIso8601String(),
    if (cancellationFee != null) 'cancellationFee': cancellationFee,
  };

  factory FirestorePaymentModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FirestorePaymentModel(
      paymentId: id ?? (map['paymentId'] as String? ?? ''),
      rideId: map['rideId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      captainId: map['captainId'] as String?,
      originalFare: (map['originalFare'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'INR',
      paymentMethod: map['paymentMethod'] as String? ?? 'online',
      paymentStatus: FirestorePaymentStatus.fromString(map['paymentStatus'] as String? ?? 'PENDING'),
      gatewayOrderId: map['gatewayOrderId'] as String?,
      gatewayPaymentId: map['gatewayPaymentId'] as String?,
      gatewaySignature: map['gatewaySignature'] as String?,
      errorMessage: map['errorMessage'] as String?,
      createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseSharedDateTime(map['updatedAt']) ?? DateTime.now(),
      paidAt: _parseSharedDateTime(map['paidAt']),
      pickupAddress: map['pickupAddress'] as String?,
      dropAddress: map['dropAddress'] as String?,
      vehicleType: map['vehicleType'] as String?,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      couponCode: map['couponCode'] as String?,
      passengerName: map['passengerName'] as String?,
      captainName: map['captainName'] as String?,
      refundAmount: (map['refundAmount'] as num?)?.toDouble(),
      refundId: map['refundId'] as String?,
      refundReason: map['refundReason'] as String?,
      refundedAt: _parseSharedDateTime(map['refundedAt']),
      cancellationFee: (map['cancellationFee'] as num?)?.toDouble(),
    );
  }

  FirestorePaymentModel copyWith({
    String? paymentId,
    String? rideId,
    String? userId,
    String? captainId,
    double? originalFare,
    double? discountAmount,
    double? finalAmount,
    String? currency,
    String? paymentMethod,
    FirestorePaymentStatus? paymentStatus,
    String? gatewayOrderId,
    String? gatewayPaymentId,
    String? gatewaySignature,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    String? pickupAddress,
    String? dropAddress,
    String? vehicleType,
    double? distanceKm,
    String? couponCode,
    String? passengerName,
    String? captainName,
    double? refundAmount,
    String? refundId,
    String? refundReason,
    DateTime? refundedAt,
    double? cancellationFee,
  }) {
    return FirestorePaymentModel(
      paymentId: paymentId ?? this.paymentId,
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      captainId: captainId ?? this.captainId,
      originalFare: originalFare ?? this.originalFare,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      gatewayOrderId: gatewayOrderId ?? this.gatewayOrderId,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      gatewaySignature: gatewaySignature ?? this.gatewaySignature,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      vehicleType: vehicleType ?? this.vehicleType,
      distanceKm: distanceKm ?? this.distanceKm,
      couponCode: couponCode ?? this.couponCode,
      passengerName: passengerName ?? this.passengerName,
      captainName: captainName ?? this.captainName,
      refundAmount: refundAmount ?? this.refundAmount,
      refundId: refundId ?? this.refundId,
      refundReason: refundReason ?? this.refundReason,
      refundedAt: refundedAt ?? this.refundedAt,
      cancellationFee: cancellationFee ?? this.cancellationFee,
    );
  }
}

// ============================================================================
// STEP 40: SAFETY CENTER & EMERGENCY INCIDENT MODELS
// ============================================================================

enum EmergencyStatus {
  active,
  acknowledged,
  resolved,
  closed;

  String get firestoreValue {
    switch (this) {
      case EmergencyStatus.active:
        return 'ACTIVE';
      case EmergencyStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case EmergencyStatus.resolved:
        return 'RESOLVED';
      case EmergencyStatus.closed:
        return 'CLOSED';
    }
  }

  static EmergencyStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACKNOWLEDGED':
        return EmergencyStatus.acknowledged;
      case 'RESOLVED':
        return EmergencyStatus.resolved;
      case 'CLOSED':
        return EmergencyStatus.closed;
      case 'ACTIVE':
      default:
        return EmergencyStatus.active;
    }
  }
}

class FirestoreEmergencyIncidentModel {
  final String emergencyId;
  final String rideId;
  final String userId;
  final String captainId;
  final double latitude;
  final double longitude;
  final EmergencyStatus status;
  final String triggeredBy; // 'USER' or 'CAPTAIN'
  final String? userName;
  final String? userPhone;
  final String? captainName;
  final String? captainPhone;
  final String? vehicleNumber;
  final String? vehicleType;
  final String? pickup;
  final String? destination;
  final String? adminNotes;
  final String? resolutionSummary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const FirestoreEmergencyIncidentModel({
    required this.emergencyId,
    required this.rideId,
    required this.userId,
    required this.captainId,
    required this.latitude,
    required this.longitude,
    this.status = EmergencyStatus.active,
    required this.triggeredBy,
    this.userName,
    this.userPhone,
    this.captainName,
    this.captainPhone,
    this.vehicleNumber,
    this.vehicleType,
    this.pickup,
    this.destination,
    this.adminNotes,
    this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  bool get isActive => status == EmergencyStatus.active;
  bool get isAcknowledged => status == EmergencyStatus.acknowledged;
  bool get isResolved => status == EmergencyStatus.resolved;
  bool get isClosed => status == EmergencyStatus.closed;

  String get statusLabel {
    switch (status) {
      case EmergencyStatus.active:
        return 'ACTIVE';
      case EmergencyStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case EmergencyStatus.resolved:
        return 'RESOLVED';
      case EmergencyStatus.closed:
        return 'CLOSED';
    }
  }

  Map<String, dynamic> toMap() => {
    'emergencyId': emergencyId,
    'rideId': rideId,
    'userId': userId,
    'captainId': captainId,
    'latitude': latitude,
    'longitude': longitude,
    'status': status.firestoreValue,
    'triggeredBy': triggeredBy,
    if (userName != null) 'userName': userName,
    if (userPhone != null) 'userPhone': userPhone,
    if (captainName != null) 'captainName': captainName,
    if (captainPhone != null) 'captainPhone': captainPhone,
    if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
    if (vehicleType != null) 'vehicleType': vehicleType,
    if (pickup != null) 'pickup': pickup,
    if (destination != null) 'destination': destination,
    if (adminNotes != null) 'adminNotes': adminNotes,
    if (resolutionSummary != null) 'resolutionSummary': resolutionSummary,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (resolvedAt != null) 'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory FirestoreEmergencyIncidentModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreEmergencyIncidentModel(
        emergencyId: id ?? (map['emergencyId'] as String? ?? ''),
        rideId: map['rideId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        captainId: map['captainId'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
        status: EmergencyStatus.fromString(map['status'] as String?),
        triggeredBy: (map['triggeredBy'] as String? ?? 'USER').toUpperCase(),
        userName: map['userName'] as String?,
        userPhone: map['userPhone'] as String?,
        captainName: map['captainName'] as String?,
        captainPhone: map['captainPhone'] as String?,
        vehicleNumber: map['vehicleNumber'] as String?,
        vehicleType: map['vehicleType'] as String?,
        pickup: map['pickup'] as String?,
        destination: map['destination'] as String?,
        adminNotes: map['adminNotes'] as String?,
        resolutionSummary: map['resolutionSummary'] as String?,
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseSharedDateTime(map['updatedAt']) ?? DateTime.now(),
        resolvedAt: _parseSharedDateTime(map['resolvedAt']),
      );

  FirestoreEmergencyIncidentModel copyWith({
    String? emergencyId,
    String? rideId,
    String? userId,
    String? captainId,
    double? latitude,
    double? longitude,
    EmergencyStatus? status,
    String? triggeredBy,
    String? userName,
    String? userPhone,
    String? captainName,
    String? captainPhone,
    String? vehicleNumber,
    String? vehicleType,
    String? pickup,
    String? destination,
    String? adminNotes,
    String? resolutionSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return FirestoreEmergencyIncidentModel(
      emergencyId: emergencyId ?? this.emergencyId,
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      captainId: captainId ?? this.captainId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      captainName: captainName ?? this.captainName,
      captainPhone: captainPhone ?? this.captainPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      adminNotes: adminNotes ?? this.adminNotes,
      resolutionSummary: resolutionSummary ?? this.resolutionSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

class FirestoreEmergencyContactModel {
  final String contactId;
  final String ownerId;
  final String name;
  final String phone;
  final String? relationship;
  final DateTime createdAt;

  const FirestoreEmergencyContactModel({
    required this.contactId,
    required this.ownerId,
    required this.name,
    required this.phone,
    this.relationship,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'contactId': contactId,
    'ownerId': ownerId,
    'name': name,
    'phone': phone,
    if (relationship != null) 'relationship': relationship,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FirestoreEmergencyContactModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreEmergencyContactModel(
        contactId: id ?? (map['contactId'] as String? ?? ''),
        ownerId: map['ownerId'] as String? ?? (map['userId'] as String? ?? ''),
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        relationship: map['relationship'] as String?,
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
      );

  FirestoreEmergencyContactModel copyWith({
    String? contactId,
    String? ownerId,
    String? name,
    String? phone,
    String? relationship,
    DateTime? createdAt,
  }) {
    return FirestoreEmergencyContactModel(
      contactId: contactId ?? this.contactId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FirestoreChatMessageModel {
  final String messageId;
  final String rideId;
  final String senderId;
  final String senderRole; // 'USER', 'CAPTAIN', 'ADMIN'
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool read;

  const FirestoreChatMessageModel({
    required this.messageId,
    required this.rideId,
    required this.senderId,
    required this.senderRole,
    this.senderName = '',
    required this.message,
    required this.createdAt,
    this.read = false,
  });

  bool get isFromUser => senderRole.toUpperCase() == 'USER';
  bool get isFromCaptain => senderRole.toUpperCase() == 'CAPTAIN';
  bool get isFromAdmin => senderRole.toUpperCase() == 'ADMIN';

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    'rideId': rideId,
    'senderId': senderId,
    'senderRole': senderRole,
    if (senderName.isNotEmpty) 'senderName': senderName,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory FirestoreChatMessageModel.fromMap(Map<String, dynamic> map, {String? id}) =>
      FirestoreChatMessageModel(
        messageId: id ?? (map['messageId'] as String? ?? ''),
        rideId: map['rideId'] as String? ?? '',
        senderId: map['senderId'] as String? ?? '',
        senderRole: (map['senderRole'] as String? ?? 'USER').toUpperCase(),
        senderName: map['senderName'] as String? ?? '',
        message: map['message'] as String? ?? '',
        createdAt: _parseSharedDateTime(map['createdAt']) ?? DateTime.now(),
        read: map['read'] as bool? ?? false,
      );

  FirestoreChatMessageModel copyWith({
    String? messageId,
    String? rideId,
    String? senderId,
    String? senderRole,
    String? senderName,
    String? message,
    DateTime? createdAt,
    bool? read,
  }) =>
      FirestoreChatMessageModel(
        messageId: messageId ?? this.messageId,
        rideId: rideId ?? this.rideId,
        senderId: senderId ?? this.senderId,
        senderRole: senderRole ?? this.senderRole,
        senderName: senderName ?? this.senderName,
        message: message ?? this.message,
        createdAt: createdAt ?? this.createdAt,
        read: read ?? this.read,
      );
}


