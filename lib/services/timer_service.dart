import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class RecoveryTimerService extends ChangeNotifier {
  static const String _globalStorageKey = 'recovery_start_date_global';

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
  bool get isLoggedIn =>
      _auth.currentUser != null && !_auth.currentUser!.isAnonymous;

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
    _backgroundImagePath = prefs.getString('timer_background_image') ??
        'assets/images/timer_bg_nature4.png';
  }

  // Get user-specific key for local storage (to isolate data per account)
  String _getStorageKey() {
    final user = _auth.currentUser;
    final userId = user?.uid ?? 'guest';
    return 'recovery_start_date_$userId';
  }

  Future<void> _saveLocalTimerState(SharedPreferences prefs, String storageKey,
      DateTime date, DateTime updatedAt) async {
    for (final key in {storageKey, _globalStorageKey}) {
      await prefs.setString(key, date.toIso8601String());
      await prefs.setInt('${key}_bonus', _bonusDays);
      await prefs.setInt('${key}_relapses', _relapseCount);
      await prefs.setString('${key}_updated_at', updatedAt.toIso8601String());
    }
  }

  DateTime? _readLocalDate(SharedPreferences prefs, String storageKey) {
    final savedDate =
        prefs.getString(storageKey) ?? prefs.getString(_globalStorageKey);
    return savedDate == null ? null : DateTime.tryParse(savedDate);
  }

  int _readLocalInt(SharedPreferences prefs, String storageKey, String suffix) {
    return prefs.getInt('$storageKey$suffix') ??
        prefs.getInt('$_globalStorageKey$suffix') ??
        0;
  }

  DateTime _readLocalUpdatedAt(SharedPreferences prefs, String storageKey) {
    return DateTime.tryParse(
          prefs.getString('${storageKey}_updated_at') ??
              prefs.getString('${_globalStorageKey}_updated_at') ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Load start date - first from local storage (for instant UI), then sync with Firebase
  Future<void> loadStartDate() async {
    await _loadBackgroundImage();
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();

    // 1. ALWAYS load from local storage first (Offline First) - USER SPECIFIC
    final localDate = _readLocalDate(prefs, storageKey);
    _bonusDays = _readLocalInt(prefs, storageKey, '_bonus');
    _relapseCount = _readLocalInt(prefs, storageKey, '_relapses');

    if (localDate != null) {
      _startDate = localDate;
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
  Future<void> _syncFromFirebase(
      SharedPreferences prefs, String storageKey) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['recoveryStartDate'] != null) {
          final timestamp = data['recoveryStartDate'] as Timestamp;
          final firebaseDate = timestamp.toDate();
          final firebaseUpdatedAt = data['lastUpdated'] is Timestamp
              ? (data['lastUpdated'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);
          final localUpdatedAt = _readLocalUpdatedAt(prefs, storageKey);

          // If the user changed the timer locally more recently, keep local data
          // and push it back to Firebase instead of letting old cloud data win.
          if (_startDate != null &&
              (localUpdatedAt.isAfter(firebaseUpdatedAt) ||
                  localUpdatedAt.isAtSameMomentAs(firebaseUpdatedAt) ||
                  firebaseUpdatedAt ==
                      DateTime.fromMillisecondsSinceEpoch(0))) {
            unawaited(syncToFirebase());
            return;
          }

          // Load bonus days and relapse count from Firebase
          _bonusDays = data['bonusDays'] ?? _bonusDays;
          _relapseCount = data['relapseCount'] ?? _relapseCount;

          // Only update if different
          if (_startDate != firebaseDate) {
            _startDate = firebaseDate;
            // Save valid data to local storage - USER SPECIFIC
            await _saveLocalTimerState(
              prefs,
              storageKey,
              _startDate!,
              firebaseUpdatedAt,
            );
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
    _updateDuration();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();

    // Save locally first (for offline support) - USER SPECIFIC
    final updatedAt = DateTime.now();
    await _saveLocalTimerState(prefs, storageKey, date, updatedAt);
    // Sync to Firebase in background only
    if (isLoggedIn) {
      unawaited(
        _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'recoveryStartDate': Timestamp.fromDate(date),
          'bonusDays': _bonusDays,
          'relapseCount': _relapseCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).catchError(
          (e) => debugPrint('Firebase sync failed: $e'),
        ),
      );
    }
  }

  /// Reset timer with relapse penalty
  /// Current streak days are halved and added to bonus days
  /// Example: If at Level 10 (100 days), after reset: bonusDays = 50 (Level 5 equivalent)
  Future<void> resetTimer() async {
    // Calculate penalty: halve current days and add to bonus
    final currentDays = totalDays;
    // Add half of current streak to bonus (stacks with existing bonus, but bonus also halved)
    _bonusDays = ((_bonusDays + currentDays) / 2).floor();
    _relapseCount++;

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _getStorageKey();
    final resetDate = DateTime.now();
    await _saveLocalTimerState(prefs, storageKey, resetDate, resetDate);

    debugPrint(
        'Relapse #$_relapseCount: Was $currentDays days, now bonus=$_bonusDays');

    await setStartDate(resetDate);
    notifyListeners();
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
