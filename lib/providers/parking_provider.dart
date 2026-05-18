import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parking_spot.dart';
import '../models/vehicle.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class BookingSession {
  final String id; // Firestore Doc ID
  final ParkingSpot spot;
  final String vehicleName;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final double totalCost;
  final bool isVerified;

  BookingSession({
    this.id = '',
    required this.spot,
    this.status = 'active',
    DateTime? startTime,
    this.vehicleName = 'Default Car',
    required this.endTime,
    required this.totalCost,
    this.isVerified = false,
  }) : this.startTime = startTime ?? DateTime.now();

  bool get isUpcoming => status == 'reserved' && DateTime.now().isBefore(startTime.subtract(const Duration(minutes: 10)));

  bool get isActive => (status == 'active' || status == 'reserved' || status == 'overstaying') 
      && DateTime.now().isAfter(startTime.subtract(const Duration(minutes: 10))) 
      && DateTime.now().isBefore(endTime);

  Duration get remainingTime {
    final now = DateTime.now();
    if (isUpcoming) return startTime.difference(now);
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
}

class SpotPerformance {
  final String spotId;
  final String title;
  final double totalRevenue;
  final int occupancyCount;
  final String verificationStatus;

  SpotPerformance({
    required this.spotId,
    required this.title,
    required this.totalRevenue,
    required this.occupancyCount,
    this.verificationStatus = 'pending',
  });
}

class ParkingProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  
  FirestoreService get firestore => _firestore;
  
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Search State
  List<ParkingSpot> _allSpots = [];
  List<ParkingSpot> _filteredSpots = [];
  bool _isLoading = false;

  List<ParkingSpot> get allSpots => _allSpots;
  List<ParkingSpot> get parkingSpots => _filteredSpots;
  bool get isLoading => _isLoading;
  Position? get currentPosition => _currentPosition;
  bool isSpotConflicting(String spotId) => _conflictingSpotIds.contains(spotId);

  // Phase 7: Search-First State
  bool _isSearching = false;
  bool get isSearching => _isSearching;
  double _searchRadius = 1.5; // Default 1.5 km radius
  double get searchRadius => _searchRadius;
  String _searchLocationQuery = '';
  String get searchLocationQuery => _searchLocationQuery;
  
  void setSearchRadius(double radius) {
    _searchRadius = radius;
    notifyListeners();
  }

  // Vehicle Selection State (Unified)
  List<Vehicle> _userVehicles = [];
  List<Vehicle> get userVehicles => _userVehicles;
  
  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle;
  String? get selectedVehicleId => _selectedVehicle?.id;

  // Availability State (Reactive)
  bool _isCheckingAvailability = false;
  bool _isSpotAvailable = true;
  bool _isVehicleAvailable = true;

  bool get isCheckingAvailability => _isCheckingAvailability;
  bool get isSpotAvailable => _isSpotAvailable;
  bool get isVehicleAvailable => _isVehicleAvailable;

  // Track current validation context for auto-retriggering
  String? _lastValidatedSpotId;
  DateTime? _lastValidatedStart;
  DateTime? _lastValidatedEnd;

  Future<void> validateBooking(String spotId, DateTime start, DateTime end) async {
    _isCheckingAvailability = true;
    _lastValidatedSpotId = spotId;
    _lastValidatedStart = start;
    _lastValidatedEnd = end;
    notifyListeners();

    try {
      // 1. Check Spot Availability
      _isSpotAvailable = await _firestore.isSpotAvailable(spotId, start, end);
      
      // 2. Check Vehicle Availability (if one is selected)
      if (_selectedVehicle != null) {
        _isVehicleAvailable = await _firestore.isVehicleAvailable(
          _selectedVehicle!.id,
          start,
          end,
        );
      } else {
        _isVehicleAvailable = true;
      }
    } catch (e) {
      debugPrint('Availability check failed: $e');
    } finally {
      _isCheckingAvailability = false;
      notifyListeners();
    }
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
    
    // Auto-revalidate if we are in the middle of a booking flow
    if (_lastValidatedSpotId != null && _lastValidatedStart != null && _lastValidatedEnd != null) {
      validateBooking(_lastValidatedSpotId!, _lastValidatedStart!, _lastValidatedEnd!);
    }
  }

  void setVehicle(String? vehicleId) {
    if (vehicleId != null && _userVehicles.isNotEmpty) {
      _selectedVehicle = _userVehicles.firstWhere(
        (v) => v.id == vehicleId, 
        orElse: () => _selectedVehicle ?? _userVehicles.first
      );
    }
    notifyListeners();
  }

  void startSearch() async {
    _isLoading = true;
    _isSearching = true;
    notifyListeners();
    
    double targetLat = _currentPosition?.latitude ?? 9.9312;
    double targetLng = _currentPosition?.longitude ?? 76.2673;

    // Geocoding Logic if a specific location is provided
    if (_searchLocationQuery.isNotEmpty && _searchLocationQuery != 'Near My Location') {
      try {
        final query = Uri.encodeComponent(_searchLocationQuery.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
        final response = await http.get(url, headers: {'User-Agent': 'Space4U_App_Search'});
        
        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          if (data.isNotEmpty) {
            targetLat = double.parse(data[0]['lat'].toString());
            targetLng = double.parse(data[0]['lon'].toString());
          }
        }
      } catch (e) {
        debugPrint("Geocoding error: $e");
      }
    }

    // Filter available spots by proximity and availability
    _filteredSpots = _allSpots.where((spot) {
      final double dist = LocationService.calculateDistanceKm(
        targetLat, targetLng, spot.latitude, spot.longitude
      );
      final bool isAvailable = !_conflictingSpotIds.contains(spot.id);
      return isAvailable && dist <= _searchRadius;
    }).toList();

    // Sort by distance from target
    _filteredSpots.sort((a, b) {
       final d1 = LocationService.calculateDistanceKm(targetLat, targetLng, a.latitude, a.longitude);
       final d2 = LocationService.calculateDistanceKm(targetLat, targetLng, b.latitude, b.longitude);
       return d1.compareTo(d2);
    });

    _isLoading = false;
    notifyListeners();
  }

  void clearSearch() {
    _isSearching = false;
    notifyListeners();
  }

  void updateSearchLocation(String location) {
    _searchLocationQuery = location;
  }

  bool _isHostMode = false;

  bool get isHostMode => _isHostMode;

  void toggleHostMode() {
    _isHostMode = !_isHostMode;
    if (_isHostMode) {
      _subscribeToHostBookings();
    } else {
      _hostBookingSubscription?.cancel();
    }
    notifyListeners();
  }

  // Booking State
  List<BookingSession> _activeSessions = [];
  List<BookingSession> _hostBookings = [];
  List<BookingSession> get activeSessions => _activeSessions;
  List<BookingSession> get hostBookings => _hostBookings;

  // Advanced Analytics (Phase 3: Host Cockpit)
  Map<int, double> get weeklyRevenueTrend {
    final Map<int, double> trends = {};
    final now = DateTime.now();
    
    // Initialize with 0 for all 7 days of the week
    for (int i = 1; i <= 7; i++) trends[i] = 0;

    for (var booking in _hostBookings) {
      final date = booking.endTime;
      final diff = now.difference(date).inDays;
      if (diff < 7) {
        final day = date.weekday;
        trends[day] = (trends[day] ?? 0) + booking.totalCost;
      }
    }
    return trends;
  }

  List<SpotPerformance> get spotPerformanceList {
    final Map<String, SpotPerformance> stats = {};
    
    // 1. Initialize with ALL host-owned spots from the Firestore stream
    // We'll use a local mapping of the host's current spots
    for (var spot in _allSpots.where((s) => s.ownerId == _currentUser?.uid)) {
      stats[spot.id] = SpotPerformance(
        spotId: spot.id,
        title: spot.title,
        totalRevenue: 0.0,
        occupancyCount: 0,
        verificationStatus: spot.verificationStatus,
      );
    }

    // 2. Aggregate earnings from bookings
    for (var booking in _hostBookings) {
      final spot = booking.spot;
      if (stats.containsKey(spot.id)) {
        final existing = stats[spot.id]!;
        stats[spot.id] = SpotPerformance(
          spotId: spot.id,
          title: spot.title,
          totalRevenue: existing.totalRevenue + booking.totalCost,
          occupancyCount: existing.occupancyCount + 1,
          verificationStatus: existing.verificationStatus,
        );
      } else {
        // Fallback for cases where a spot might have bookings but isn't in _allSpots yet
        stats[spot.id] = SpotPerformance(
          spotId: spot.id,
          title: spot.title,
          totalRevenue: booking.totalCost,
          occupancyCount: 1,
          verificationStatus: 'verified', // If it has bookings, it's likely verified
        );
      }
    }
    final list = stats.values.toList();
    list.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return list;
  }
  
  // Categorized Session Getters
  List<BookingSession> get currentParkedSessions => _activeSessions.where((s) => s.status == 'active').toList();
  List<BookingSession> get upcomingReservations => _activeSessions.where((s) => s.status == 'reserved').toList();
  
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _hostBookingSubscription;
  StreamSubscription? _occupancySubscription;
  Set<String> _conflictingSpotIds = {};

  Timer? _timer;
  Timer? _locationTimer;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _vehicleSubscription;
  Position? _currentPosition;

  DateTime _searchStartTime = DateTime.now().add(const Duration(minutes: 5));
  DateTime _searchEndTime = DateTime.now().add(const Duration(hours: 1, minutes: 5));
  
  DateTime get searchStartTime => _searchStartTime;
  DateTime get searchEndTime => _searchEndTime;

  // Arrival & Handshake Triggers (Phase 5)
  final StreamController<BookingSession> _arrivalController = StreamController<BookingSession>.broadcast();
  Stream<BookingSession> get arrivalStream => _arrivalController.stream;

  final StreamController<BookingSession> _handshakeController = StreamController<BookingSession>.broadcast();
  Stream<BookingSession> get handshakeStream => _handshakeController.stream;

  final StreamController<BookingSession> _overstayController = StreamController<BookingSession>.broadcast();
  Stream<BookingSession> get overstayStream => _overstayController.stream;

  final StreamController<BookingSession> _checkoutNudgeController = StreamController<BookingSession>.broadcast();
  Stream<BookingSession> get checkoutNudgeStream => _checkoutNudgeController.stream;

  final Set<String> _notifiedArrivalIds = {};
  final Set<String> _notifiedHandshakeIds = {};
  final Set<String> _notifiedOverstayIds = {};
  final Set<String> _notifiedDepartureIds = {};
  final Set<String> _approachingSessionIds = {};
  
  Set<String> get approachingSessionIds => _approachingSessionIds;
  bool isVerified(String sessionId) {
    try {
      final session = _activeSessions.firstWhere((s) => s.id == sessionId);
      return session.isVerified;
    } catch (_) {
      return false;
    }
  }

  ParkingProvider() {
    // Listen to Auth Changes
    _auth.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _initUser();
      } else {
        _activeSessions = [];
        _sessionSubscription?.cancel();
        _occupancySubscription?.cancel();
        _vehicleSubscription?.cancel();
        _filteredSpots = []; // Clear data on logout
        notifyListeners();
      }
    });
  }

  void _initUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Fetch Spots (Public Verified + Personal)
    final publicSpots = await _firestore.getSpots();
    final mySpots = await _firestore.getMySpots(_currentUser!.uid);
    
    // Merge without duplicates
    final Map<String, ParkingSpot> merged = {};
    for (var s in publicSpots) merged[s.id] = s;
    for (var s in mySpots) merged[s.id] = s;
    _allSpots = merged.values.toList();
    
    // Initial Distance calculation
    await _updateCurrentPosition();
    _calculateAllDistances();
    
    // Listen to Active Sessions (Current User)
    _subscribeToSessions();
    
    // Listen to ALL Occupied Spots (Global)
    _subscribeToOccupancy();
    
    // Periodic Location Updates (30s)
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateCurrentPosition();
      _calculateAllDistances();
      notifyListeners();
    });
    
    _isLoading = false;
    notifyListeners();
    
    // Listen to Vehicles
    _subscribeToVehicles();
    
    // Start High-Frequency tracking for active navigation
    _startPositionStream();
  }

  void _subscribeToVehicles() {
    if (_currentUser == null) return;
    _vehicleSubscription?.cancel();
    _vehicleSubscription = _firestore.streamVehicles(_currentUser!.uid).listen((vehicles) {
      _userVehicles = vehicles;
      if (_selectedVehicle == null && vehicles.isNotEmpty) {
        _selectedVehicle = vehicles.firstWhere((v) => v.isDefault, orElse: () => vehicles.first);
      }
      notifyListeners();
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 meters for smooth movement
      ),
    ).listen((position) {
      _currentPosition = position;
      _calculateAllDistances();
      notifyListeners();
    });
  }

  void _subscribeToOccupancy() {
    _occupancySubscription?.cancel();
    _occupancySubscription = _firestore.streamAllOccupiedSpotIds().listen((ids) {
      _refreshConflicts(); // Trigger secondary cleanup
      _calculateAllDistances();
      notifyListeners();
    });
  }

  Future<void> _refreshConflicts() async {
    final ids = await _firestore.getConflictingSpotIds(_searchStartTime, _searchEndTime);
    _conflictingSpotIds = ids;
    _calculateAllDistances();
    notifyListeners();
  }

  Future<void> refreshSpots() async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    
    final publicSpots = await _firestore.getSpots();
    final mySpots = await _firestore.getMySpots(_currentUser!.uid);
    
    // Merge without duplicates
    final Map<String, ParkingSpot> merged = {};
    for (var s in publicSpots) merged[s.id] = s;
    for (var s in mySpots) merged[s.id] = s;
    _allSpots = merged.values.toList();
    
    _calculateAllDistances();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateCurrentPosition() async {
    try {
      _currentPosition = await LocationService.determinePosition();
    } catch (e) {
      debugPrint("Position error: $e");
    }
  }

  void _calculateAllDistances() {
    // Default to Kochi center if GPS is unavailable during mobile testing
    final double userLat = _currentPosition?.latitude ?? 9.9312;
    final double userLng = _currentPosition?.longitude ?? 76.2673;
    
    for (int i = 0; i < _allSpots.length; i++) {
      final spot = _allSpots[i];
      final double distance = LocationService.calculateDistanceKm(
        userLat,
        userLng,
        spot.latitude,
        spot.longitude,
      );
      
      _allSpots[i] = ParkingSpot(
        id: spot.id,
        ownerId: spot.ownerId,
        title: spot.title,
        address: spot.address,
        latitude: spot.latitude,
        longitude: spot.longitude,
        pricePerHour: spot.pricePerHour,
        distanceKm: distance,
        imageUrl: spot.imageUrl,
        rating: spot.rating,
        reviews: spot.reviews,
        amenities: spot.amenities,
        arrivalInstructions: spot.arrivalInstructions,
        verificationStatus: spot.verificationStatus,
      );
    }
    
    // Performance Optimization: If in Host Mode, skip Rider geofencing logic
    if (_isHostMode) {
      if (!_isSearching) {
        final allSorted = List<ParkingSpot>.from(_allSpots);
        allSorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        _filteredSpots = allSorted;
      }
      return;
    }
    
    // Phase 5: Geofencing for Active Sessions
    for (var session in _activeSessions) {
      if (session.status == 'active' || session.status == 'reserved') {
        final double dist = LocationService.calculateDistanceKm(
          userLat,
          userLng,
          session.spot.latitude,
          session.spot.longitude,
        );
        
        // Handshake: Within 500 meters (0.5 km)
        if (dist <= 0.5 && session.status == 'reserved') {
          _approachingSessionIds.add(session.id);
          if (!_notifiedHandshakeIds.contains(session.id)) {
            _notifiedHandshakeIds.add(session.id);
            _handshakeController.add(session);
          }
        } else {
          _approachingSessionIds.remove(session.id);
        }

        // Arrival: Within 50 meters (0.05 km)
        if (dist <= 0.05 && !_notifiedArrivalIds.contains(session.id)) {
          _notifiedArrivalIds.add(session.id);
          
          // AUTO-ACTIVATE: If it was reserved, it's now active!
          if (session.status == 'reserved') {
            updateSessionStatus(session.id, 'active');
            _approachingSessionIds.remove(session.id);
          }
          
          _arrivalController.add(session);
        }

        // Departure: More than 200 meters (0.2 km) away while active/overstaying
        if (dist > 0.2 && (session.status == 'active' || session.status == 'overstaying')) {
          if (!_notifiedDepartureIds.contains(session.id)) {
            _notifiedDepartureIds.add(session.id);
            _checkoutNudgeController.add(session);
          }
          
          // AUTO-RELEASE: If more than 1km away, force-release the spot
          if (dist > 1.0) {
            endSession(session.id);
          }
        }
      }
    }

    // Phase 6: Permanent Inventory - No filtering, just sorting (ONLY if NOT searching)
    if (!_isSearching) {
      final allSorted = List<ParkingSpot>.from(_allSpots);
      allSorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      _filteredSpots = allSorted;
    } else {
      // In Search Mode: Just update the distance of existing results from the allSpots pool
      _filteredSpots = _filteredSpots.map((f) {
         return _allSpots.firstWhere((a) => a.id == f.id, orElse: () => f);
      }).toList();
    }
  }

  void _subscribeToSessions() {
    if (_currentUser == null) return;
    
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore.streamActiveSessions(_currentUser!.uid).listen((sessions) {
      _activeSessions = sessions;
      if (sessions.isNotEmpty) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> updateSearchTime(DateTime start, DateTime end) async {
    _searchStartTime = start;
    // Auto-correction: If end is before or equal to start, nudge it forward by 1 hour
    if (!end.isAfter(start)) {
      _searchEndTime = start.add(const Duration(hours: 1));
    } else {
      _searchEndTime = end;
    }
    await _refreshConflicts(); 
    notifyListeners();
  }

  void _subscribeToHostBookings() {
    if (_currentUser == null) return;
    _hostBookingSubscription?.cancel();
    _hostBookingSubscription = _firestore.streamHostBookings(_currentUser!.uid).listen((bookings) {
      _hostBookings = bookings;
      notifyListeners();
    });
  }

  // Search Logic
  void searchSpots(String query) {
    final availableSpots = _allSpots.where((s) => !_conflictingSpotIds.contains(s.id)).toList();
    if (query.isEmpty) {
      _filteredSpots = availableSpots;
    } else {
      _filteredSpots = availableSpots.where((spot) {
        return spot.title.toLowerCase().contains(query.toLowerCase()) ||
               spot.address.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // Start Booking
  Future<String?> startBooking(ParkingSpot spot, DateTime start, DateTime end) async {
    if (_currentUser == null || _selectedVehicle == null) return null;
    
    // Server-side safety check
    final spotAvailable = await _firestore.isSpotAvailable(spot.id, start, end);
    final vehicleAvailable = await _firestore.isVehicleAvailable(_selectedVehicle!.id, start, end);
    
    if (!spotAvailable || !vehicleAvailable) {
      debugPrint("Booking failed: Spot or Vehicle no longer available.");
      return null;
    }

    final duration = end.difference(start);
    final hours = duration.inMinutes / 60.0;
    final cost = spot.pricePerHour * hours;

    final String bookingId = await _firestore.createBookingWithVehicle(
      userId: _currentUser!.uid,
      spot: spot,
      startTime: start,
      endTime: end,
      totalCost: cost,
      vehicle: _selectedVehicle!,
    );
    
    return bookingId;
  }

  // Extend Session
  Future<void> extendSession(String bookingId, int additionalMinutes, double additionalCost) async {
    await _firestore.extendBooking( 
      bookingId,
      additionalMinutes,
      additionalCost,
    );
  }

  // Update session status (e.g. for auto-starting)
  Future<void> updateSessionStatus(String bookingId, String newStatus) async {
    await _firestore.updateBookingStatus(bookingId, newStatus);
  }

  // End Session
  Future<void> deleteSpot(String spotId) async {
    await _firestore.deleteSpot(spotId);
    await refreshSpots();
  }

  Future<void> verifySpot(String spotId) async {
    await _firestore.verifySpotManually(spotId);
    await refreshSpots();
  }

  Future<void> endSession(String bookingId) async {
    await _firestore.endBooking(bookingId);
    // Stream updates UI automatically
  }

  // QR Verification (Phase 4)
  Future<bool> verifySessionWithQR(String sessionId, String qrData) async {
    final session = _activeSessions.firstWhere((s) => s.id == sessionId);
    
    // Check for Checkout Suffix
    if (qrData == '${session.spot.id}-checkout') {
      await endSession(sessionId);
      return true;
    }

    // Check for standard ID match (Verify Spot)
    if (qrData == session.spot.id) {
       await _firestore.markBookingVerified(sessionId);
       return true;
    }

    return false;
  }

  // History State
  List<BookingSession> _pastBookings = [];
  List<BookingSession> get pastBookings => _pastBookings;

  Future<void> fetchHistory() async {
    if (_currentUser == null) return;
    _pastBookings = await _firestore.getPastBookings(_currentUser!.uid);
    notifyListeners();
  }

  // Timer for UI updates
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSessions.isEmpty) {
        timer.cancel();
        return;
      }

      // Auto-cleanup and Auto-start sessions
      for (var session in _activeSessions) {
        // OVERSTAY DETECTION
        if (session.status == 'active' && session.remainingTime == Duration.zero) {
           _firestore.updateBookingStatus(session.id, 'overstaying');
           if (!_notifiedOverstayIds.contains(session.id)) {
             _notifiedOverstayIds.add(session.id);
             _overstayController.add(session);
           }
        }
        
        // Auto-End (For overstaying sessions that passed a long time, or just regular completion)
        // Note: For now, we'll keep them in 'overstaying' until host/rider ends them manually or logic added here
        
        // Auto-Start (Convert Reserved -> Active)
        if (session.status == 'reserved' && session.isActive) {
           updateSessionStatus(session.id, 'active');
        }
      }
      
      // Optimization: Only notify listeners if we have active sessions to avoid unnecessary dashboard rebuilds
      if (!_isHostMode) {
        notifyListeners();
      }
    });
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _filteredSpots = [];
    _activeSessions = [];
    _hostBookings = [];
    _isHostMode = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _sessionSubscription?.cancel();
    _occupancySubscription?.cancel();
    _positionSubscription?.cancel();
    _vehicleSubscription?.cancel();
    _arrivalController.close();
    _handshakeController.close();
    _overstayController.close();
    _checkoutNudgeController.close();
    super.dispose();
  }
}
