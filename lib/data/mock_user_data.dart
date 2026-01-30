
class UserVehicle {
  final String id;
  final String name;
  final String licensePlate;
  final bool isDefault;

  const UserVehicle({
    required this.id,
    required this.name,
    required this.licensePlate,
    this.isDefault = false,
  });
}

class PaymentMethod {
  final String id;
  final String last4;
  final String brand; // Visa, Mastercard
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.last4,
    required this.brand,
    this.isDefault = false,
  });
}

class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCredit;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCredit,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
  });
}

class PastBooking {
  final String id;
  final String spotTitle;
  final String spotAddress;
  final String imageUrl;
  final double totalCost;
  final DateTime date;
  final String duration;

  const PastBooking({
    required this.id,
    required this.spotTitle,
    required this.spotAddress,
    required this.imageUrl,
    required this.totalCost,
    required this.date,
    required this.duration,
  });
}

class MockUserData {
  static const List<UserVehicle> vehicles = [
    UserVehicle(id: '1', name: 'Toyota Prius', licensePlate: 'ABC-1234', isDefault: true),
    UserVehicle(id: '2', name: 'Tesla Model 3', licensePlate: 'ELN-X99'),
  ];

  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', last4: '4242', brand: 'Visa', isDefault: true),
    PaymentMethod(id: '2', last4: '8888', brand: 'Mastercard'),
  ];

  static final List<WalletTransaction> walletTransactions = [
    WalletTransaction(id: '1', title: 'Top Up', amount: 50.00, date: DateTime.now().subtract(const Duration(days: 2)), isCredit: true),
    WalletTransaction(id: '2', title: 'Parking: Downtown Lot', amount: 12.50, date: DateTime.now().subtract(const Duration(days: 5)), isCredit: false),
    WalletTransaction(id: '3', title: 'Parking: Mission Dist', amount: 8.00, date: DateTime.now().subtract(const Duration(days: 10)), isCredit: false),
    WalletTransaction(id: '4', title: 'New User Bonus', amount: 10.00, date: DateTime.now().subtract(const Duration(days: 30)), isCredit: true),
  ];

  static final List<NotificationItem> notifications = [
    NotificationItem(id: '1', title: 'Session Ended', body: 'Your parking session at Downtown Lot has ended.', date: DateTime.now().subtract(const Duration(hours: 2))),
    NotificationItem(id: '2', title: 'Wallet Top Up', body: 'Successful top up of \$50.00.', date: DateTime.now().subtract(const Duration(days: 2))),
    NotificationItem(id: '3', title: 'Welcome to Space4U!', body: 'Find your perfect spot today.', date: DateTime.now().subtract(const Duration(days: 30)), isRead: true),
  ];

  static final List<PastBooking> history = [
    PastBooking(
      id: '1', 
      spotTitle: 'Downtown Secure Lot', 
      spotAddress: '123 Market St', 
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=1000', 
      totalCost: 12.50, 
      date: DateTime.now().subtract(const Duration(days: 5)),
      duration: '2h 15m',
    ),
    PastBooking(
      id: '2', 
      spotTitle: 'Mission District Spot', 
      spotAddress: '101 Valencia St', 
      imageUrl: 'https://images.unsplash.com/photo-1590674899505-1c5c41951f89?auto=format&fit=crop&q=80&w=1000', 
      totalCost: 8.00, 
      date: DateTime.now().subtract(const Duration(days: 10)),
      duration: '1h 30m',
    ),
  ];
}
