import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/captain_auth_service.dart';
import '../auth/captain_login_screen.dart';
import '../support/captain_support_screen.dart';

class CaptainSettingsScreen extends StatefulWidget {
  const CaptainSettingsScreen({super.key});

  @override
  State<CaptainSettingsScreen> createState() => _CaptainSettingsScreenState();
}

class _CaptainSettingsScreenState extends State<CaptainSettingsScreen> {
  bool _rideAlerts = true;
  bool _soundEnabled = true;
  bool _highDemandAlerts = true;
  bool _autoAcceptRides = false;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: const Text('Logout', style: TextStyle(color: AppColors.textPrimaryDark, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to log out of QuickRide Captain? Your registered account data will remain saved, but your active driving session will be ended.',
          style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear session key from shared_preferences
              await CaptainAuthService().logout();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CaptainLoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          const Text(
            'Ride Preferences',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Ride Request Alerts', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Receive sound and notification popups for new rides', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  value: _rideAlerts,
                  onChanged: (v) => setState(() => _rideAlerts = v),
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Sound Effects', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play chime upon ride assignment and completion', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  value: _soundEnabled,
                  onChanged: (v) => setState(() => _soundEnabled = v),
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('High Demand Surge Alerts', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Notify when nearby zones have extra fare multiplier', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  value: _highDemandAlerts,
                  onChanged: (v) => setState(() => _highDemandAlerts = v),
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                SwitchListTile(
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Auto-Accept Rides (Beta)', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically accept requests within 2 km radius', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  value: _autoAcceptRides,
                  onChanged: (v) => setState(() => _autoAcceptRides = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Support & Legal',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded, color: AppColors.secondary),
                  title: const Text('Captain Help & Support', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptainSupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.onlineGreen),
                  title: const Text('Safety Center & SOS Guidelines', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
                  onTap: () {},
                ),
                const Divider(color: AppColors.borderDark, height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondaryDark),
                  title: const Text('About QuickRide Captain', style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Version 1.0.0 (Build 1)', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.15),
              foregroundColor: AppColors.error,
              elevation: 0,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout from Captain App', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
    );
  }
}
