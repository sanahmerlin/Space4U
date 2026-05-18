import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'active_session_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String bookingId;
  const ConfirmationScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Manual navigation preferred for Phase 8+
  }

  Future<void> _launchNavigation(double destLat, double destLng, {double? originLat, double? originLng}) async {
    // 1. Build the high-precision Universal Google Maps Directions URL
    final Map<String, String> params = {
      'api': '1',
      'destination': '$destLat,$destLng',
      'travelmode': 'driving',
    };
    
    if (originLat != null && originLng != null) {
      params['origin'] = '$originLat,$originLng';
    }

    final Uri googleMapsUrl = Uri.https('www.google.com', '/maps/dir/', params);

    try {
      if (kIsWeb) {
        // PlatformDefault is more reliable for Web-to-App handshakes than externalApplication on mobile browsers
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      } else {
        // Native App Logic: Try deep-links first
        if (Platform.isIOS) {
          final Uri appleMapsUrl = Uri.parse('http://maps.apple.com/?daddr=$destLat,$destLng');
          if (await canLaunchUrl(appleMapsUrl)) {
            await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
            return;
          }
        } else if (Platform.isAndroid) {
          final Uri googleMapsAppUrl = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
          if (await canLaunchUrl(googleMapsAppUrl)) {
            await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
            return;
          }
        }
        
        // Final Fallback for Native
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Navigation launch failed: $e');
      // Emergency Fallback: Standard Search Link
      final Uri backupUrl = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$destLat,$destLng',
      });
      await launchUrl(backupUrl, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 100),
            const SizedBox(height: 24),
            Text(
              'Booking Confirmed!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Text(
              'Your parking session is confirmed.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                   Consumer<ParkingProvider>(
                     builder: (context, provider, child) {
                        final session = provider.activeSessions.any((s) => s.id == widget.bookingId) 
                            ? provider.activeSessions.firstWhere((s) => s.id == widget.bookingId)
                            : null;
                        if (session == null) return const SizedBox.shrink();
                        
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchNavigation(
                              session.spot.latitude, 
                              session.spot.longitude,
                              originLat: provider.currentPosition?.latitude,
                              originLng: provider.currentPosition?.longitude,
                            ),
                            icon: const Icon(Icons.navigation),
                            label: const Text('NAVIGATE WITH GOOGLE MAPS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        );
                     }
                   ),
                   const SizedBox(height: 16),
                   TextButton(
                     onPressed: () {
                        final provider = context.read<ParkingProvider>();
                        final session = provider.activeSessions.any((s) => s.id == widget.bookingId) 
                            ? provider.activeSessions.firstWhere((s) => s.id == widget.bookingId)
                            : null;
                        
                        // Default to Parked Now (0), but switch to Upcoming (1) if it's a future booking
                        int targetTab = (session != null && session.isUpcoming) ? 1 : 0;

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ActiveSessionScreen(initialIndex: targetTab)),
                        );
                     },
                     child: const Text('VIEW SESSION DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
