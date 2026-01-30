import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_user_data.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockUserData.vehicles.length,
        itemBuilder: (context, index) {
          final v = MockUserData.vehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: AppColors.primary),
              title: Text(v.name),
              subtitle: Text(v.licensePlate),
              trailing: v.isDefault 
                  ? const Chip(label: Text('Default', style: TextStyle(fontSize: 10)))
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
