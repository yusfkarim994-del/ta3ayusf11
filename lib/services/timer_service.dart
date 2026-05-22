import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecoveryTimerService extends ChangeNotifier {
  DateTime? _startDate;
  Duration _currentDuration = Duration.zero;
  int _bonusDays = 0; // Bonus days from previous streaks (halved on relapse)
  int _relapseCount = 0; // Number of relapses
  String _backgroundImagePath = 'assets/images/timer_bg_nature4.png';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime? get startDate => _startDate;
  Duration get currentDuration => _currentDuration;
  int get bonusDays => _bonusDays;
  int get relapseCount => _relapseCount;
  String get backgroundImagePath => _backgroundImagePath;
  
  int get months {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    final int totalDays = now.difference(_startDate!).inDays;
    return totalDays < 0 ? 0 : (totalDays ~/ 30);
  }
  
  int get days {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    final int totalDays = now.difference(_startDate!).inDays;
    return totalDays < 0 ? 0 : (totalDays % 30);
  }
  
  int get hours => _currentDuration.inHours % 24;
  int get minutes => _currentDuration.inMinutes % 60;
  int get seconds => _currentDuration.inSeconds % 60;
  int get totalDays => _currentDuration.inDays;
  
  /// Effective days for level calculation = current streak + bonus from previous streaks
  int get effectiveDays => totalDays + _bonusDays;
  
  bool get hasStarted => _startDate != null;
  bool get isLoggedIn => _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

  /// Set and persist the timer background image path
  Future<void> setBackgroundImage(String path) async {
    _backgroundImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_background_image', path);
    notifyListeners();
  }

  /// Load background image preference
  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    _backgroundImagePath = prefs.getString('timer_background_image') ?? 'assets/images/timer_bg_nature4.png';
  }

  // Get user-specific key for local storage (to isolate data per account)
  String _getStorageKey() {
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'guest';
    return 'recovery_start_date_$userId';
  }

  // Load start date - first from local storage (for instant UI), then sync with Firebase
  Future<void> loadStartDate() async {
    await _loadBackgroundImage();
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();
    
    // 1. ALWAYS load from local storage first (Offline First) - USER SPECIFIC
    final savedDate = prefs.getString(storageKey);
    _bonusDays = prefs.getInt('${storageKey}_bonus') ?? 0;
    _relapseCount = prefs.getInt('${storageKey}_relapses') ?? 0;
    
    if (savedDate != null) {
      _startDate = DateTime.parse(savedDate);
      _updateDuration();
      notifyListeners();
    } else {
      // Reset if no data for this user
      _startDate = null;
      _currentDuration = Duration.zero;
      notifyListeners();
    }
    
    // 2. Sync with Firebase in background (if logged in)
    if (isLoggedIn) {
      _syncFromFirebase(prefs, storageKey);
    }
  }

  // Background sync from Firebase
  Future<void> _syncFromFirebase(SharedPreferences prefs, String storageKey) async {
    try {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['recoveryStartDate'] != null) {
          final timestamp = data['recoveryStartDate'] as Timestamp;
          final firebaseDate = timestamp.toDate();
          
          // Load bonus days and relapse count from Firebase
          _bonusDays = data['bonusDays'] ?? _bonusDays;
          _relapseCount = data['relapseCount'] ?? _relapseCount;
          
          // Only update if different
          if (_startDate != firebaseDate) {
            _startDate = firebaseDate;
            // Save valid data to local storage - USER SPECIFIC
            await prefs.setString(storageKey, _startDate!.toIso8601String());
            await prefs.setInt('${storageKey}_bonus', _bonusDays);
            await prefs.setInt('${storageKey}_relapses', _relapseCount);
            _updateDuration();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Firebase background sync failed: $e');
    }
  }

  // Set start date - save locally and to Firebase
  Future<void> setStartDate(DateTime date) async {
    _startDate = date;
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();
    
    // Save locally first (for offline support) - USER SPECIFIC
    await prefs.setString(storageKey, date.toIso8601String());
    
    // Sync to Firebase if logged in
    if (isLoggedIn) {
      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'recoveryStartDate': Timestamp.fromDate(date),
          'bonusDays': _bonusDays,
          'relapseCount': _relapseCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase sync failed: $e');
      }
    }
    
    _updateDuration();
    notifyListeners();
  }

  /// Reset timer with relapse penalty
  /// Current streak days are halved and added to bonus days
  /// Example: If at Level 10 (100 days), after reset: bonusDays = 50 (Level 5 equivalent)
  Future<void> resetTimer() async {
    // Calculate penalty: halve current days and add to bonus
    final currentDays = totalDays;
    final halfDays = (currentDays / 2).floor();
    
    // Add half of current streak to bonus (stacks with existing bonus, but bonus also halved)
    _bonusDays = ((_bonusDays + currentDays) / 2).floor();
    _relapseCount++;
    
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();
    await prefs.setInt('${storageKey}_bonus', _bonusDays);
    await prefs.setInt('${storageKey}_relapses', _relapseCount);
    
    debugPrint('Relapse #$_relapseCount: Was $currentDays days, now bonus=$_bonusDays');
    
    await setStartDate(DateTime.now());
  }

  // Sync local data to Firebase when user logs in
  Future<void> syncToFirebase() async {
    if (!isLoggedIn || _startDate == null) return;
    
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'recoveryStartDate': Timestamp.fromDate(_startDate!),
        'bonusDays': _bonusDays,
        'relapseCount': _relapseCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase sync failed: $e');
    }
  }

  void _updateDuration() {
    if (_startDate != null) {
      _currentDuration = DateTime.now().difference(_startDate!);
    }
  }

  void tick() {
    _updateDuration();
    notifyListeners();
  }
}
