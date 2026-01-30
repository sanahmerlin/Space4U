import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_user_data.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In a real app we might merge active/past here but for phase 3 we just show list
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Managed by bottom nav mostly
      ),
      body: MockUserData.history.isEmpty
          ? const Center(child: Text('No past activity'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockUserData.history.length,
              itemBuilder: (context, index) {
                final booking = MockUserData.history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            booking.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 60, height: 60, color: Colors.grey[800],
                            ),
                          ),
                        ),
                        title: Text(
                          booking.spotTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(booking.spotAddress),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(booking.date),
                              style: const TextStyle(fontSize: 12),
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
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Completed',
                                style: const TextStyle(fontSize: 10, color: Colors.white70),
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
                            Text('Duration: ${booking.duration}', style: const TextStyle(color: AppColors.secondary)),
                            Row(
                              children: [
                                const Icon(Icons.refresh, size: 16, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'Rebook',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
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
            ),
    );
  }
}
