import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'package:geolocator/geolocator.dart';

class SearchForm extends StatefulWidget {
  const SearchForm({Key? key}) : super(key: key);

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final currentQuery = context.read<ParkingProvider>().searchLocationQuery;
    _locationController = TextEditingController(text: currentQuery);
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context) async {
    final provider = context.read<ParkingProvider>();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(provider.searchStartTime),
    );

    if (picked != null) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final end = start.add(const Duration(hours: 1));
      await provider.updateSearchTime(start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: const [
           BoxShadow(color: Colors.black45, blurRadius: 40, offset: Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Parking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Location Input
          _buildInputLabel('DESTINATION'),
          const SizedBox(height: 10),
          TextField(
            controller: _locationController,
            onChanged: (val) => context.read<ParkingProvider>().updateSearchLocation(val),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location, size: 20, color: AppColors.secondary),
                onPressed: () async {
                  const nearMe = 'Near My Location';
                  _locationController.text = nearMe;
                  context.read<ParkingProvider>().updateSearchLocation(nearMe);
                },
              ),
              hintText: 'Enter specific location or landmark',
              hintStyle: TextStyle(color: AppColors.secondary.withOpacity(0.5), fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              // Time Range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('START TIME'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _pickTime(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 18, color: AppColors.accent),
                            const SizedBox(width: 12),
                            Consumer<ParkingProvider>(
                              builder: (context, provider, child) {
                                final start = provider.searchStartTime;
                                return Text(
                                  '${start.hour}:${start.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Vehicle Selection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('VEHICLE'),
                    const SizedBox(height: 10),
                    Consumer<ParkingProvider>(
                      builder: (context, provider, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: provider.selectedVehicleId ?? (provider.userVehicles.isNotEmpty ? provider.userVehicles.first.id : null),
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.secondary),
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              onChanged: (val) => provider.setVehicle(val),
                              items: provider.userVehicles.map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(v.name),
                              )).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Phase 8: Radius Selection
          _buildInputLabel('SEARCH RADIUS'),
          const SizedBox(height: 10),
          Consumer<ParkingProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${provider.searchRadius.toStringAsFixed(1)} km', 
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Max 5.0 km', style: TextStyle(color: AppColors.secondary.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.background,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.accent.withOpacity(0.2),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: provider.searchRadius,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9, // increments of 0.5km
                      onChanged: (val) => provider.setSearchRadius(val),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // SEARCH CTA
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Consumer<ParkingProvider>(
              builder: (context, provider, child) {
                final bool isTimeValid = provider.searchEndTime.isAfter(provider.searchStartTime);
                
                return ElevatedButton(
                  onPressed: (provider.isLoading || !isTimeValid) ? null : () => provider.startSearch(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimeValid ? AppColors.accent : AppColors.secondary.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: provider.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isTimeValid ? Icons.search : Icons.error_outline, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            isTimeValid ? 'FIND PARKING SPACE' : 'INVALID TIME SELECTION', 
                            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8)
                          ),
                        ],
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.secondary.withOpacity(0.8),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}
