import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/firestore_models.dart';
import 'captain_firebase_service.dart';
import 'captain_state_service.dart';

class CaptainStorageResult {
  final bool success;
  final String? downloadUrl;
  final String? errorMessage;
  final bool isOfflineFallback;

  const CaptainStorageResult({
    required this.success,
    this.downloadUrl,
    this.errorMessage,
    this.isOfflineFallback = false,
  });
}

class CaptainStorageService {
  static final CaptainStorageService _instance = CaptainStorageService._internal();
  factory CaptainStorageService() => _instance;
  CaptainStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('[CaptainStorageService] Error picking image: $e');
      return null;
    }
  }

  /// Upload captain profile photo to captains/{captainId}/profile/
  Future<CaptainStorageResult> uploadProfilePhoto({
    required String captainId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadImage(
      captainId: captainId,
      subfolder: 'profile',
      file: file,
      onProgress: onProgress,
      isVehicle: false,
    );
  }

  /// Upload captain vehicle photo to captains/{captainId}/vehicle/
  Future<CaptainStorageResult> uploadVehiclePhoto({
    required String captainId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadImage(
      captainId: captainId,
      subfolder: 'vehicle',
      file: file,
      onProgress: onProgress,
      isVehicle: true,
    );
  }

  /// Upload captain driving license document to captains/{captainId}/documents/
  Future<CaptainStorageResult> uploadLicenseDocument({
    required String captainId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadDocument(
      captainId: captainId,
      docType: 'license',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Upload captain vehicle registration / RC document to captains/{captainId}/documents/
  Future<CaptainStorageResult> uploadVehicleDocument({
    required String captainId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadDocument(
      captainId: captainId,
      docType: 'rc',
      file: file,
      onProgress: onProgress,
    );
  }

  Future<CaptainStorageResult> _uploadDocument({
    required String captainId,
    required String docType,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final firebaseService = CaptainFirebaseService();

      if (firebaseService.isFirebaseAvailable) {
        final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
        final fileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = 'captains/$captainId/documents/$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(progress);
          }
        });

        final TaskSnapshot completedSnapshot = await uploadTask;
        final String downloadUrl = await completedSnapshot.ref.getDownloadURL();

        debugPrint('[CaptainStorageService] Uploaded $docType successfully: $downloadUrl');
        return CaptainStorageResult(success: true, downloadUrl: downloadUrl);
      } else {
        debugPrint('[CaptainStorageService] Offline fallback: $docType document');
        onProgress?.call(0.3);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(0.7);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(1.0);

        final fallbackUrl = docType == 'license'
            ? 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=600&q=80'
            : 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?auto=format&fit=crop&w=600&q=80';

        return CaptainStorageResult(
          success: true,
          downloadUrl: fallbackUrl,
          isOfflineFallback: true,
        );
      }
    } catch (e) {
      debugPrint('[CaptainStorageService] $docType upload error: $e');
      return CaptainStorageResult(success: false, errorMessage: e.toString());
    }
  }

  /// Upload complaint attachment to complaints/{captainId}/{complaintId}/{filename}
  Future<CaptainStorageResult> uploadComplaintAttachment({
    required String captainId,
    required String complaintId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final firebaseService = CaptainFirebaseService();

      if (firebaseService.isFirebaseAvailable) {
        final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = 'complaints/$captainId/$complaintId/$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(progress);
          }
        });

        final TaskSnapshot completedSnapshot = await uploadTask;
        final String downloadUrl = await completedSnapshot.ref.getDownloadURL();

        debugPrint('[CaptainStorageService] Complaint attachment uploaded: $downloadUrl');
        return CaptainStorageResult(success: true, downloadUrl: downloadUrl);
      } else {
        debugPrint('[CaptainStorageService] Offline fallback: simulating complaint attachment upload');
        onProgress?.call(0.3);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(0.7);
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(1.0);

        const fallbackUrl = 'https://images.unsplash.com/photo-1590674899484-d5640e854abe?auto=format&fit=crop&w=600&q=80';
        return const CaptainStorageResult(
          success: true,
          downloadUrl: fallbackUrl,
          isOfflineFallback: true,
        );
      }
    } catch (e) {
      debugPrint('[CaptainStorageService] Complaint attachment upload error: $e');
      return CaptainStorageResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<CaptainStorageResult> _uploadImage({
    required String captainId,
    required String subfolder,
    required XFile file,
    required bool isVehicle,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final firebaseService = CaptainFirebaseService();

      if (firebaseService.isFirebaseAvailable) {
        final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final storagePath = 'captains/$captainId/$subfolder/$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(storagePath);
        final uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress?.call(progress);
          }
        });

        final TaskSnapshot completedSnapshot = await uploadTask;
        final String downloadUrl = await completedSnapshot.ref.getDownloadURL();

        _updateStateAndSync(captainId, downloadUrl, isVehicle: isVehicle);

        debugPrint('[CaptainStorageService] Uploaded $subfolder successfully: $downloadUrl');
        return CaptainStorageResult(success: true, downloadUrl: downloadUrl);
      } else {
        // Fallback simulation
        debugPrint('[CaptainStorageService] Firebase Storage offline fallback mode');
        onProgress?.call(0.3);
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress?.call(0.7);
        await Future.delayed(const Duration(milliseconds: 150));
        onProgress?.call(1.0);

        final fallbackUrl = isVehicle
            ? 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc?auto=format&fit=crop&w=600&q=80'
            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';

        _updateStateAndSync(captainId, fallbackUrl, isVehicle: isVehicle);

        return CaptainStorageResult(
          success: true,
          downloadUrl: fallbackUrl,
          isOfflineFallback: true,
        );
      }
    } catch (e) {
      debugPrint('[CaptainStorageService] Upload error: $e');
      return CaptainStorageResult(success: false, errorMessage: e.toString());
    }
  }

  void _updateStateAndSync(String captainId, String url, {required bool isVehicle}) {
    final stateService = CaptainStateService();
    final currentAccount = stateService.account;
    final updated = isVehicle
        ? currentAccount.copyWith(vehicleImageUrl: url)
        : currentAccount.copyWith(profileImageUrl: url);

    stateService.updateAccount(updated);

    // Sync to Firestore if available
    CaptainFirebaseService().syncCaptainProfile(
      FirestoreCaptainModel(
        captainId: updated.id,
        name: updated.name,
        phone: updated.phone,
        email: updated.email,
        vehicleNumber: updated.vehicleNumber,
        vehicleType: updated.vehicleType,
        drivingLicenseNumber: updated.licenseNumber,
        rating: updated.rating,
        online: updated.isOnline,
        profileImage: updated.profileImageUrl,
        vehicleImage: updated.vehicleImageUrl,
        createdAt: DateTime.now(),
      ),
    );
  }
}
