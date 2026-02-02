import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class BookingSession {
  final String id; // Firestore Doc ID
  final ParkingSpot spot;
  DateTime startTime;
  DateTime endTime;
  double totalCost;

  BookingSession({
    this.id = '',
    required this.spot,
    required this.startTime,
    required this.endTime,
    required this.totalCost,
  });

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
}

class ParkingProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Search State
  List<ParkingSpot> _allSpots = [];
  List<ParkingSpot> _filteredSpots = [];
  bool _isLoading = false;

  List<ParkingSpot> get parkingSpots => _filteredSpots;
  bool get isLoading => _isLoading;

  // Booking State
  BookingSession? _activeSession;
  BookingSession? get activeSession => _activeSession;
  StreamSubscription? _sessionSubscription;

  Timer? _timer;

  ParkingProvider() {
    // Listen to Auth Changes
    _auth.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _initUser();
      } else {
        _activeSession = null;
        _sessionSubscription?.cancel();
        _filteredSpots = []; // Clear data on logout
        notifyListeners();
      }
    });
  }

  void _initUser() async {
    _isLoading = true;
    notifyListeners();
    
    // Fetch Spots
    _allSpots = await _firestore.getSpots();
    _filteredSpots = _allSpots;
    
    // Listen to Active Sessions
    _subscribeToSessions();
    
    _isLoading = false;
    notifyListeners();
  }

  void _subscribeToSessions() {
    if (_currentUser == null) return;
    
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore.streamActiveSessions(_currentUser!.uid).listen((sessions) {
      if (sessions.isNotEmpty) {
        // Just take the first active one for MVP
        _activeSession = sessions.first;
        _startTimer();
      } else {
        _activeSession = null;
        _timer?.cancel();
      }
      notifyListeners();
    });
  }

  // Search Logic
  void searchSpots(String query) {
    if (query.isEmpty) {
      _filteredSpots = _allSpots;
    } else {
      _filteredSpots = _allSpots.where((spot) {
        return spot.title.toLowerCase().contains(query.toLowerCase()) ||
               spot.address.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  // Start Booking
  Future<void> startBooking(ParkingSpot spot, int durationHours) async {
    if (_currentUser == null) return;
    
    final cost = spot.pricePerHour * durationHours;
    await _firestore.createBooking(
      userId: _currentUser!.uid,
      spot: spot,
      durationHours: durationHours,
      totalCost: cost,
    );
    // Stream will update _activeSession automatically
  }

  // Extend Session
  Future<void> extendSession(int additionalMinutes, double additionalCost) async {
    if (_activeSession == null) return;
    
    await _firestore.extendBooking( // We need booking ID in session now
      _activeSession!.id,
      additionalMinutes,
      additionalCost,
    );
  }

  // End Session
  Future<void> endSession() async {
    if (_activeSession == null) return;
    await _firestore.endBooking(_activeSession!.id);
    // Stream updates UI
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
      if (_activeSession == null) {
        timer.cancel();
        return;
      }
      notifyListeners();
    });
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _filteredSpots = [];
    _activeSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
