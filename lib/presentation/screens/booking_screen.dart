import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/mock_data.dart';
import '../../providers/parking_provider.dart';
import '../screens/confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final ParkingSpot spot;

  const BookingScreen({Key? key, required this.spot}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedHours = 2;

  double get _totalPrice => widget.spot.pricePerHour * _selectedHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Parking'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.spot.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.spot.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.spot.address, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text('\$${widget.spot.pricePerHour.toStringAsFixed(2)}/hr', style: TextStyle(color: AppColors.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Duration Selector
            Text('Select Duration', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Slider(
              value: _selectedHours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              activeColor: AppColors.accent,
              label: '$_selectedHours hrs',
              onChanged: (val) {
                setState(() {
                  _selectedHours = val.toInt();
                });
              },
            ),
            Center(
              child: Text(
                '$_selectedHours Hours',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const Spacer(),
            
            // Cost Breakdown
            const Divider(color: AppColors.divider),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Cost', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<ParkingProvider>().startBooking(widget.spot, _selectedHours);
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfirmationScreen(),
                    ),
                  );
                },
                child: const Text('Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
