import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'home_screen.dart';

class ActiveSessionScreen extends StatelessWidget {
  final int initialIndex;
  const ActiveSessionScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  void _showScannerDialog(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScannerDialogContent(sessionId: sessionId),
    );
  }

  void _showExtendModal(BuildContext context) {
// ... existing code ...
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ExtendSessionModal(),
    );
  }

  void _endSession(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End Session?', style: TextStyle(color: AppColors.primary)),
        content: const Text('Are you sure you want to end this parking session early?', style: TextStyle(color: AppColors.secondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<ParkingProvider>().endSession(sessionId);
               Navigator.pop(context); // Just close the dialog, stream will update UI
            },
            child: const Text('End Session', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
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
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () {
               // Clear navigation stack and go back to Search Home (Root Scaffold)
               Navigator.of(context).pushAndRemoveUntil(
                 MaterialPageRoute(builder: (context) => const HomeScreen()), 
                 (route) => false
               );
            },
          ),
          title: const Text('My Garage'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Parked Now'),
              Tab(text: 'Upcoming'),
            ],
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.secondary,
          ),
        ),
        body: Consumer<ParkingProvider>(
          builder: (context, provider, child) {
            final parked = provider.currentParkedSessions;
            final upcoming = provider.upcomingReservations;

            return TabBarView(
              children: [
                _buildSessionList(context, parked, 'No active sessions'),
                _buildSessionList(context, upcoming, 'No upcoming reservations'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionList(BuildContext context, List<BookingSession> sessions, String emptyMsg) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_outlined, size: 64, color: AppColors.secondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: AppColors.secondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionCard(context, sessions[index]);
      },
    );
  }

  Widget _buildSessionCard(BuildContext context, BookingSession session) {
    final isVerified = context.read<ParkingProvider>().isVerified(session.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isVerified ? AppColors.success.withOpacity(0.5) : AppColors.divider, width: isVerified ? 1.5 : 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.spot.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(session.vehicleName, style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  if (isVerified)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user, color: AppColors.success, size: 10),
                          SizedBox(width: 4),
                          Text('VERIFIED', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: session.isUpcoming ? Colors.blue.withOpacity(0.1) : AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (session.remainingTime > Duration.zero) 
                        ? (session.isUpcoming ? 'RESERVED' : 'ACTIVE')
                        : 'COMPLETED',
                      style: TextStyle(
                        color: (session.remainingTime > Duration.zero) ? AppColors.accent : AppColors.secondary, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimerColumn(context, session.remainingTime, session.isUpcoming ? 'STARTS IN' : 'REMAINING'),
              Container(width: 1, height: 40, color: AppColors.divider),
              _buildSimpleInfoColumn('Total Cost', '\$${session.totalCost.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (session.remainingTime > Duration.zero && !isVerified)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showScannerDialog(context, session.id),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: const Text('VERIFY SPOT (QR)', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hostAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final pos = context.read<ParkingProvider>().currentPosition;
                      _launchNavigation(
                        session.spot.latitude, 
                        session.spot.longitude,
                        originLat: pos?.latitude,
                        originLng: pos?.longitude,
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 20),
                    label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _endSession(context, session.id), 
                icon: const Icon(Icons.stop_circle_outlined, color: AppColors.error, size: 28),
                tooltip: 'End Session',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerColumn(BuildContext context, Duration duration, String label) {
    return Column(
      children: [
        Text(
          _formatDuration(duration),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, fontFeatures: [FontFeature.tabularFigures()]),
        ),
        Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildSimpleInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 10, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondary)),
        Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class ExtendSessionModal extends StatefulWidget {
  const ExtendSessionModal({Key? key}) : super(key: key);

  @override
  State<ExtendSessionModal> createState() => _ExtendSessionModalState();
}

class _ExtendSessionModalState extends State<ExtendSessionModal> {
  int? _selectedMinutes;
  final TextEditingController _customController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Extend Parking', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildOption(context, '+30 m', 30),
              const SizedBox(width: 12),
              _buildOption(context, '+1 hr', 60),
              const SizedBox(width: 12),
              _buildOption(context, '+2 hr', 120),
            ],
          ),
          const SizedBox(height: 16),
          // Custom input placeholder
          TextField(
            controller: _customController,
            decoration: InputDecoration(
              hintText: 'Enter custom minutes...',
              suffixIcon: const Icon(Icons.access_time, color: AppColors.secondary),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) {
              setState(() {
                _selectedMinutes = int.tryParse(val);
              });
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedMinutes == null || _selectedMinutes! <= 0) 
                  ? null 
                  : () {
                      final firstActive = context.read<ParkingProvider>().currentParkedSessions.firstOrNull;
                      if (firstActive != null) {
                         context.read<ParkingProvider>().extendSession(firstActive.id, _selectedMinutes!, 2.0);
                      }
                      Navigator.pop(context);
                    },
              child: const Text('Confirm Extension'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, int minutes) {
    final isSelected = _selectedMinutes == minutes && _customController.text.isEmpty;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
             _selectedMinutes = minutes;
             _customController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.accent : AppColors.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerDialogContent extends StatefulWidget {
  final String sessionId;
  const ScannerDialogContent({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<ScannerDialogContent> createState() => _ScannerDialogContentState();
}

class _ScannerDialogContentState extends State<ScannerDialogContent> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Scan Spot QR'),
      content: SizedBox(
        width: 300,
        height: 380,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) async {
                        if (_isProcessing) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            setState(() => _isProcessing = true);
                            final success = await context.read<ParkingProvider>().verifySessionWithQR(widget.sessionId, barcode.rawValue!);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Spot Verified!'), backgroundColor: AppColors.success),
                              );
                            } else {
                              setState(() => _isProcessing = false);
                            }
                          }
                        }
                      },
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Point your camera at the QR code on the parking spot.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            const SizedBox(height: 16),
            // MOCK SCAN BUTTON
            TextButton.icon(
              onPressed: _isProcessing ? null : () async {
                final provider = context.read<ParkingProvider>();
                final session = provider.currentParkedSessions.firstWhere((s) => s.id == widget.sessionId);
                setState(() => _isProcessing = true);
                await provider.verifySessionWithQR(widget.sessionId, session.spot.id);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('MOCK SCAN (TEST MODE)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
