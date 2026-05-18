import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/parking_spot.dart';
import '../../providers/parking_provider.dart';
import '../../services/firestore_service.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  Future<void> _deleteSpot(BuildContext context, String spotId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Listing'),
        content:
            const Text('Are you sure you want to remove this parking spot?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteSpot(spotId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spot removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<ParkingProvider>().currentUser?.uid ?? '';
    const String placeholderImage = 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000&auto=format&fit=crop';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'My Parking Spots',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
          ),
          const Text(
            'Manage and monitor your listed spaces.',
            style: TextStyle(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FirestoreService().streamMySpots(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final spots = snap.data ?? [];
                if (spots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_parking,
                            size: 64, color: AppColors.secondary),
                        const SizedBox(height: 16),
                        const Text('No listings yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('List your first spot to start earning!',
                            style: TextStyle(color: AppColors.secondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: spots.length,
                  itemBuilder: (context, i) {
                    final spot = spots[i];
                    final String imageUrl = (spot['imageUrl'] as String?)?.isNotEmpty == true 
                        ? spot['imageUrl'] 
                        : placeholderImage;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Column(
                        children: [
                          // Modified Image Logic with Placeholder & Fail-safe Error UI
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              imageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, color: AppColors.secondary.withOpacity(0.3), size: 40),
                                      const SizedBox(height: 8),
                                      Text('Image Preview', style: TextStyle(color: AppColors.secondary.withOpacity(0.3), fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        spot['title'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900, fontSize: 18),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '\$${(spot['pricePerHour'] as num).toStringAsFixed(2)}/hr',
                                        style: const TextStyle(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 14, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        spot['address'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.secondary, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('ACTIVE',
                                              style: TextStyle(
                                                  color: AppColors.success,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.1)),
                                        ),
                                        const SizedBox(width: 8),
                                        // Verification Badge (Phase 4)
                                        (() {
                                          final isVerified = spot['verificationStatus'] == 'verified';
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isVerified ? AppColors.accent.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isVerified ? 'VERIFIED ✅' : 'PENDING ⏳',
                                              style: TextStyle(
                                                  color: isVerified ? AppColors.accent : Colors.orange,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.1),
                                            ),
                                          );
                                        })(),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (spot['verificationStatus'] != 'verified')
                                          TextButton.icon(
                                            onPressed: () => context.read<ParkingProvider>().verifySpot(spot['id']),
                                            icon: const Icon(Icons.verified_user_rounded, size: 14),
                                            label: const Text('VERIFY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error),
                                          onPressed: () =>
                                              _deleteSpot(context, spot['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
