import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../../services/firestore_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AddSpotScreen extends StatefulWidget {
  const AddSpotScreen({Key? key}) : super(key: key);

  @override
  State<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(37.7749, -122.4194); // Default to SF
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _findMyLocation();
  }

  Future<void> _findMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        final latLng = LatLng(pos.latitude, pos.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        if (mounted) {
          setState(() {
            _selectedLocation = latLng;
          });
        }
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _amenitiesCtrl.dispose();
    _instructionsCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 
                  context.read<ParkingProvider>().currentUser?.uid ?? '';
                  
      if (uid.isEmpty) {
        throw Exception("You must be signed in to list a space.");
      }

      final amenities = _amenitiesCtrl.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      await FirestoreService().addSpot(
        ownerId: uid,
        title: _titleCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        pricePerHour: double.parse(_priceCtrl.text.trim()),
        distanceKm: 0.0,
        imageUrl: _imageCtrl.text.trim().isNotEmpty
            ? _imageCtrl.text.trim()
            : 'https://images.unsplash.com/photo-1542255019-33d3bb44422f?auto=format&fit=crop&q=80&w=800',
        amenities: amenities,
        arrivalInstructions: _instructionsCtrl.text.trim(),
      );

      if (mounted) {
        await context.read<ParkingProvider>().refreshSpots();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Your spot is now listed!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Your Space'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.maps_home_work, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fill in the details of your parking spot and start earning!',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Spot Name *',
                  hintText: 'e.g. Secure Downtown Driveway',
                  prefixIcon: Icon(Icons.local_parking),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressCtrl,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  try {
                    final query = Uri.encodeComponent(value.trim());
                    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
                    final response = await http.get(url, headers: {'User-Agent': 'Space4U_App_Test'});
                    
                    if (response.statusCode == 200) {
                      final List data = json.decode(response.body);
                      if (data.isNotEmpty) {
                        final lat = double.parse(data[0]['lat'].toString());
                        final lng = double.parse(data[0]['lon'].toString());
                        final latLng = LatLng(lat, lng);
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: latLng, zoom: 16),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _selectedLocation = latLng;
                          });
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Geocoding failed: $e');
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Full Address *',
                  hintText: 'e.g. 123 Market St, San Francisco',
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Press Enter to find on map',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Map Selection
              const Text('Pinpoint the exact location:', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
              const SizedBox(height: 8),
              SizedBox(
                height: 250,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 14,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onCameraMove: (position) {
                          _selectedLocation = position.target;
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        myLocationEnabled: true,
                      ),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 30),
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          onPressed: _findMyLocation,
                          backgroundColor: AppColors.surface,
                          child: const Icon(Icons.my_location, color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Drag the map to align the pin exactly with your parking spot.',
                style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(height: 24),

              // Price
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price per Hour (USD) *',
                  hintText: 'e.g. 5.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amenities
              TextFormField(
                controller: _amenitiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amenities (comma-separated)',
                  hintText: 'e.g. CCTV, Covered, 24/7 Access',
                  prefixIcon: Icon(Icons.checklist),
                ),
              ),
              const SizedBox(height: 16),

              // Arrival Instructions
              TextFormField(
                controller: _instructionsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Arrival Instructions',
                  hintText: 'e.g. Park behind the red gate, access via the side alley.',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Image URL
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Photo URL (optional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 32),

              // Verification Block (Phase 4)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.hostAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hostAccent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppColors.hostAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Verification & Trust', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.hostAccent)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To protect our community, every spot must be verified. Please upload a digital copy of your property deed or utility bill.',
                      style: TextStyle(fontSize: 12, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                         // Mocking doc upload
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('📄 Document attached successfully!')),
                         );
                      },
                      icon: const Icon(Icons.document_scanner_rounded, size: 18),
                      label: const Text('UPLOAD PROOF OF OWNERSHIP'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.hostAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.hostAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit for Verification',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
