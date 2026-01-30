import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/mock_data.dart';
import '../providers/parking_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Spots ---

  // Fetch all spots (simulating search by just fetching all then filtering client-side for MVP simplify)
  Future<List<ParkingSpot>> getSpots() async {
    // Check if we need to seed
    // For performance, in a real app we'd paginate or use Algolia.
    // MVP: Get all spots from 'spots' collection.
    
    final snapshot = await _db.collection('spots').get();
    if (snapshot.docs.isEmpty) {
      // Auto-seed if empty
      await _seedSpots();
      return MockData.parkingSpots;
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ParkingSpot(
        id: doc.id,
        title: data['title'] ?? '',
        address: data['address'] ?? '',
        pricePerHour: (data['pricePerHour'] as num).toDouble(),
        distanceKm: (data['distanceKm'] as num).toDouble(),
        imageUrl: data['imageUrl'] ?? '',
        rating: (data['rating'] as num).toDouble(),
        reviews: data['reviews'] ?? 0,
        amenities: List<String>.from(data['amenities'] ?? []),
      );
    }).toList();
  }

  Future<void> _seedSpots() async {
    final batch = _db.batch();
    for (var spot in MockData.parkingSpots) {
      final ref = _db.collection('spots').doc(spot.id);
      batch.set(ref, {
        'title': spot.title,
        'address': spot.address,
        'pricePerHour': spot.pricePerHour,
        'distanceKm': spot.distanceKm,
        'imageUrl': spot.imageUrl,
        'rating': spot.rating,
        'reviews': spot.reviews,
        'amenities': spot.amenities,
      });
    }
    await batch.commit();
  }

  // --- Bookings ---

  Future<void> createBooking({
    required String userId,
    required ParkingSpot spot,
    required int durationHours,
    required double totalCost,
  }) async {
    final now = DateTime.now();
    final endTime = now.add(Duration(hours: durationHours));
    
    await _db.collection('bookings').add({
      'userId': userId,
      'spotId': spot.id,
      'spotTitle': spot.title, // store title snapshot
      'startTime': Timestamp.fromDate(now),
      'endTime': Timestamp.fromDate(endTime),
      'durationHours': durationHours,
      'totalCost': totalCost,
      'status': 'active', // active, completed, cancelled
      'createdAt': FieldValue.serverTimestamp(),
      'spotData': {  // Store snapshot for history display
         'title': spot.title,
         'address': spot.address,
         'imageUrl': spot.imageUrl,
      }
    });
  }

  Future<void> extendBooking(String bookingId, int additionalMinutes, double addedCost) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return;
    
    final currentEnd = (doc.data()!['endTime'] as Timestamp).toDate();
    final newEnd = currentEnd.add(Duration(minutes: additionalMinutes));
    final currentCost = (doc.data()!['totalCost'] as num).toDouble();

    await _db.collection('bookings').doc(bookingId).update({
      'endTime': Timestamp.fromDate(newEnd),
      'totalCost': currentCost + addedCost,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': 'completed',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream active session for user
  Stream<List<BookingSession>> streamActiveSessions(String userId) {
    return _db.collection('bookings')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          final spotData = data['spotData'] ?? {};
          
          // Reconstruct partial spot for display
          final spot = ParkingSpot(
            id: data['spotId'],
            title: spotData['title'] ?? data['spotTitle'] ?? 'Unknown',
            address: spotData['address'] ?? '',
            pricePerHour: 0, // Not needed for active view display strictly
            distanceKm: 0,
            imageUrl: spotData['imageUrl'] ?? '',
            rating: 0,
            reviews: 0,
            amenities: [],
          );

          return BookingSession(
            id: doc.id,
            spot: spot,
            startTime: (data['startTime'] as Timestamp).toDate(),
            endTime: (data['endTime'] as Timestamp).toDate(),
            totalCost: (data['totalCost'] as num).toDouble(),
          );
        }).toList();
      });
  }
}
