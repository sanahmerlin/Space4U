import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParkingProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Activity History',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
          ),
          const Text(
            'Keep track of your past parking sessions.',
            style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Consumer<ParkingProvider>(
              builder: (context, provider, child) {
                final history = provider.pastBookings;
                
                if (history.isEmpty) {
                  return const Center(child: Text('No past activity'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final booking = history[index];
                    // Calculate duration string
                    final duration = booking.endTime.difference(booking.startTime);
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes.remainder(60);
                    final durationStr = '${hours}h ${minutes}m';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                booking.spot.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 60, height: 60, color: AppColors.background,
                                  child: const Icon(Icons.image_outlined, color: AppColors.secondary, size: 20),
                                ),
                              ),
                            ),
                            title: Text(
                              booking.spot.title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(booking.spot.address, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, yyyy • h:mm a').format(booking.startTime),
                                  style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${booking.totalCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Duration: $durationStr', style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                                Row(
                                  children: [
                                    Text('${booking.vehicleName}', style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontStyle: FontStyle.italic)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.refresh, size: 14, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Rebook',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
