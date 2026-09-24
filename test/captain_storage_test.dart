import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickride_captain/services/captain_storage_service.dart';
import 'package:quickride_captain/services/captain_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Captain Storage Service Tests', () {
    test('CaptainStorageService singleton instance is consistent', () {
      final s1 = CaptainStorageService();
      final s2 = CaptainStorageService();
      expect(identical(s1, s2), isTrue);
    });

    test('uploadProfilePhoto handles offline fallback, reports progress, and updates account', () async {
      final service = CaptainStorageService();
      final state = CaptainStateService();

      double recordedProgress = 0.0;
      final dummyFile = XFile.fromData(
        Uint8List.fromList([10, 20, 30, 40]),
        name: 'captain_profile.jpg',
      );

      final result = await service.uploadProfilePhoto(
        captainId: state.account.id,
        file: dummyFile,
        onProgress: (progress) {
          recordedProgress = progress;
        },
      );

      expect(result.success, isTrue);
      expect(result.isOfflineFallback, isTrue);
      expect(result.downloadUrl, isNotNull);
      expect(recordedProgress, equals(1.0));
      expect(state.account.profileImageUrl, equals(result.downloadUrl));
    });

    test('uploadVehiclePhoto handles offline fallback, reports progress, and updates account', () async {
      final service = CaptainStorageService();
      final state = CaptainStateService();

      double recordedProgress = 0.0;
      final dummyFile = XFile.fromData(
        Uint8List.fromList([50, 60, 70, 80]),
        name: 'vehicle_photo.png',
      );

      final result = await service.uploadVehiclePhoto(
        captainId: state.account.id,
        file: dummyFile,
        onProgress: (progress) {
          recordedProgress = progress;
        },
      );

      expect(result.success, isTrue);
      expect(result.isOfflineFallback, isTrue);
      expect(result.downloadUrl, isNotNull);
      expect(recordedProgress, equals(1.0));
      expect(state.account.vehicleImageUrl, equals(result.downloadUrl));
    });
  });
}
