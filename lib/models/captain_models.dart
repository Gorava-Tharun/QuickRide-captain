import 'dart:convert';

/// Captain Ride States defined for Step 26 & 27
enum CaptainRideState {
  idle,
  requestReceived,
  accepted,
  navigatingToPickup,
  arrivedAtPickup,
  rideInProgress,
  completed,
}

class CaptainAccount {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final double rating;
  final int totalRides;
  final double todayEarnings;
  final bool isOnline;
  final String? profileImageUrl;
  final String? vehicleImageUrl;
  final String verificationStatus;
  final String vehicleVerificationStatus;
  final DateTime? documentsSubmittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final String? drivingLicenseImageUrl;
  final String? vehicleDocumentImageUrl;

  bool get isApproved => verificationStatus == 'APPROVED';
  bool get isPending => verificationStatus == 'PENDING';
  bool get isRejected => verificationStatus == 'REJECTED';

  const CaptainAccount({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    this.vehicleType = 'Bike (QuickRide)',
    required this.vehicleNumber,
    required this.licenseNumber,
    this.rating = 4.9,
    this.totalRides = 0,
    this.todayEarnings = 0.0,
    this.isOnline = true,
    this.profileImageUrl,
    this.vehicleImageUrl,
    this.verificationStatus = 'APPROVED',
    this.vehicleVerificationStatus = 'APPROVED',
    this.documentsSubmittedAt,
    this.verifiedAt,
    this.rejectionReason,
    this.drivingLicenseImageUrl,
    this.vehicleDocumentImageUrl,
  });

  CaptainAccount copyWith({
    String? name,
    String? phone,
    String? email,
    String? password,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    double? rating,
    int? totalRides,
    double? todayEarnings,
    bool? isOnline,
    String? profileImageUrl,
    String? vehicleImageUrl,
    String? verificationStatus,
    String? vehicleVerificationStatus,
    DateTime? documentsSubmittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    String? drivingLicenseImageUrl,
    String? vehicleDocumentImageUrl,
  }) {
    return CaptainAccount(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      isOnline: isOnline ?? this.isOnline,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      vehicleVerificationStatus: vehicleVerificationStatus ?? this.vehicleVerificationStatus,
      documentsSubmittedAt: documentsSubmittedAt ?? this.documentsSubmittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      drivingLicenseImageUrl: drivingLicenseImageUrl ?? this.drivingLicenseImageUrl,
      vehicleDocumentImageUrl: vehicleDocumentImageUrl ?? this.vehicleDocumentImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'rating': rating,
      'totalRides': totalRides,
      'todayEarnings': todayEarnings,
      'isOnline': isOnline,
      'profileImageUrl': profileImageUrl,
      'vehicleImageUrl': vehicleImageUrl,
      'verificationStatus': verificationStatus,
      'vehicleVerificationStatus': vehicleVerificationStatus,
      'documentsSubmittedAt': documentsSubmittedAt?.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'drivingLicenseImageUrl': drivingLicenseImageUrl,
      'vehicleDocumentImageUrl': vehicleDocumentImageUrl,
    };
  }

