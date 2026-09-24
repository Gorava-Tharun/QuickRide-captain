import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/captain_state_service.dart';
import '../../services/captain_storage_service.dart';

class CaptainEditProfileScreen extends StatefulWidget {
  const CaptainEditProfileScreen({super.key});

  @override
  State<CaptainEditProfileScreen> createState() => _CaptainEditProfileScreenState();
}

class _CaptainEditProfileScreenState extends State<CaptainEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storageService = CaptainStorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _licenseController;

  String _selectedVehicleType = 'Honda Activa 6G (Bike)';
  static const List<String> _vehicleTypes = [
    'Honda Activa 6G (Bike)',
    'Bajaj RE (Auto)',
    'Maruti Suzuki WagonR (Economy)',
    'Hyundai Aura (Premium Sedan)',
  ];

  bool _isUploadingProfile = false;
  double _profileProgress = 0.0;
  bool _isUploadingVehicle = false;
  double _vehicleProgress = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final account = CaptainStateService().account;
    _nameController = TextEditingController(text: account.name);
    _phoneController = TextEditingController(text: account.phone);
    _emailController = TextEditingController(text: account.email);
    _vehicleNumberController = TextEditingController(text: account.vehicleNumber);
    _licenseController = TextEditingController(text: account.licenseNumber);

    if (_vehicleTypes.contains(account.vehicleType)) {
      _selectedVehicleType = account.vehicleType;
    } else {
      // Find matching or default
      final match = _vehicleTypes.firstWhere(
        (t) => t.toLowerCase().contains(account.vehicleType.toLowerCase()) ||
               account.vehicleType.toLowerCase().contains(t.toLowerCase()),
        orElse: () => _vehicleTypes.first,
      );
      _selectedVehicleType = match;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _handlePickProfilePhoto() async {
    final account = CaptainStateService().account;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),
              if (account.profileImageUrl != null && account.profileImageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: AppColors.primary),
                  title: const Text('View Current Photo', style: TextStyle(color: AppColors.textPrimaryDark)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImagePreviewDialog(account.profileImageUrl!, 'Profile Photo');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPickedImage(ImageSource.gallery, isVehicle: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take a Photo', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPickedImage(ImageSource.camera, isVehicle: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePickVehiclePhoto() async {
    final account = CaptainStateService().account;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vehicle Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 16),
              if (account.vehicleImageUrl != null && account.vehicleImageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.fullscreen_rounded, color: AppColors.primary),
                  title: const Text('View Current Photo', style: TextStyle(color: AppColors.textPrimaryDark)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showImagePreviewDialog(account.vehicleImageUrl!, 'Vehicle Photo');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPickedImage(ImageSource.gallery, isVehicle: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Take a Photo', style: TextStyle(color: AppColors.textPrimaryDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _processPickedImage(ImageSource.camera, isVehicle: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPickedImage(ImageSource source, {required bool isVehicle}) async {
    final XFile? pickedFile = await _storageService.pickImage(source: source);
    if (pickedFile == null || !mounted) return;

    final confirmed = await _showImagePreviewConfirmationDialog(pickedFile, isVehicle: isVehicle);
    if (confirmed != true || !mounted) return;

    final captainId = CaptainStateService().account.id;
    if (isVehicle) {
      setState(() {
        _isUploadingVehicle = true;
        _vehicleProgress = 0.0;
      });
      final result = await _storageService.uploadVehiclePhoto(
        captainId: captainId,
        file: pickedFile,
        onProgress: (p) {
          if (mounted) setState(() => _vehicleProgress = p);
        },
      );
      if (mounted) {
        setState(() => _isUploadingVehicle = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isOfflineFallback
                  ? 'Vehicle photo updated (Local Mode)'
                  : 'Vehicle photo uploaded to Cloud Storage!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      setState(() {
        _isUploadingProfile = true;
        _profileProgress = 0.0;
      });
      final result = await _storageService.uploadProfilePhoto(
        captainId: captainId,
        file: pickedFile,
        onProgress: (p) {
          if (mounted) setState(() => _profileProgress = p);
        },
      );
      if (mounted) {
        setState(() => _isUploadingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isOfflineFallback
                  ? 'Profile photo updated (Local Mode)'
                  : 'Profile photo uploaded to Cloud Storage!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool?> _showImagePreviewConfirmationDialog(XFile file, {required bool isVehicle}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: Text(
          isVehicle ? 'Preview Vehicle Photo' : 'Preview Profile Photo',
          style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: SizedBox(
                width: 240,
                height: 200,
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.cover)
                    : Image.file(File(file.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isVehicle
                  ? 'Would you like to upload this vehicle photo?'
                  : 'Would you like to set this as your captain profile photo?',
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
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
                  child: const Text('Unable to load image', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final email = _emailController.text.trim().toLowerCase();
    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final licenseNumber = _licenseController.text.trim().toUpperCase();

    CaptainStateService().updateProfile(
      name: name,
      phone: phone,
      email: email,
      vehicleNumber: vehicleNumber,
      vehicleType: _selectedVehicleType,
      licenseNumber: licenseNumber,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Captain profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
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
            title: const Text('Edit Captain Profile'),
            actions: [
              if (_isSaving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _handleSave,
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo Header
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                ),
                                border: Border.all(color: AppColors.borderDark, width: 2),
                              ),
                              child: ClipOval(
                                child: _isUploadingProfile
                                    ? Center(
                                        child: SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: CircularProgressIndicator(
                                            value: _profileProgress > 0 ? _profileProgress : null,
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : (account.profileImageUrl != null && account.profileImageUrl!.isNotEmpty
                                        ? Image.network(
                                            account.profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Icon(
                                              Icons.person_rounded,
                                              size: 52,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.person_rounded, size: 52, color: Colors.black),
                                          )),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingProfile ? null : _handlePickProfilePhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isUploadingProfile ? null : _handlePickProfilePhoto,
                          icon: const Icon(Icons.photo_camera_rounded, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Change Profile Photo',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // Protected Account ID (Read-only)
                  _buildReadOnlyField(
                    label: 'Captain ID (Protected)',
                    value: account.id,
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Full Name
                  _buildTextFormField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'e.g. Rajesh Kumar',
                    icon: Icons.person_outline_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Full name is required';
                      if (val.trim().length < 2) return 'Full name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Phone Number
                  _buildTextFormField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '10-digit mobile number',
                    icon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Phone number is required';
                      final digits = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length != 10) return 'Enter a valid 10-digit phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Email
                  _buildTextFormField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'e.g. captain@quickride.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      final emailRegExp = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(val.trim())) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Vehicle Type (Dropdown)
                  const Text(
                    'Vehicle Type',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedVehicleType,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceDark,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type,
                              style: const TextStyle(
                                color: AppColors.textPrimaryDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedVehicleType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Vehicle Number
                  _buildTextFormField(
                    controller: _vehicleNumberController,
                    label: 'Vehicle Plate Number',
                    hint: 'e.g. KA-05-HA-1234',
                    icon: Icons.confirmation_number_outlined,
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vehicle number is required';
                      if (val.trim().length < 5) return 'Enter a valid plate number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Driving License
                  _buildTextFormField(
                    controller: _licenseController,
                    label: 'Driving License Number',
                    hint: 'e.g. DL-KA0520210009876',
                    icon: Icons.assignment_ind_outlined,
                    textCapitalization: TextCapitalization.characters,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Driving license number is required';
                      if (val.trim().length < 5) return 'Enter a valid license number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.space24),

                  // Vehicle Photo Section
                  const Text(
                    'Vehicle Image',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Captain Vehicle Photo',
                                style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            if (_isUploadingVehicle)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  value: _vehicleProgress > 0 ? _vehicleProgress : null,
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: _handlePickVehiclePhoto,
                                icon: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                                label: Text(
                                  account.vehicleImageUrl != null ? 'Change' : 'Upload',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        if (account.vehicleImageUrl != null && account.vehicleImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _showImagePreviewDialog(account.vehicleImageUrl!, 'Vehicle Photo'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                              child: Container(
                                height: 130,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevatedDark,
                                  border: Border.all(color: AppColors.borderDark),
                                ),
                                child: Image.network(
                                  account.vehicleImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondaryDark),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'No vehicle photo uploaded yet. Add a clear picture of your vehicle.',
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // Save Changes Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textSecondaryDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: AppColors.surfaceDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
