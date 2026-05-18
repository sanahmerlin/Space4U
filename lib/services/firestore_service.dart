import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_spot.dart';
import '../models/vehicle.dart';
import '../providers/parking_provider.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── SPOTS ────────────────────────────────────────────────────────────────

  Future<List<ParkingSpot>> getSpots() async {
    final snapshot = await _db
        .collection('spots')
        .where('verificationStatus', isEqualTo: 'verified')
        .get();
    return snapshot.docs.map((doc) => _mapDocToSpot(doc)).toList();
  }

  Future<List<ParkingSpot>> getMySpots(String ownerId) async {
    final snapshot = await _db
        .collection('spots')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs.map((doc) => _mapDocToSpot(doc)).toList();
  }

  Future<void> addSpot({
    required String ownerId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    required double pricePerHour,
    required double distanceKm,
    required String imageUrl,
    required List<String> amenities,
    required String arrivalInstructions,
  }) async {
    await _db.collection('spots').add({
      'ownerId': ownerId,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'pricePerHour': pricePerHour,
      'distanceKm': distanceKm,
      'imageUrl': imageUrl,
      'rating': 0.0,
      'reviews': 0,
      'amenities': amenities,
      'arrivalInstructions': arrivalInstructions,
      'verificationStatus': 'pending', // Phase 4: Trust Architecture
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamMySpots(String ownerId) {
    return _db
        .collection('spots')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> deleteSpot(String spotId) async {
    await _db.collection('spots').doc(spotId).delete();
  }

  Future<void> verifySpotManually(String spotId) async {
    await _db.collection('spots').doc(spotId).update({
      'verificationStatus': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  ParkingSpot _mapDocToSpot(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSpot(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (data['longitude'] as num?)?.toDouble() ?? -122.4194,
      pricePerHour: (data['pricePerHour'] as num).toDouble(),
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      amenities: List<String>.from(data['amenities'] ?? []),
      arrivalInstructions: data['arrivalInstructions'] ?? '',
      verificationStatus: data['verificationStatus'] ?? 'pending',
    );
  }

  // ─── BOOKINGS ─────────────────────────────────────────────────────────────

  Future<void> createBooking({
    required String userId,
    required ParkingSpot spot,
    required int durationHours,
    required double totalCost,
  }) async {
    final Map<String, dynamic> bookingData = {
      'userId': userId,
      'spotId': spot.id,
      'hostId': spot.ownerId, // Added hostId for marketplace tracking
      'startTime': FieldValue.serverTimestamp(),
      'endTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: durationHours))),
      'status': 'active',
      'totalCost': totalCost,
      'vehicleId': 'unknown',
      'vehicleName': 'Default Car',
      'spotData': {
        'title': spot.title,
        'address': spot.address,
        'imageUrl': spot.imageUrl,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
      }
    };

    await _db.collection('bookings').add(bookingData);
  }

  Future<String> createBookingWithVehicle({
    required String userId,
    required ParkingSpot spot,
    required DateTime startTime,
    required DateTime endTime,
    required double totalCost,
    required Vehicle vehicle,
  }) async {
    final status = startTime.isAfter(DateTime.now()) ? 'reserved' : 'active';
    
    final docRef = await _db.collection('bookings').add({
      'userId': userId,
      'spotId': spot.id,
      'hostId': spot.ownerId, // Added hostId for marketplace tracking
      'vehicleId': vehicle.id,
      'vehicleName': vehicle.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'totalCost': totalCost,
      'spotData': {
        'title': spot.title,
        'address': spot.address,
        'imageUrl': spot.imageUrl,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
      }
    });

    return docRef.id;
  }

  Stream<List<BookingSession>> streamHostBookings(String hostId) {
    return _db
        .collection('bookings')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snap) => snap.docs.map(_mapDocToSession).toList());
  }

  Future<bool> isSpotAvailable(String spotId, DateTime start, DateTime end) async {
    final snap = await _db
        .collection('bookings')
        .where('spotId', isEqualTo: spotId)
        .where('status', whereIn: ['active', 'reserved'])
        .get();

    for (var doc in snap.docs) {
      final existingStart = (doc['startTime'] as Timestamp).toDate();
      final existingEnd = (doc['endTime'] as Timestamp).toDate();

      // Skip expired sessions that haven't triggered auto-end yet
      if (existingEnd.isBefore(DateTime.now())) continue;

      // Conflict logic: (Start1 < End2) AND (End1 > Start2)
      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return false;
      }
    }
    return true;
  }

  Future<Set<String>> getConflictingSpotIds(DateTime start, DateTime end) async {
    final snap = await _db
        .collection('bookings')
        .where('status', whereIn: ['active', 'reserved'])
        .get();

    final Set<String> conflictingIds = {};
    for (var doc in snap.docs) {
      final existingStart = (doc['startTime'] as Timestamp).toDate();
      final existingEnd = (doc['endTime'] as Timestamp).toDate();

      if (existingEnd.isBefore(DateTime.now())) continue;

      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        conflictingIds.add(doc['spotId'] as String);
      }
    }
    return conflictingIds;
  }

  Future<bool> isVehicleAvailable(String vehicleId, DateTime start, DateTime end) async {
    final snap = await _db
        .collection('bookings')
        .where('vehicleId', isEqualTo: vehicleId)
        .where('status', whereIn: ['active', 'reserved'])
        .get();

    for (var doc in snap.docs) {
      final existingStart = (doc['startTime'] as Timestamp).toDate();
      final existingEnd = (doc['endTime'] as Timestamp).toDate();

      // Skip expired sessions that haven't triggered auto-end yet
      if (existingEnd.isBefore(DateTime.now())) continue;

      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return false;
      }
    }
    return true;
  }

  Future<void> extendBooking(
      String bookingId, int additionalMinutes, double addedCost) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    if (!doc.exists) return;
    final currentEnd =
        (doc.data()!['endTime'] as Timestamp).toDate();
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

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markBookingVerified(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<BookingSession>> streamActiveSessions(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'reserved'])
        .snapshots()
        .map((snap) => snap.docs.map(_mapDocToSession).toList());
  }

  Stream<List<String>> streamAllOccupiedSpotIds() {
    return _db
        .collection('bookings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['spotId'] as String)
            .toList());
  }

  Future<List<BookingSession>> getPastBookings(String userId) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('endTime', descending: true)
        .get();
    return snap.docs.map(_mapDocToSession).toList();
  }

  BookingSession _mapDocToSession(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final spotData = data['spotData'] ?? {};
    final spot = ParkingSpot(
      id: data['spotId'] ?? '',
      ownerId: data['hostId'] ?? '', // Added hostId mapping
      title: spotData['title'] ?? data['spotTitle'] ?? 'Unknown',
      address: spotData['address'] ?? '',
      latitude: (spotData['latitude'] as num?)?.toDouble() ?? 37.7749,
      longitude: (spotData['longitude'] as num?)?.toDouble() ?? -122.4194,
      pricePerHour: 0,
      distanceKm: 0,
      imageUrl: spotData['imageUrl'] ?? '',
      rating: 0,
      reviews: 0,
      amenities: [],
      arrivalInstructions: data['arrivalInstructions'] ?? '',
    );
    return BookingSession(
      id: doc.id,
      spot: spot,
      status: data['status'] ?? 'active',
      vehicleName: data['vehicleName'] ?? 'Default Car',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      totalCost: (data['totalCost'] as num).toDouble(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  // ─── USER VEHICLES ────────────────────────────────────────────────────────

  Stream<List<Vehicle>> streamVehicles(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Vehicle.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> addVehicle(
      String userId, String name, String plate, bool isDefault) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .add({
      'name': name,
      'licensePlate': plate,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .delete();
  }

  // ─── WALLET ───────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> streamWallet(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return {
        'balance': (data['walletBalance'] as num?)?.toDouble() ?? 0.0,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> streamWalletTransactions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('walletTransactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> markNotificationRead(String userId, String notifId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  // ─── WALLET TOP-UP ────────────────────────────────────────────────────────

  Future<void> topUpWallet(String userId, double amount) async {
    final userRef = _db.collection('users').doc(userId);
    final txRef = userRef.collection('walletTransactions').doc();

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final currentBalance =
          (userSnap.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;

      tx.update(userRef, {'walletBalance': currentBalance + amount});
      tx.set(txRef, {
        'title': 'Top Up',
        'amount': amount,
        'isCredit': true,
        'date': FieldValue.serverTimestamp(),
      });
    });
  }
}
