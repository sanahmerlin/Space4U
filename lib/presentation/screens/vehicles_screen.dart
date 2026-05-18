import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/vehicle.dart';
import '../../providers/parking_provider.dart';
import '../../services/firestore_service.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({Key? key}) : super(key: key);

  void _showAddDialog(BuildContext context, String uid) {
    final nameCtrl = TextEditingController();
    final plateCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Vehicle',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Vehicle Name (e.g. My Tesla)')),
            const SizedBox(height: 12),
            TextField(
                controller: plateCtrl,
                decoration:
                    const InputDecoration(labelText: 'License Plate')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    plateCtrl.text.trim().isEmpty) return;
                await FirestoreService().addVehicle(
                    uid, nameCtrl.text.trim(), plateCtrl.text.trim(), false);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();
    final uid = provider.currentUser?.uid ?? '';
    final vehicles = provider.userVehicles;

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: vehicles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: AppColors.secondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No vehicles added yet', style: TextStyle(color: AppColors.secondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, i) {
                final v = vehicles[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_car, color: AppColors.primary),
                    ),
                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(v.licensePlate, style: const TextStyle(color: AppColors.secondary)),
                    trailing: v.isDefault
                        ? const Chip(
                            label: Text('Default', style: TextStyle(fontSize: 10, color: Colors.white)),
                            backgroundColor: AppColors.accent,
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => FirestoreService().deleteVehicle(uid, v.id),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, uid),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
