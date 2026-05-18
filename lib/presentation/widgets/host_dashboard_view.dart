import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../screens/add_spot_screen.dart';

class HostDashboardView extends StatelessWidget {
  const HostDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final hostBookings = provider.hostBookings;
        final activeRenters = hostBookings.where((s) => s.isActive).toList();
        final totalEarnings = hostBookings.fold<double>(0, (sum, b) => sum + b.totalCost);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Card
              _buildEarningsCard(context, totalEarnings, activeRenters.length),
              const SizedBox(height: 32),

              // Weekly Revenue Chart (New Phase 3)
              const Text(
                'Weekly Revenue Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildRevenueChart(context, provider.weeklyRevenueTrend),
              const SizedBox(height: 32),

              // Quick Actions
              Row(
                children: [
                  _buildQuickAction(
                    context,
                    title: 'List Spot',
                    icon: Icons.add_business_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSpotScreen())),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                    context,
                    title: 'Fleet Stats',
                    icon: Icons.analytics_outlined,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Spot Performance (New Phase 3)
              const Text(
                'Spot Performance',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildSpotPerformanceList(context, provider.spotPerformanceList),
              const SizedBox(height: 32),

              // Live Occupancy Feed
              const Text(
                'Live Occupancy Feed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (hostBookings.isEmpty)
                _buildEmptyState()
              else
                ...(() {
                  // Sort: Overstaying first, then Arriving, then Active
                  final sortedBookings = List<BookingSession>.from(hostBookings);
                  sortedBookings.sort((a, b) {
                    final aOverstay = a.status == 'overstaying';
                    final bOverstay = b.status == 'overstaying';
                    if (aOverstay && !bOverstay) return -1;
                    if (!aOverstay && bOverstay) return 1;
                    
                    final aApprox = provider.approachingSessionIds.contains(a.id);
                    final bApprox = provider.approachingSessionIds.contains(b.id);
                    if (aApprox && !bApprox) return -1;
                    if (!aApprox && bApprox) return 1;
                    
                    return 0;
                  });

                  return sortedBookings.map((booking) {
                    final isApproaching = provider.approachingSessionIds.contains(booking.id);
                    final isOverstaying = booking.status == 'overstaying';
                    
                    // Show if active OR if it's a reserved guest arriving soon OR overstaying
                    if (booking.status == 'active' || isApproaching || isOverstaying) {
                      return _buildOccupancyCard(context, booking, isApproaching, isOverstaying);
                    }
                    return const SizedBox.shrink();
                  }).toList();
                })(),
            ],
          ),
        );
      },
    );
  }

  void _showSpotQRDialog(BuildContext context, String spotId, String spotTitle) {
    if (spotId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Spot ID missing. Try refreshing.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(spotTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Physical Check-in Key', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: spotId.isNotEmpty 
                ? QrImageView(
                    data: spotId,
                    version: QrVersions.auto,
                    size: 200.0,
                    errorStateBuilder: (cxt, err) => const Center(child: Text('Failed to generate QR')),
                  )
                : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            ),
            const SizedBox(height: 24),
            const Text('Print this QR and place it at your parking spot for instant arrival verification.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, Map<int, double> data) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.values.isEmpty ? 10 : (data.values.reduce((a, b) => a > b ? a : b) * 1.5),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              tooltipBorder: const BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      days[value.toInt() % 7], 
                      style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final day = index + 1;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[day] ?? 0,
                  color: AppColors.hostAccent,
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSpotPerformanceList(BuildContext context, List<SpotPerformance> performance) {
    if (performance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No performance data yet', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
        ),
      );
    }

    final maxRevenue = performance.first.totalRevenue;

    return Column(
      children: performance.take(3).map((spot) { // Show top 3 earners
        final progress = maxRevenue > 0 ? spot.totalRevenue / maxRevenue : 0.0;
        final isVerified = spot.verificationStatus == 'verified';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isVerified ? AppColors.success.withOpacity(0.3) : AppColors.divider, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spot.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVerified ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVerified ? 'VERIFIED ✅' : 'PENDING REVIEW ⏳',
                            style: TextStyle(
                              color: isVerified ? AppColors.success : Colors.orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (!isVerified)
                        IconButton(
                          onPressed: () => context.read<ParkingProvider>().verifySpot(spot.spotId),
                          icon: const Icon(Icons.verified_user_outlined, color: Colors.orange, size: 20),
                          tooltip: 'ADMIN: Mock Approve',
                        ),
                      IconButton(
                        onPressed: () => _showSpotQRDialog(context, spot.spotId, spot.title),
                        icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.hostAccent, size: 20),
                        tooltip: 'Show Spot QR',
                      ),
                      Text('\$${spot.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.hostAccent)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.hostAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text('${spot.occupancyCount} sessions booked', style: const TextStyle(color: AppColors.secondary, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarningsCard(BuildContext context, double total, int activeCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.hostAccent, Color(0xFF311B92)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.hostAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL REVENUE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildMiniStat('Active Rentals', activeCount.toString()),
              const SizedBox(width: 32),
              _buildMiniStat('Monthly Trend', '+12%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickAction(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.hostAccent, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOccupancyCard(BuildContext context, dynamic booking, bool isApproaching, bool isOverstaying) {
    Color statusColor = AppColors.success;
    String statusText = 'Currently Parked';
    
    if (isOverstaying) {
      statusColor = AppColors.error;
      statusText = 'OVERSTAYING';
    } else if (isApproaching) {
      statusColor = Colors.orange;
      statusText = 'ARRIVING...';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.5), 
          width: (isApproaching || isOverstaying) ? 1.5 : 0.5
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor,
            radius: 4,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(booking.spot.title, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
              ],
            ),
          ),
          Text(
            statusText, 
            style: TextStyle(
              color: statusColor, 
              fontSize: 11, 
              fontWeight: (isApproaching || isOverstaying) ? FontWeight.w900 : FontWeight.bold,
              letterSpacing: (isApproaching || isOverstaying) ? 0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Icon(Icons.sensor_occupied_outlined, size: 48, color: AppColors.secondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No one is parked currently', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
        ],
      ),
    );
  }
}
