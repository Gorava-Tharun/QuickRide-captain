import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'captain_home_screen.dart';
import '../history/captain_history_screen.dart';
import '../earnings/captain_earnings_screen.dart';
import '../profile/captain_profile_screen.dart';
import '../settings/captain_settings_screen.dart';

class CaptainMainNavigation extends StatefulWidget {
  const CaptainMainNavigation({super.key});

  @override
  State<CaptainMainNavigation> createState() => _CaptainMainNavigationState();
}

class _CaptainMainNavigationState extends State<CaptainMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CaptainHomeScreen(),
    CaptainHistoryScreen(),
    CaptainEarningsScreen(),
    CaptainProfileScreen(),
    CaptainSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.borderDark, width: 1.0)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.surfaceDark,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondaryDark,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.two_wheeler_rounded),
              activeIcon: Icon(Icons.two_wheeler_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