  factory CaptainAccount.fromMap(Map<String, dynamic> map) {
    return CaptainAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Bike (QuickRide)',
      vehicleNumber: map['vehicleNumber'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      totalRides: (map['totalRides'] as num?)?.toInt() ?? 0,
      todayEarnings: (map['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      isOnline: map['isOnline'] ?? true,
      profileImageUrl: map['profileImageUrl'] as String?,
      vehicleImageUrl: map['vehicleImageUrl'] as String?,
      verificationStatus: map['verificationStatus'] as String? ?? 'APPROVED',
      vehicleVerificationStatus: map['vehicleVerificationStatus'] as String? ?? 'APPROVED',
      documentsSubmittedAt: map['documentsSubmittedAt'] != null
          ? DateTime.tryParse(map['documentsSubmittedAt'].toString())
          : null,
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.tryParse(map['verifiedAt'].toString())
          : null,
      rejectionReason: map['rejectionReason'] as String?,
      drivingLicenseImageUrl: (map['drivingLicenseImageUrl'] ?? map['licenseDocumentUrl']) as String?,
      vehicleDocumentImageUrl: (map['vehicleDocumentImageUrl'] ?? map['vehicleRcImageUrl']) as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CaptainAccount.fromJson(String source) => CaptainAccount.fromMap(json.decode(source));
}

class RideRequestItem {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final double passengerRating;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropAddress;
  final double dropLatitude;
  final double dropLongitude;
  final double distanceKm;
  final int estimatedMinutes;
  final String vehicleType;
  final double estimatedFare;
  final String paymentMode;

  const RideRequestItem({
    required this.id,
    this.passengerId = 'user_quickride_01',
    required this.passengerName,
    this.passengerPhone = '+91 98450 11223',
    required this.passengerRating,
    required this.pickupAddress,
    this.pickupLatitude = 12.9780,
    this.pickupLongitude = 77.6000,
    required this.dropAddress,
    this.dropLatitude = 12.9850,
    this.dropLongitude = 77.6100,
    required this.distanceKm,
    this.estimatedMinutes = 14,
    this.vehicleType = 'QuickRide Bike',
    required this.estimatedFare,
    this.paymentMode = 'Cash / UPI',
  });
}

class CompletedRideRecord {
  final String id;
  final String passengerName;
  final String passengerPhone;
  final String pickupAddress;
  final String dropAddress;
  final String vehicleType;
  final double fare;
  final double distanceKm;
  final int durationSeconds;
  final DateTime completionTime;
  final String? userId;
  final String? rideId;
  final bool isRated;
  final int? rating;
  final String? reviewText;

  final String? paymentStatus;
  final String? paymentMethod;
  final double discount;
  final double? originalFare;
  final double? customCaptainEarning;
  final double? customPlatformFee;

  double get effectiveFinalFare => fare;
  double get effectiveOriginalFare => originalFare ?? (fare + discount);
  double get captainEarning => customCaptainEarning ?? (fare * 0.85);
  double get platformFee => customPlatformFee ?? (fare * 0.15);
  bool get isPaid => paymentStatus?.toUpperCase() == 'PAID';

  const CompletedRideRecord({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.vehicleType,
    required this.fare,
    required this.distanceKm,
    required this.durationSeconds,
    required this.completionTime,
    this.userId,
    this.rideId,
    this.isRated = false,
    this.rating,
    this.reviewText,
    this.paymentStatus = 'PAID',
    this.paymentMethod = 'Online / Cash',
    this.discount = 0.0,
    this.originalFare,
    this.customCaptainEarning,
    this.customPlatformFee,
  });

  CompletedRideRecord copyWith({
    String? id,
    String? passengerName,
    String? passengerPhone,
    String? pickupAddress,
    String? dropAddress,
    String? vehicleType,
    double? fare,
    double? distanceKm,
    int? durationSeconds,
    DateTime? completionTime,
    String? userId,
    String? rideId,
    bool? isRated,
    int? rating,
    String? reviewText,
    String? paymentStatus,
    String? paymentMethod,
    double? discount,
    double? originalFare,
    double? customCaptainEarning,
    double? customPlatformFee,
  }) {
    return CompletedRideRecord(
      id: id ?? this.id,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropAddress: dropAddress ?? this.dropAddress,
      vehicleType: vehicleType ?? this.vehicleType,
      fare: fare ?? this.fare,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completionTime: completionTime ?? this.completionTime,
      userId: userId ?? this.userId,
      rideId: rideId ?? this.rideId,
      isRated: isRated ?? this.isRated,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      originalFare: originalFare ?? this.originalFare,
      customCaptainEarning: customCaptainEarning ?? this.customCaptainEarning,
      customPlatformFee: customPlatformFee ?? this.customPlatformFee,
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '$minutes min ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'vehicleType': vehicleType,
      'fare': fare,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'completionTime': completionTime.toIso8601String(),
      'userId': userId,
      'rideId': rideId,
      'isRated': isRated,
      'rating': rating,
      'reviewText': reviewText,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'discount': discount,
      if (originalFare != null) 'originalFare': originalFare,
      'captainEarning': captainEarning,
      'platformFee': platformFee,
    };
  }

  factory CompletedRideRecord.fromMap(Map<String, dynamic> map) {
    final fareVal = (map['fare'] as num?)?.toDouble() ?? 0.0;
    return CompletedRideRecord(
      id: map['id'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      dropAddress: map['dropAddress'] ?? '',
      vehicleType: map['vehicleType'] ?? 'QuickRide Bike',
      fare: fareVal,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      completionTime: DateTime.tryParse(map['completionTime']?.toString() ?? '') ?? DateTime.now(),
      userId: map['userId'] as String?,
      rideId: map['rideId'] as String?,
      isRated: map['isRated'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toInt(),
      reviewText: map['reviewText'] as String?,
      paymentStatus: map['paymentStatus'] as String? ?? 'PAID',
      paymentMethod: map['paymentMethod'] as String? ?? 'Online / Cash',
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      originalFare: (map['originalFare'] as num?)?.toDouble(),
      customCaptainEarning: (map['captainEarning'] as num?)?.toDouble(),
      customPlatformFee: (map['platformFee'] as num?)?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory CompletedRideRecord.fromJson(String source) =>
      CompletedRideRecord.fromMap(json.decode(source));
}
