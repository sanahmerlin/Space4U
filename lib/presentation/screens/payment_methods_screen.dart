import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/parking_provider.dart';
import '../../services/firestore_service.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Payment methods are stored as a subcollection under users/{uid}/paymentMethods
    // For now we show a placeholder — real card tokenization requires a payment provider.
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card, size: 64, color: AppColors.secondary),
              SizedBox(height: 16),
              Text(
                'Payment methods',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Secure card management coming soon. Integration with Stripe will be added in Phase 4.2.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
