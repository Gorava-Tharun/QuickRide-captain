import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/captain_models.dart';
import '../../services/captain_state_service.dart';
import '../../services/captain_demo_service.dart';
import 'captain_ride_details_screen.dart';

enum HistoryFilter { all, today, thisWeek, thisMonth }

class CaptainHistoryScreen extends StatefulWidget {
  const CaptainHistoryScreen({super.key});

  @override
  State<CaptainHistoryScreen> createState() => _CaptainHistoryScreenState();
}

class _CaptainHistoryScreenState extends State<CaptainHistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;
  late bool _showDemoHistory;

  @override
  void initState() {
    super.initState();
    _showDemoHistory = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([CaptainStateService(), CaptainDemoService()]),
      builder: (context, _) {
        final stateService = CaptainStateService();
        final demoService = CaptainDemoService();

        final filteredRides = _getFilteredRides(stateService, demoService);
        final totalCount = _showDemoHistory
            ? demoService.demoCompletedRides.length
            : stateService.completedRides.length;
        final hasAnyRides = totalCount > 0;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceDark,
            title: const Text(
              'Ride History',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Column(
            children: [
              _buildModeSelector(),
              if (_showDemoHistory) _buildDemoHistoryNotice(),

              // Filter Chips Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'All',
                        HistoryFilter.all,
                        _showDemoHistory ? demoService.demoCompletedRides.length : stateService.completedRides.length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Today',
                        HistoryFilter.today,
                        _showDemoHistory ? demoService.todayDemoCompletedRidesCount : stateService.todayCompletedRidesCount,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'This Week',
                        HistoryFilter.thisWeek,
                        _showDemoHistory ? demoService.weeklyDemoCompletedRidesCount : stateService.weeklyCompletedRidesCount,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'This Month',
                        HistoryFilter.thisMonth,
                        _showDemoHistory ? demoService.monthlyDemoCompletedRidesCount : stateService.monthlyCompletedRidesCount,
                      ),
                    ],
                  ),
                ),
              ),

              // Ride List or Empty State
              Expanded(
                child: filteredRides.isEmpty
                    ? _buildEmptyState(context, hasAnyRides)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        itemCount: filteredRides.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space12),
                        itemBuilder: (context, index) {
                          final item = filteredRides[index];
                          return _buildRideHistoryCard(context, item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showDemoHistory = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_showDemoHistory ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Real History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: !_showDemoHistory ? Colors.black : AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showDemoHistory = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _showDemoHistory ? Colors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: _showDemoHistory ? Colors.black : Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DEMO HISTORY',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _showDemoHistory ? Colors.black : Colors.amber,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHistoryNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'DEMO RIDE HISTORY — Stored separately from real ride history. Preserved across app restarts.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  List<CompletedRideRecord> _getFilteredRides(
    CaptainStateService stateService,
    CaptainDemoService demoService,
  ) {
    if (_showDemoHistory) {
      switch (_selectedFilter) {
        case HistoryFilter.today:
          return demoService.todayDemoRides;
        case HistoryFilter.thisWeek:
          return demoService.weeklyDemoRides;
        case HistoryFilter.thisMonth:
          return demoService.monthlyDemoRides;
        case HistoryFilter.all:
          return demoService.demoCompletedRides;
      }
    } else {
      switch (_selectedFilter) {
        case HistoryFilter.today:
          return stateService.todayRides;
        case HistoryFilter.thisWeek:
          return stateService.weeklyRides;
        case HistoryFilter.thisMonth:
          return stateService.monthlyRides;
        case HistoryFilter.all:
          return stateService.completedRides;
      }
    }
  }

  Widget _buildFilterChip(String label, HistoryFilter filter, int count) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (_showDemoHistory ? Colors.amber : AppColors.primary)
              : AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (_showDemoHistory ? Colors.amber : AppColors.primary)
                : AppColors.borderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withValues(alpha: 0.15) : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.black : AppColors.textSecondaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasAnyRides) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
                border: Border.all(
                  color: _showDemoHistory ? Colors.amber.withValues(alpha: 0.5) : AppColors.borderDark,
                ),
              ),
              child: Icon(
                _showDemoHistory ? Icons.bolt_rounded : Icons.history_rounded,
                size: 40,
                color: _showDemoHistory ? Colors.amber : AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasAnyRides ? 'No rides for this period' : (_showDemoHistory ? 'No demo rides completed yet' : 'No completed rides yet'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyRides
                  ? 'Try selecting a different filter above to view completed trips.'
                  : (_showDemoHistory
                      ? 'Complete a demo ride on the Home screen to see the verified demo record here.'
                      : 'Rides you complete will be automatically logged and detailed here.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideHistoryCard(BuildContext context, CompletedRideRecord item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: item.isDemo ? Colors.amber.withValues(alpha: 0.5) : AppColors.borderDark,
          width: item.isDemo ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CaptainRideDetailsScreen(record: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.onlineGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.onlineGreen.withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 11, color: AppColors.onlineGreen),
                                SizedBox(width: 4),
                                Text(
                                  'COMPLETED',
                                  style: TextStyle(
                                    color: AppColors.onlineGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: (item.isPaid ? AppColors.onlineGreen : Colors.orange)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: (item.isPaid ? AppColors.onlineGreen : Colors.orange)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.isPaid ? Icons.verified_rounded : Icons.schedule_rounded,
                                  size: 10,
                                  color: item.isPaid ? AppColors.onlineGreen : Colors.orange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.isDemo
                                      ? 'DEMO / CASH'
                                      : (item.isPaid
                                          ? (item.paymentMethod != null ? 'PAID • ${item.paymentMethod}' : 'PAID')
                                          : 'UNPAID'),
                                  style: TextStyle(
                                    color: item.isPaid ? AppColors.onlineGreen : Colors.orange,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.isDemo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber, width: 0.8),
                              ),
                              child: const Text(
                                'DEMO',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                          if (item.isRated) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.rating ?? 5}★',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.captainEarning.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: item.isDemo ? Colors.amber : AppColors.success,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          'Gross: ₹${item.fare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(item.completionTime)}, ${_formatTime(item.completionTime)} • Ride #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Passenger & Vehicle Row
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      item.passengerName,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${item.vehicleType}',
                      style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${item.distanceKm} km • ${item.formattedDuration}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.borderDark, height: 20),

                // Pickup
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, color: AppColors.onlineGreen, size: 10),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.pickupAddress,
                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppColors.error, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.dropAddress,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMutedDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
