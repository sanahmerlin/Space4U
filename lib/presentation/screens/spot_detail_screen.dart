import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_data.dart';
import '../screens/booking_screen.dart';

class SpotDetailScreen extends StatelessWidget {
  final ParkingSpot spot;

  const SpotDetailScreen({Key? key, required this.spot}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Image.network(
              spot.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Content Sheet
          Positioned.fill(
            top: 250,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          spot.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${spot.pricePerHour.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text('/ hour', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${spot.rating} (${spot.reviews} reviews)'),
                      const Spacer(),
                      const Icon(Icons.location_on, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 4),
                      Text('${spot.distanceKm} km away'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: spot.amenities.map((amenity) => Chip(
                      label: Text(amenity),
                      backgroundColor: AppColors.surface,
                      labelStyle: const TextStyle(color: AppColors.primary),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure and convenient parking spot located in the heart of the city. 24/7 access with CCTV surveillance. Perfect for daily commuters or overnight stays.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingScreen(spot: spot),
                              ),
                            );
                          },
                          child: const Text('Book Now'),
                        ),
                      ),
                    ),
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
