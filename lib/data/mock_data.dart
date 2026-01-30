class ParkingSpot {
  final String id;
  final String title;
  final String address;
  final double pricePerHour;
  final double distanceKm;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> amenities;

  ParkingSpot({
    required this.id,
    required this.title,
    required this.address,
    required this.pricePerHour,
    required this.distanceKm,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.amenities,
  });
}

class MockData {
  static final List<ParkingSpot> parkingSpots = [
    ParkingSpot(
      id: '1',
      title: 'Downtown Secure Lot',
      address: '123 Market St, San Francisco',
      pricePerHour: 5.50,
      distanceKm: 0.8,
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=1000',
      rating: 4.8,
      reviews: 124,
      amenities: ['CCTV', 'Covered', '24/7 Access'],
    ),
    ParkingSpot(
      id: '2',
      title: 'Private Driveway - Sunset District',
      address: '456 Irving St, San Francisco',
      pricePerHour: 3.00,
      distanceKm: 2.1,
      imageUrl: 'https://images.unsplash.com/photo-1522050212171-61b01dd2c579?auto=format&fit=crop&q=80&w=1000',
      rating: 5.0,
      reviews: 12,
      amenities: ['Gated', 'Well Lit'],
    ),
    ParkingSpot(
      id: '3',
      title: 'SoMa Business Parking',
      address: '789 Howard St, San Francisco',
      pricePerHour: 7.00,
      distanceKm: 1.2,
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=1000',
      rating: 4.5,
      reviews: 89,
      amenities: ['EV Charging', 'CCTV', 'Security Guard'],
    ),
     ParkingSpot(
      id: '4',
      title: 'Mission District Spot',
      address: '101 Valencia St, San Francisco',
      pricePerHour: 4.25,
      distanceKm: 3.5,
      imageUrl: 'https://images.unsplash.com/photo-1590674899505-1c5c41951f89?auto=format&fit=crop&q=80&w=1000',
      rating: 4.7,
      reviews: 45,
      amenities: ['24/7 Access', 'Wide Space'],
    ),
  ];
}
