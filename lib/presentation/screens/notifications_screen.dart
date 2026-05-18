import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = context.read<ParkingProvider>().currentUser?.uid ?? '';
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snap.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final note = notes[i];
              final isRead = note['isRead'] == true;
              final date = note['date'] is Timestamp
                  ? (note['date'] as Timestamp).toDate()
                  : DateTime.now();
              return Container(
                color: isRead
                    ? Colors.transparent
                    : AppColors.accent.withValues(alpha: 0.05),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.notifications,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(note['title'] ?? '',
                      style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(note['body'] ?? '',
                          style: const TextStyle(color: AppColors.secondary)),
                      const SizedBox(height: 6),
                      Text(DateFormat('MMM d, h:mm a').format(date),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle),
                        ),
                  onTap: isRead
                      ? null
                      : () => service.markNotificationRead(
                          uid, note['id']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
