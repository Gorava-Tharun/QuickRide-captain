import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../../services/captain_state_service.dart';
import '../../services/captain_storage_service.dart';

class CaptainVerificationScreen extends StatefulWidget {
  const CaptainVerificationScreen({super.key});

  @override
  State<CaptainVerificationScreen> createState() =>
      _CaptainVerificationScreenState();
}

class _CaptainVerificationScreenState extends State<CaptainVerificationScreen> {
  final _storageService = CaptainStorageService();

  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _licenseNumberController;

  String? _licenseImageUrl;
  String? _vehicleDocImageUrl;
  String? _vehicleImageUrl;

  bool _isUploadingLicense = false;
  double _licenseProgress = 0.0;

  bool _isUploadingVehicleDoc = false;
  double _vehicleDocProgress = 0.0;

  bool _isUploadingVehiclePhoto = false;
  double _vehiclePhotoProgress = 0.0;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final account = CaptainStateService().account;
    _vehicleTypeController = TextEditingController(text: account.vehicleType);
    _vehicleNumberController =
        TextEditingController(text: account.vehicleNumber);
    _licenseNumberController =
        TextEditingController(text: account.licenseNumber);

    _licenseImageUrl = account.drivingLicenseImageUrl;
    _vehicleDocImageUrl = account.vehicleDocumentImageUrl;
    _vehicleImageUrl = account.vehicleImageUrl;
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _handlePickAndUploadLicense(String captainId) async {
    final image = await _storageService.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingLicense = true;
      _licenseProgress = 0.0;
    });

    final result = await _storageService.uploadLicenseDocument(
      captainId: captainId,
      file: image,
      onProgress: (progress) {
        if (mounted) setState(() => _licenseProgress = progress);
      },
    );

    if (mounted) {
      setState(() {
        _isUploadingLicense = false;
        if (result.success && result.downloadUrl != null) {
          _licenseImageUrl = result.downloadUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isOfflineFallback
                ? 'License document uploaded (Local Mode)'
                : 'License document uploaded to Cloud Storage!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePickAndUploadVehicleDoc(String captainId) async {
    final image = await _storageService.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingVehicleDoc = true;
      _vehicleDocProgress = 0.0;
    });

    final result = await _storageService.uploadVehicleDocument(
      captainId: captainId,
      file: image,
      onProgress: (progress) {
        if (mounted) setState(() => _vehicleDocProgress = progress);
      },
    );

    if (mounted) {
      setState(() {
        _isUploadingVehicleDoc = false;
        if (result.success && result.downloadUrl != null) {
          _vehicleDocImageUrl = result.downloadUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isOfflineFallback
                ? 'Vehicle RC document uploaded (Local Mode)'
                : 'Vehicle RC document uploaded to Cloud Storage!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePickAndUploadVehiclePhoto(String captainId) async {
    final image = await _storageService.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingVehiclePhoto = true;
      _vehiclePhotoProgress = 0.0;
    });

    final result = await _storageService.uploadVehiclePhoto(
      captainId: captainId,
      file: image,
      onProgress: (progress) {
        if (mounted) setState(() => _vehiclePhotoProgress = progress);
      },
    );

    if (mounted) {
      setState(() {
        _isUploadingVehiclePhoto = false;
        if (result.success && result.downloadUrl != null) {
          _vehicleImageUrl = result.downloadUrl;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isOfflineFallback
                ? 'Vehicle photo uploaded (Local Mode)'
                : 'Vehicle photo uploaded to Cloud Storage!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePreviewDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(32),
                  color: AppColors.surfaceDark,
                  child: const Text('Unable to load document image',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_licenseNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your driving license number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_vehicleNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your vehicle plate number.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await CaptainStateService().submitVerificationDocuments(
      licenseImageUrl: _licenseImageUrl,
      vehicleDocumentImageUrl: _vehicleDocImageUrl,
      vehicleImageUrl: _vehicleImageUrl,
      vehicleType: _vehicleTypeController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim(),
      licenseNumber: _licenseNumberController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.onlineGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Documents submitted successfully! Awaiting Admin review.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceDark,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CaptainStateService(),
      builder: (context, _) {
        final account = CaptainStateService().account;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text('Documents & Verification'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(account),
                const SizedBox(height: AppDimensions.space20),
                const Text(
                  'Required Documents',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upload clear photos of your Driving License and Vehicle Registration Certificate (RC).',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // 1. Driving License Upload Card
                _buildDocumentCard(
                  title: 'Driving License (DL)',
                  subtitle: 'Official government-issued driving license',
                  icon: Icons.badge_outlined,
                  imageUrl: _licenseImageUrl ?? account.drivingLicenseImageUrl,
                  isUploading: _isUploadingLicense,
                  progress: _licenseProgress,
                  onUpload: () => _handlePickAndUploadLicense(account.id),
                  onPreview: (url) =>
                      _showImagePreviewDialog(url, 'Driving License Document'),
                ),
                const SizedBox(height: AppDimensions.space14),

                // 2. Vehicle RC Document Card
                _buildDocumentCard(
                  title: 'Vehicle Document (RC)',
                  subtitle: 'Registration certificate matching your vehicle',
                  icon: Icons.description_outlined,
                  imageUrl:
                      _vehicleDocImageUrl ?? account.vehicleDocumentImageUrl,
                  isUploading: _isUploadingVehicleDoc,
                  progress: _vehicleDocProgress,
                  onUpload: () => _handlePickAndUploadVehicleDoc(account.id),
                  onPreview: (url) =>
                      _showImagePreviewDialog(url, 'Vehicle RC Document'),
                ),
                const SizedBox(height: AppDimensions.space14),

                // 3. Vehicle Photo Card
                _buildDocumentCard(
                  title: 'Vehicle Photo',
                  subtitle: 'Clear front view showing license plate',
                  icon: Icons.two_wheeler_rounded,
                  imageUrl: _vehicleImageUrl ?? account.vehicleImageUrl,
                  isUploading: _isUploadingVehiclePhoto,
                  progress: _vehiclePhotoProgress,
                  onUpload: () => _handlePickAndUploadVehiclePhoto(account.id),
                  onPreview: (url) =>
                      _showImagePreviewDialog(url, 'Vehicle Photo'),
                ),
                const SizedBox(height: AppDimensions.space24),

                const Text(
                  'Vehicle & License Information',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Editable details
                _buildTextField(
                  controller: _vehicleTypeController,
                  label: 'Vehicle Type',
                  hint: 'e.g. Honda Activa 6G (Bike)',
                  icon: Icons.two_wheeler_rounded,
                ),
                const SizedBox(height: AppDimensions.space12),

                _buildTextField(
                  controller: _vehicleNumberController,
                  label: 'Vehicle Plate Number',
                  hint: 'e.g. KA-05-HA-1234',
                  icon: Icons.confirmation_number_outlined,
                ),
                const SizedBox(height: AppDimensions.space12),

                _buildTextField(
                  controller: _licenseNumberController,
                  label: 'Driving License Number',
                  hint: 'e.g. DL-KA0520210009876',
                  icon: Icons.assignment_ind_outlined,
                ),
                const SizedBox(height: AppDimensions.space28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Submit Documents for Verification',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(CaptainAccount account) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String statusTitle;
    String statusDesc;

    if (account.isApproved) {
      bg = const Color(0xFF0D251D);
      border = AppColors.onlineGreen.withValues(alpha: 0.6);
      text = AppColors.onlineGreen;
      icon = Icons.verified_user_rounded;
      statusTitle = 'VERIFIED PARTNER';
      statusDesc =
          'Your driving license and vehicle documents are approved by Admin. You are cleared to take rides.';
    } else if (account.isRejected) {
      bg = const Color(0xFF2C1414);
      border = const Color(0xFFEF4444).withValues(alpha: 0.6);
      text = const Color(0xFFEF4444);
      icon = Icons.highlight_off_rounded;
      statusTitle = 'VERIFICATION REJECTED';
      final reason = account.rejectionReason ?? 'Documents not valid or clear';
      statusDesc =
          'Reason: $reason. Please re-upload valid documents and resubmit.';
    } else {
      bg = const Color(0xFF291F0A);
      border = Colors.amberAccent.withValues(alpha: 0.6);
      text = Colors.amberAccent;
      icon = Icons.hourglass_top_rounded;
      statusTitle = 'VERIFICATION PENDING';
      statusDesc =
          'Your documents are under review by QuickRide Admin. Once approved, you can toggle duty to Online.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: text, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: const TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (account.documentsSubmittedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Submitted: ${account.documentsSubmittedAt!.day}/${account.documentsSubmittedAt!.month}/${account.documentsSubmittedAt!.year}',
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? imageUrl,
    required bool isUploading,
    required double progress,
    required VoidCallback onUpload,
    required void Function(String url) onPreview,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: hasImage ? () => onPreview(imageUrl) : onUpload,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(icon, color: AppColors.primary, size: 30),
                      )
                    : Icon(icon, color: AppColors.primary, size: 30),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasImage ? 'Document uploaded' : subtitle,
                  style: TextStyle(
                    color: hasImage
                        ? AppColors.onlineGreen
                        : AppColors.textSecondaryDark,
                    fontSize: 12,
                    fontWeight:
                        hasImage ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUploading)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: progress > 0 ? progress : null,
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: Icon(
                hasImage ? Icons.refresh_rounded : Icons.upload_file_rounded,
                size: 16,
              ),
              label: Text(hasImage ? 'Change' : 'Upload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: AppColors.textSecondaryDark, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
