import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../../services/captain_auth_service.dart';
import '../../services/captain_state_service.dart';
import '../../services/captain_storage_service.dart';
import '../auth/captain_login_screen.dart';
import '../support/captain_support_screen.dart';
import 'captain_edit_profile_screen.dart';
import 'captain_change_password_screen.dart';
import 'captain_verification_screen.dart';

class CaptainProfileScreen extends StatefulWidget {
  const CaptainProfileScreen({super.key});

  @override
  State<CaptainProfileScreen> createState() => _CaptainProfileScreenState();
}

class _CaptainProfileScreenState extends State<CaptainProfileScreen> {
  final _storageService = CaptainStorageService();
  bool _isUploadingProfile = false;
  double _profileProgress = 0.0;
  bool _isUploadingVehicle = false;
  double _vehicleProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCaptainProfile();
  }

  Future<void> _loadCaptainProfile() async {
    await CaptainStateService().loadCaptainProfile();
  }

  Future<void> _handleUploadProfilePhoto(String captainId) async {
    final image = await _storageService.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingProfile = true;
      _profileProgress = 0.0;
    });

    final result = await _storageService.uploadProfilePhoto(
      captainId: captainId,
      file: image,
      onProgress: (progress) {
        if (mounted) setState(() => _profileProgress = progress);
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
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleUploadVehiclePhoto(String captainId) async {
    final image = await _storageService.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _isUploadingVehicle = true;
      _vehicleProgress = 0.0;
    });

    final result = await _storageService.uploadVehiclePhoto(
      captainId: captainId,
      file: image,
      onProgress: (progress) {
        if (mounted) setState(() => _vehicleProgress = progress);
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

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Logout Confirmation', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of QuickRide Captain?',
          style: TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CaptainAuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const CaptainLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CaptainStateService(),
      builder: (context, _) {
        final profile = CaptainStateService().profile;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text('Captain Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                tooltip: 'Edit Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CaptainEditProfileScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              children: [
                // Avatar & Rating
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
                                _showImagePreviewDialog(profile.profileImageUrl!, 'Captain Profile Photo');
                              } else {
                                _handleUploadProfilePhoto(profile.id);
                              }
                            },
                            child: Container(
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
                                          width: 36,
                                          height: 36,
                                          child: CircularProgressIndicator(
                                            value: _profileProgress > 0 ? _profileProgress : null,
                                            color: Colors.black,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                                        ? Image.network(
                                            profile.profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => const Icon(
                                              Icons.person_rounded,
                                              size: 54,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.person_rounded, size: 54, color: Colors.black),
                                          )),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingProfile ? null : () => _handleUploadProfilePhoto(profile.id),
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
                      const SizedBox(height: 12),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status & Rating Badges
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Duty Status Badge (Online/Offline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: profile.isOnline
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: profile.isOnline
                                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                    : Colors.grey.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: profile.isOnline ? const Color(0xFF10B981) : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.isOnline ? 'ONLINE' : 'OFFLINE',
                                  style: TextStyle(
                                    color: profile.isOnline ? const Color(0xFF10B981) : Colors.grey,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Verification Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: profile.isApproved
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : (profile.isRejected
                                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                      : Colors.amber.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: profile.isApproved
                                    ? const Color(0xFF10B981).withValues(alpha: 0.6)
                                    : (profile.isRejected
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                                        : Colors.amber.withValues(alpha: 0.6)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  profile.isApproved
                                      ? Icons.verified_user_rounded
                                      : (profile.isRejected
                                          ? Icons.highlight_off_rounded
                                          : Icons.hourglass_top_rounded),
                                  color: profile.isApproved
                                      ? const Color(0xFF10B981)
                                      : (profile.isRejected
                                          ? const Color(0xFFEF4444)
                                          : Colors.amberAccent),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  profile.isApproved
                                      ? 'VERIFIED'
                                      : (profile.isRejected ? 'REJECTED' : 'PENDING'),
                                  style: TextStyle(
                                    color: profile.isApproved
                                        ? const Color(0xFF10B981)
                                        : (profile.isRejected
                                            ? const Color(0xFFEF4444)
                                            : Colors.amberAccent),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rating & Completed Rides Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevatedDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.rating.toStringAsFixed(1)} Rating',
                                  style: const TextStyle(
                                    color: AppColors.textPrimaryDark,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${profile.totalRides} Rides',
                                  style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Edit Profile Quick Button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptainEditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceDark,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),

                // Documents & Verification Action Card
                _buildVerificationActionCard(profile),
                const SizedBox(height: AppDimensions.space20),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Captain Details',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(Icons.badge_rounded, 'Captain ID', profile.id),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _buildProfileRow(Icons.phone_iphone_rounded, 'Phone Number', profile.phone),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _buildProfileRow(Icons.email_rounded, 'Email', profile.email),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _buildProfileRow(Icons.two_wheeler_rounded, 'Vehicle', profile.vehicleType),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _buildProfileRow(Icons.confirmation_number_rounded, 'Vehicle Plate', profile.vehicleNumber),
                      const Divider(color: AppColors.borderDark, height: 20),
                      _buildProfileRow(Icons.assignment_ind_rounded, 'Driving License', profile.licenseNumber),
                      const Divider(color: AppColors.borderDark, height: 20),
                      
                      // Vehicle Photo Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_car_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Vehicle Photo', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  profile.vehicleImageUrl != null ? 'Vehicle image verified' : 'No photo uploaded yet',
                                  style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          _isUploadingVehicle
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    value: _vehicleProgress > 0 ? _vehicleProgress : null,
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton.icon(
                                  onPressed: () => _handleUploadVehiclePhoto(profile.id),
                                  icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.primary),
                                  label: Text(
                                    profile.vehicleImageUrl != null ? 'Change' : 'Upload',
                                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                        ],
                      ),
                      if (profile.vehicleImageUrl != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showImagePreviewDialog(profile.vehicleImageUrl!, 'Vehicle Photo'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              child: Image.network(
                                profile.vehicleImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondaryDark),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),

                // Verification Status Badge
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space14),
                  decoration: BoxDecoration(
                    color: AppColors.onlineGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_rounded, color: AppColors.onlineGreen, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified QuickRide Captain',
                              style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Documents & background verification approved.',
                              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Change Password Action Tile
                _buildActionTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptainChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space12),

                // Captain Support & Assistance Button
                _buildActionTile(
                  icon: Icons.support_agent_rounded,
                  title: 'Captain Help & Support',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptainSupportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space12),

                // Logout Action Tile
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  iconColor: const Color(0xFFEF4444),
                  textColor: const Color(0xFFEF4444),
                  onTap: _handleLogout,
                ),
                const SizedBox(height: AppDimensions.space20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationActionCard(CaptainAccount profile) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (profile.isApproved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Approved';
      statusIcon = Icons.verified_user_rounded;
    } else if (profile.isRejected) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Rejected';
      statusIcon = Icons.highlight_off_rounded;
    } else {
      statusColor = Colors.amberAccent;
      statusLabel = 'Pending';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.fact_check_rounded, color: statusColor, size: 22),
        ),
        title: const Text(
          'Documents & Verification',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          profile.isRejected
              ? 'Reason: ${profile.rejectionReason ?? "Update required"}'
              : 'License, Vehicle RC & vehicle documents',
          style: TextStyle(
            color: profile.isRejected
                ? const Color(0xFFEF4444)
                : AppColors.textSecondaryDark,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondaryDark, size: 14),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CaptainVerificationScreen(),
            ),
          );
        },
      ),
    ),
  );
  }
}