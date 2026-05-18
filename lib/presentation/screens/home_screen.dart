import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../widgets/parking_spot_card.dart';
import '../widgets/search_form.dart';
import 'active_session_screen.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'map_screen.dart';
import 'my_listings_screen.dart';
import '../widgets/host_dashboard_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Listen for Automated Movements (Geofencing Phase 5)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ParkingProvider>();
      
      // Rider: Arrival Alert (50m)
      provider.arrivalStream.listen((session) {
        if (!provider.isHostMode && mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showArrivalAlert(session);
        }
      });

      // Rider: Handshake Alert (500m)
      provider.handshakeStream.listen((session) {
        if (!provider.isHostMode && mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showHandshakeAlert(session);
        }
      });

      // Unified: Overstay Alert (0:00 remaining)
      provider.overstayStream.listen((session) {
        if (!provider.isHostMode && mounted) {
           ScaffoldMessenger.of(context).clearSnackBars();
           _showOverstayAlert(session);
        }
      });

      // Unified: Departure Nudge (> 200m away)
      provider.checkoutNudgeStream.listen((session) {
        if (mounted && !provider.isHostMode) {
          ScaffoldMessenger.of(context).clearSnackBars();
          _showDepartureNudge(session);
        }
      });
    });
  }

  void _showDepartureNudge(BookingSession session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.directions_run_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leaving already?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('End your session now to release the spot.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showReviewPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your experience?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your review helps us keep the space clean and safe.', style: TextStyle(color: AppColors.secondary, fontSize: 13)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => const Icon(Icons.star_border, color: Colors.amber, size: 40)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SUBMIT REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showOverstayAlert(BookingSession session) {
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SESSION EXPIRED!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${session.spot.title} time is up.', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showHandshakeAlert(BookingSession session) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.radar, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spot Approaching!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('You are within 500m of ${session.spot.title}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'IGNORE',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange, 
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showArrivalAlert(BookingSession session) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome! You\'ve Arrived', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${session.spot.title} is now active.', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'IGNORE',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, _) {
        final List<Widget> pages = provider.isHostMode 
          ? [
              HostDashboardView(),
              MyListingsScreen(),
              ActivityScreen(),
              ProfileScreen(),
            ]
          : [
              HomeView(),
              MapScreen(),
              ActivityScreen(),
              ProfileScreen(),
            ];

        final List<BottomNavigationBarItem> navItems = provider.isHostMode
          ? [
              const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              const BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Spots'),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Rentals'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ]
          : [
              const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Activity'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              provider.isHostMode ? 'HOST DASHBOARD' : 'SPACE4U',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  tooltip: provider.isHostMode ? 'Switch to Rider' : 'Switch to Host',
                  icon: Icon(
                    provider.isHostMode ? Icons.directions_car_rounded : Icons.dashboard_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    provider.toggleHostMode();
                  },
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.surface,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: AppColors.secondary,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: navItems,
          ),
        );
      },
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, child) {
        if (!provider.isSearching) {
          // SEARCH HUB (State A) - Initial Flight Booking Mode
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SearchForm(),
                ),
                const SizedBox(height: 32),
                // Reused Garage Summary
                _buildGarageSummary(context, provider),
                const SizedBox(height: 32),
              ],
            ),
          );
        }

        // RESULTS LIST (State B) - Only shown after search submitted
        final spots = provider.parkingSpots;
        return Column(
          children: [
            // Results Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.background,
              child: Row(
                children: [
                   IconButton(
                     icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.secondary),
                     onPressed: () => provider.clearSearch(),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('Available Spaces', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                         Text('${spots.length} spots found within ${provider.searchRadius.toStringAsFixed(1)} km', 
                           style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            Expanded(
              child: spots.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: spots.length,
                  itemBuilder: (context, index) {
                    return ParkingSpotCard(spot: spots[index]);
                  },
                ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGarageSummary(BuildContext context, ParkingProvider provider) {
    final parkedCount = provider.currentParkedSessions.length;
    final upcomingCount = provider.upcomingReservations.length;
    if (parkedCount == 0 && upcomingCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSessionScreen())),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent, AppColors.accent.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.directions_car_filled, color: Colors.white)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manage My Fleet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${parkedCount} Active Session • ${upcomingCount} Upcoming', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.secondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No match found for this criteria', style: TextStyle(color: AppColors.secondary)),
          const SizedBox(height: 8),
          const Text('Try adjusting your time range or radius', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
        ],
      ),
    );
  }
}
