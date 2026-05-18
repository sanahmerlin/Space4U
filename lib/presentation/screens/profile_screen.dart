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
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Integrated Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          // User Header
          Consumer<ParkingProvider>(
            builder: (context, provider, _) {
              final user = provider.currentUser;
              return Column(
                children: [
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.surface,
                        child: Text(
                          user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'Welcome',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          const SizedBox(height: 24),
          
          // Menu Items
          _buildMenuItem(context, icon: Icons.account_balance_wallet, title: 'Wallet', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
          _buildMenuItem(context, icon: Icons.history, title: 'History', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()))),
          _buildMenuItem(context, icon: Icons.maps_home_work, title: 'My Listings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsScreen()))),
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
              context.read<ParkingProvider>().signOut();
            }
          ),
          
          const SizedBox(height: 40),
        ],
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
