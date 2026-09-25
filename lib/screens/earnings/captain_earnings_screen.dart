import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../../services/captain_state_service.dart';

class CaptainEarningsScreen extends StatelessWidget {
  const CaptainEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CaptainStateService(),
      builder: (context, _) {
        final service = CaptainStateService();
        final isEmpty = service.completedRides.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('Captain Earnings', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: isEmpty
                ? _buildEmptyEarningsView(context, service)
                : _buildEarningsContent(service),
          ),
        );
      },
    );
  }

  Widget _buildEmptyEarningsView(BuildContext context, CaptainStateService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.borderDark, width: 1.5),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 46,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No completed rides yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go online and complete rides to start earning. Your daily, weekly, and monthly earnings breakdown will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryDark,
                height: 1.4,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 28),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_chart_rounded, size: 18),
                label: const Text(
                  'Load Sample Demo Rides',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                onPressed: () async {
                  await service.seedDemoCompletedRides();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample demo rides loaded.')),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsContent(CaptainStateService service) {
    final todayEarnings = service.todayEarningsTotal;
    final todayRidesCount = service.todayCompletedRidesCount;

    final weeklyEarnings = service.weeklyEarningsTotal;
    final weeklyRidesCount = service.weeklyCompletedRidesCount;

    final monthlyEarnings = service.monthlyEarningsTotal;
    final monthlyRidesCount = service.monthlyCompletedRidesCount;

    final totalEarnings = service.totalEarnings;
    final totalRidesCount = service.totalCompletedRidesCount;
    final averageFare = service.averageFare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Primary Highlight Card: Today's Earnings
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.space20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B2436), Color(0xFF131B2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Earnings",
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.onlineGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'ACTIVE TODAY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.onlineGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹${service.todayCaptainEarningsNet.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Net Earnings (85%)',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Gross Fare: ₹${todayEarnings.toStringAsFixed(0)} • Platform Fee (15%): ₹${service.todayPlatformFeeTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderDark, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Completed Rides', '$todayRidesCount', Icons.check_circle_outline_rounded, AppColors.onlineGreen),
                  Container(width: 1, height: 26, color: AppColors.borderDark),
                  _buildStatItem('Avg Fare', '₹${averageFare.toStringAsFixed(0)}', Icons.analytics_outlined, AppColors.secondary),
                  Container(width: 1, height: 26, color: AppColors.borderDark),
                  _buildStatItem('Lifetime Net', '₹${service.totalCaptainEarningsNet.toStringAsFixed(0)}', Icons.all_inclusive_rounded, AppColors.primary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),

        // Section Title: Detailed Breakdowns
        const Text(
          'Earnings Breakdown',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),

        // 2. This Week's Earnings Card
        _buildPeriodCard(
          title: "This Week's Earnings",
          subtitle: 'Current Monday to Sunday cycle',
          amount: weeklyEarnings,
          ridesCount: weeklyRidesCount,
          icon: Icons.calendar_view_week_rounded,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: AppDimensions.space10),

        // 3. This Month's Earnings Card
        _buildPeriodCard(
          title: "This Month's Earnings",
          subtitle: 'Current calendar month',
          amount: monthlyEarnings,
          ridesCount: monthlyRidesCount,
          icon: Icons.calendar_month_rounded,
          iconColor: Colors.amber,
        ),
        const SizedBox(height: AppDimensions.space10),

        // 4. Lifetime Total Earnings Card
        _buildPeriodCard(
          title: 'Total Earnings (All Time)',
          subtitle: 'Cumulative earnings from all completed rides',
          amount: totalEarnings,
          ridesCount: totalRidesCount,
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.onlineGreen,
        ),
        const SizedBox(height: AppDimensions.space24),

        // 5. Recent Completed Trips Breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Earnings Activity',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              '${service.completedRides.length} Total Rides',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space10),

        ...service.completedRides.take(5).map((r) => _buildRecentRideRow(r)),
        const SizedBox(height: AppDimensions.space20),
      ],
    );
  }

  Widget _buildPeriodCard({
    required String title,
    required String subtitle,
    required double amount,
    required int ridesCount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$ridesCount ${ridesCount == 1 ? 'ride' : 'rides'} • $subtitle',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRideRow(CompletedRideRecord record) {
    final isPaid = record.isPaid;
    final rideId = record.rideId ?? record.id;
    final formattedDate =
        '${record.completionTime.day.toString().padLeft(2, '0')}/${record.completionTime.month.toString().padLeft(2, '0')} at ${record.completionTime.hour.toString().padLeft(2, '0')}:${record.completionTime.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: 16,
                    color: isPaid ? AppColors.onlineGreen : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rideId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPaid ? AppColors.onlineGreen : Colors.orange).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isPaid ? AppColors.onlineGreen : Colors.orange,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      record.paymentStatus?.toUpperCase() ?? 'PAID',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? AppColors.onlineGreen : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '+₹${record.captainEarning.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isPaid ? AppColors.success : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Passenger: ${record.passengerName} • $formattedDate',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gross: ₹${record.effectiveOriginalFare.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
              ),
              if (record.discount > 0)
                Text(
                  'Disc: -₹${record.discount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                ),
              Text(
                'Fee (15%): ₹${record.platformFee.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
              ),
              Text(
                record.paymentMethod ?? 'Online / Cash',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
