import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../widgets/parking_spot_card.dart';
import 'active_session_screen.dart';
import 'activity_screen.dart';
import 'profile_screen.dart';
import 'tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    const HomeView(),
    const TrackingScreen(),
    const ActivityScreen(), // Reused as tab
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.secondary,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header / Search Area
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.background,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Space4U',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.primary),
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveSessionScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) {
                  context.read<ParkingProvider>().searchSpots(value);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                  hintText: 'Where to?',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Listing Feed
        Expanded(
          child: Consumer<ParkingProvider>(
            builder: (context, provider, child) {
              final spots = provider.parkingSpots;
              if (spots.isEmpty) {
                return Center(
                  child: Text(
                    'No spots found',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: spots.length,
                itemBuilder: (context, index) {
                  return ParkingSpotCard(spot: spots[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
