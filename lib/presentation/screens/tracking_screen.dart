import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Location'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Visual Map Placeholder
          Container(
            color: const Color(0xFF242f3e), // Dark map base
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.map, size: 80, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Map Visualization Placeholder\n(Interactive Map in Phase 4)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Marker
          const Center(
            child: Icon(Icons.location_on, size: 48, color: AppColors.accent),
          ),
          
          // Bottom Info
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                   BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation, color: AppColors.accent),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3 min walk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Get directions', style: TextStyle(color: AppColors.accent)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
