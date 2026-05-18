class ParkingSpot {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerHour;
  final double distanceKm;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> amenities;
  final String arrivalInstructions;
  final String ownerId;
  final String verificationStatus; // 'pending', 'verified', 'rejected'

  const ParkingSpot({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerHour,
    required this.distanceKm,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.amenities,
    this.arrivalInstructions = '',
    this.verificationStatus = 'pending',
  });
}
