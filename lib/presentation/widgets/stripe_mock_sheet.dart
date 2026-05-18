import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class StripeMockSheet extends StatefulWidget {
  final double amount;
  final VoidCallback onPaymentSuccessful;

  const StripeMockSheet({
    Key? key,
    required this.amount,
    required this.onPaymentSuccessful,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required double amount, required VoidCallback onSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StripeMockSheet(amount: amount, onPaymentSuccessful: onSuccess),
    );
  }

  @override
  State<StripeMockSheet> createState() => _StripeMockSheetState();
}

class _StripeMockSheetState extends State<StripeMockSheet> {
  bool _isProcessing = false;
  bool _isSuccess = false;

  void _pay() async {
    setState(() => _isProcessing = true);
    // Simulate network delay for tokenization and charge
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      
      // Keep success checkmark visible briefly before popping
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context); // close sheet
        widget.onPaymentSuccessful();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface, // Dark theme surface
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.lock, color: Colors.greenAccent.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 24),

          // Total Amount display
          Center(
            child: Text(
              '\$${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),

          // Mock Card Input Field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.white70),
                SizedBox(width: 12),
                Text('•••• •••• •••• 4242', style: TextStyle(fontSize: 16, letterSpacing: 2)),
                Spacer(),
                Text('12/26', style: TextStyle(color: Colors.white54)),
                SizedBox(width: 8),
                Text('CVC', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Email input field for receipt
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('user@space4u.com', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(height: 24),

          // Secure by stripe mock text
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Powered by ', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('Stripe', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Pay Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing || _isSuccess ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSuccess ? Colors.green : AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSuccess
                  ? const Icon(Icons.check, color: Colors.white, size: 30)
                  : _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Pay \$${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
