import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/parking_spot.dart';
import '../../models/vehicle.dart';
import '../../providers/parking_provider.dart';
import '../screens/confirmation_screen.dart';
import '../screens/vehicles_screen.dart';
import '../widgets/stripe_mock_sheet.dart';

class BookingScreen extends StatefulWidget {
  final ParkingSpot spot;

  const BookingScreen({Key? key, required this.spot}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ParkingProvider>();
    _startTime = provider.searchStartTime;
    _endTime = provider.searchEndTime;
    _checkAvailability();
  }

  bool get _isTimeValid => _endTime.isAfter(_startTime);

  double get _totalPrice {
    if (!_isTimeValid) return 0.0;
    final diff = _endTime.difference(_startTime);
    final hours = diff.inMinutes / 60.0;
    return widget.spot.pricePerHour * hours;
  }

  void _checkAvailability() {
    context.read<ParkingProvider>().validateBooking(
      widget.spot.id,
      _startTime,
      _endTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();

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
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.divider,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.secondary, size: 24),
                      ),
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
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Time Filter
                    Text('Select Time', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                           _buildTimeRow('Start', _startTime, (newTime) {
                             setState(() => _startTime = newTime);
                             _checkAvailability();
                           }),
                           const Divider(height: 32),
                           _buildTimeRow('End', _endTime, (newTime) {
                             setState(() => _endTime = newTime);
                             _checkAvailability();
                           }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (provider.isCheckingAvailability)
                      const LinearProgressIndicator(color: AppColors.accent, backgroundColor: Colors.transparent)
                    else if (!provider.isSpotAvailable)
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                          const SizedBox(width: 8),
                          const Text('This slot is already reserved', style: TextStyle(color: AppColors.error, fontSize: 12)),
                        ],
                      )
                    else if (!provider.isVehicleAvailable)
                      Row(
                        children: [
                           Icon(Icons.directions_car_outlined, color: AppColors.error, size: 16),
                           const SizedBox(width: 8),
                           const Text('This car is already booked elsewhere!', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    
                    const SizedBox(height: 32),
        
                    // Vehicle Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Vehicle', style: Theme.of(context).textTheme.titleLarge),
                        if (provider.userVehicles.isNotEmpty)
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VehiclesScreen())),
                            child: const Text('Manage'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.userVehicles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('No vehicles found', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                                  Text('Add a vehicle to enable booking.', style: TextStyle(color: AppColors.error.withOpacity(0.8), fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VehiclesScreen())),
                              child: const Text('Add Now'),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: provider.userVehicles.length,
                          itemBuilder: (context, i) {
                            final vehicle = provider.userVehicles[i];
                            final isSelected = provider.selectedVehicle?.id == vehicle.id;
                            return GestureDetector(
                              onTap: () => provider.selectVehicle(vehicle),
                              child: Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accent : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? AppColors.accent : AppColors.divider),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.directions_car, size: 20, color: isSelected ? Colors.white : AppColors.secondary),
                                    const SizedBox(height: 4),
                                    Text(vehicle.name, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.primary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(vehicle.licensePlate, style: TextStyle(color: isSelected ? Colors.white70 : AppColors.secondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Cost Breakdown
            const Divider(color: AppColors.divider),
            if (!_isTimeValid)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Invalid Time Range: End must be after Start.',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Cost', style: TextStyle(color: Colors.white70)),
                Text(
                  '\$${_totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _isTimeValid ? AppColors.accent : AppColors.secondary.withOpacity(0.5),
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
                onPressed: (provider.selectedVehicle == null || !provider.isSpotAvailable || !provider.isVehicleAvailable || provider.isCheckingAvailability || !_isTimeValid) 
                  ? null 
                  : () {
                      StripeMockSheet.show(
                        context,
                        amount: _totalPrice,
                        onSuccess: () {
                          provider.startBooking(widget.spot, _startTime, _endTime).then((id) {
                             if (mounted && id != null) {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => ConfirmationScreen(bookingId: id),
                                 ),
                               );
                             }
                          });
                        },
                      );
                    },
                child: Text(
                  !_isTimeValid 
                    ? 'Check Time Selection' 
                    : (!provider.isSpotAvailable 
                      ? 'Time Slot Unavailable' 
                      : (!provider.isVehicleAvailable ? 'Vehicle Already Booked' : (provider.selectedVehicle == null ? 'Select a Vehicle' : 'Proceed to Checkout')))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time, Function(DateTime) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondary)),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: time,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (pickedDate != null) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(time),
              );
              if (pickedTime != null) {
                onChanged(DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                ));
              }
            }
          },
          child: Row(
            children: [
              Text(
                '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
              const Icon(Icons.edit, size: 14, color: AppColors.accent),
            ],
          ),
        ),
      ],
    );
  }
}
