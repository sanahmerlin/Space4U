import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/mock_user_data.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '\$45.50',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Top Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.accent,
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Transactions
            Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: MockUserData.walletTransactions.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
              itemBuilder: (context, index) {
                final tx = MockUserData.walletTransactions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: tx.isCredit ? AppColors.success : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM d, h:mm a').format(tx.date)),
                  trailing: Text(
                    '${tx.isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: tx.isCredit ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
