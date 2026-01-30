import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import 'tracking_screen.dart';
import 'home_screen.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({Key? key}) : super(key: key);

  void _showExtendModal(BuildContext context) {
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

  void _endSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('End Session?', style: TextStyle(color: AppColors.primary)),
        content: const Text('Are you sure you want to end your parking session early?', style: TextStyle(color: AppColors.secondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<ParkingProvider>().endSession();
               Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ParkingProvider>(
      builder: (context, provider, child) {
        final session = provider.activeSession;

        if (session == null) {
          return Scaffold(
             appBar: AppBar(title: const Text('Active Session')),
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('No active session'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed:() => Navigator.pop(context), 
                     child: const Text('Go Home')
                   )
                 ],
               ),
             ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Active Session'),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Timer Circle
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDuration(session.remainingTime),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('REMAINING', style: TextStyle(color: AppColors.accent, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildRow(context, 'Location', session.spot.title),
                      const Divider(color: AppColors.divider, height: 24),
                      _buildRow(context, 'Vehicle', 'Toyota Prius (ABC-123)'), // Mock
                      const Divider(color: AppColors.divider, height: 24),
                      _buildRow(context, 'Total Cost', '\$${session.totalCost.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TrackingScreen()),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Track Vehicle', style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showExtendModal(context),
                        child: const Text('Extend'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _endSession(context),
                  child: const Text('End Session', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
        );
      },
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
                      // Simplified cost calculation logic for mock: $1 per 15 mins? 
                      // Or just base it on spot price if we had it handy. 
                      // For now, let's assume a flat rate or retrieve spot from provider if we wanted to be precise.
                      // We will use a safe default cost update of 2.0.
                      context.read<ParkingProvider>().extendSession(_selectedMinutes!, 2.0);
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
