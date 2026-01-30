import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_user_data.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: MockUserData.notifications.length,
        itemBuilder: (context, index) {
          final note = MockUserData.notifications[index];
          return Container(
            color: note.isRead ? Colors.transparent : AppColors.accent.withOpacity(0.05),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: Icon(Icons.notifications, color: AppColors.primary, size: 20),
              ),
              title: Text(
                note.title,
                style: TextStyle(
                  fontWeight: note.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(note.body, style: TextStyle(color: AppColors.secondary)),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, h:mm a').format(note.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: note.isRead 
                  ? null 
                  : Container(
                      width: 10, 
                      height: 10, 
                      decoration: const BoxDecoration(
                        color: AppColors.accent, 
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
