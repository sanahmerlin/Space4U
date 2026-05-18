import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../widgets/parking_spot_card.dart';
import '../../models/parking_spot.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  String? _selectedSpotId;
  bool _didCenterOnUser = false;

  // Global default (will be overridden by user location)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(9.8943, 76.2673), // Default to a more relevant coordinate
    zoom: 13.0,
  );

  final String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#242f3e"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#746855"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#38414e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#212a37"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#17263c"}]
    }
  ]
  ''';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParkingProvider>();
    final allSpots = provider.allSpots;

    // Automatic Centering Logic
    if (!_didCenterOnUser && provider.currentPosition != null && _mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
          14
        )
      );
      _didCenterOnUser = true;
    }

    final Set<Marker> markers = {};
    for (var spot in allSpots) {
        final bool isConflicting = provider.isSpotConflicting(spot.id);
        final bool isSelected = _selectedSpotId == spot.id;

        double hue = isConflicting ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen;
        if (isSelected) hue = BitmapDescriptor.hueBlue;

        markers.add(
          Marker(
            markerId: MarkerId(spot.id),
            position: LatLng(spot.latitude, spot.longitude),
            onTap: () {
              setState(() {
                _selectedSpotId = spot.id;
              });
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(spot.latitude, spot.longitude), 15),
              );
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          ),
        );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _mapController?.setMapStyle(_darkMapStyle);
            
            // Immediate sync if location already exists
            if (provider.currentPosition != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude),
                  14
                )
              );
              _didCenterOnUser = true;
            }
          },
          onTap: (_) {
            setState(() {
              _selectedSpotId = null;
            });
          },
        ),
        
        // Search overlay with PointerInterceptor (Crucial for Web/Mobile)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: PointerInterceptor(
            child: Material(
              color: Colors.transparent,
              child: TextField(
                onChanged: (value) {
                  context.read<ParkingProvider>().searchSpots(value);
                },
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  try {
                    final query = Uri.encodeComponent(value.trim());
                    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
                    final response = await http.get(url, headers: {'User-Agent': 'Space4U_App_Production'});
                    
                    if (response.statusCode == 200) {
                      final List data = json.decode(response.body);
                      if (data.isNotEmpty) {
                        final lat = double.parse(data[0]['lat'].toString());
                        final lng = double.parse(data[0]['lon'].toString());
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: LatLng(lat, lng), zoom: 13),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('Map search API failed: $e');
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                  hintText: 'Search for a spot...',
                  hintStyle: const TextStyle(color: AppColors.secondary),
                  filled: true,
                  fillColor: AppColors.surface.withOpacity(0.9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Time Filter overlay
        Positioned(
          top: 80,
          left: 16,
          child: PointerInterceptor(
            child: GestureDetector(
              onTap: () => _showTimePicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Consumer<ParkingProvider>(
                      builder: (context, provider, child) {
                        final start = provider.searchStartTime;
                        return Text(
                          '${start.hour}:${start.minute.toString().padLeft(2, '0')} today',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Manual Location Button (since Scaffold is removed)
        if (_selectedSpotId == null)
          Positioned(
            bottom: 24,
            right: 16,
            child: PointerInterceptor(
              child: FloatingActionButton(
                onPressed: () async {
                   try {
                     final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                     _mapController?.animateCamera(
                       CameraUpdate.newCameraPosition(
                         CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 15)
                       )
                     );
                   } catch (e) {
                     debugPrint("Location error: $e");
                   }
                },
                backgroundColor: AppColors.surface,
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),
          ),

        // Bottom card overlay when spot selected
        if (_selectedSpotId != null)
          (() {
            final selectedSpot = allSpots.cast<ParkingSpot?>().firstWhere(
              (s) => s?.id == _selectedSpotId,
              orElse: () => null,
            );
            
            if (selectedSpot == null) return const SizedBox.shrink();
            
            return Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: PointerInterceptor(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: const [
                       BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -5)),
                    ],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ParkingSpotCard(spot: selectedSpot),
                ),
              ),
            );
          })(),
      ],
    );
  }

  void _showTimePicker(BuildContext context) async {
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
}
