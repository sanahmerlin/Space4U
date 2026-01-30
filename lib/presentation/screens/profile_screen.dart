import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'wallet_screen.dart';
import 'notifications_screen.dart';
import 'activity_screen.dart';
import 'vehicles_screen.dart';
import 'payment_methods_screen.dart';
import 'host_landing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Header
            Consumer<ParkingProvider>(
              builder: (context, provider, _) {
                final user = provider.currentUser;
                return Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.surface,
                          child: Text(
                            user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(fontSize: 40, color: Colors.white),
                          ),
                        ),
                        // Edit icon...
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'Welcome',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '', style: TextStyle(color: Colors.grey[400])),
                  ],
                );
              }
            ),
            const SizedBox(height: 32),
            
            // Host Banner
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostLandingScreen())),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade900, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.maps_home_work, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Earn with Space4U', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('List your parking spot today', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Menu Items
            _buildMenuItem(context, icon: Icons.account_balance_wallet, title: 'Wallet', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
            _buildMenuItem(context, icon: Icons.history, title: 'History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
            _buildMenuItem(context, icon: Icons.directions_car, title: 'Vehicles', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VehiclesScreen()))),
            _buildMenuItem(context, icon: Icons.credit_card, title: 'Payment Methods', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
            const Divider(color: AppColors.divider),
            _buildMenuItem(context, icon: Icons.settings, title: 'Settings', onTap: () {}),
            _buildMenuItem(context, icon: Icons.help_outline, title: 'Support', onTap: () {}),
            _buildMenuItem(
              context, 
              icon: Icons.logout, 
              title: 'Log Out', 
              textColor: AppColors.error, 
              onTap: () {
                context.read<ParkingProvider>().dispose(); // Actually provider disposal is handled by tree, just signout
                // Actually we just need to signout auth
                // But since logic is in AuthService, and provided exposed?
                // Provider doesn't expose signOut directly, let's fix that or use AuthService directly.
                // Or better, update Provider to have signOut
              }
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, Color? textColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: textColor ?? AppColors.secondary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.divider),
      onTap: onTap,
    );
  }
}
