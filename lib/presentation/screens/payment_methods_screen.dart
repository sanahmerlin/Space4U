import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_user_data.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: MockUserData.paymentMethods.length,
        itemBuilder: (context, index) {
          final p = MockUserData.paymentMethods[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.credit_card, color: AppColors.primary),
              title: Text('•••• •••• •••• ${p.last4}'),
              subtitle: Text(p.brand),
              trailing: p.isDefault 
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
