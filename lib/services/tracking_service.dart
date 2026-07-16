import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'supabase_service.dart';
import 'dart:convert';

/// Enum representing the daily status options
enum DayStatus {
  success,  // نجاح / سەرکەوتن - Green
  slip,     // زلة / زەلە - Yellow/Amber
  relapse,  // انتكاسة / شکست - Red
  unknown,  // غائب / نادیار - Grey
}

/// Record for a single day's status
class DayRecord {
  final DateTime date;
  final DayStatus status;
  final DateTime recordedAt;

  DayRecord({
    required this.date,
    required this.status,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'status': status.name,
    'recordedAt': recordedAt.toIso8601String(),
  };

  factory DayRecord.fromJson(Map<String, dynamic> json) => DayRecord(
    date: DateTime.parse(json['date']),
    status: DayStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => DayStatus.unknown,
    ),
    recordedAt: DateTime.parse(json['recordedAt']),
  );

  /// Get key for storage (YYYY-MM-DD format)
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Service for managing daily tracking data
class TrackingService extends ChangeNotifier {
  static const String _storageKey = 'tracking_records';
  
  final Map<String, DayRecord> _records = {};
  bool _isLoaded = false;
  String? _currentUserId;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TrackingService() {
    // Listen to auth state changes and reload data when user changes
    _auth.authStateChanges().listen((user) {
      if (user?.uid != _currentUserId) {
        _currentUserId = user?.uid;
        _isLoaded = false; // Reset load flag to force reload
        _records.clear();
        loadRecords(); // Reload from Firestore for new user
      }
    });
  }

  /// All records
  Map<String, DayRecord> get records => Map.unmodifiable(_records);

  /// Check if data is loaded
  bool get isLoaded => _isLoaded;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get Firestore collection for current user
  CollectionReference? get _collection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('tracking_records');
  }

  /// Force reload records from Firestore (for manual refresh)
  Future<void> forceReload() async {
    _isLoaded = false;
    _records.clear();
    await loadRecords();
  }

  /// Load records from Supabase (web) or SharedPreferences (APK)
  Future<void> loadRecords() async {
    if (_isLoaded) return;

    // Load from local storage first (works on both web and APK)
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _records.clear();

        for (final item in jsonList) {
          final record = DayRecord.fromJson(item as Map<String, dynamic>);
          _records[record.dateKey] = record;
        }
      }

      _isLoaded = true;
      notifyListeners();
      _syncFromFirestore();
    } catch (e) {
      debugPrint('Error loading tracking records: $e');
      _isLoaded = true;
    }
  }

  /// Load from Supabase (primary source on web)
  Future<void> _loadFromSupabase() async {
    try {
      final records = await SupabaseService.loadTrackingRecords();
      for (final data in records) {
        final record = DayRecord.fromJson(data);
        _records[record.dateKey] = record;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from Supabase: $e');
    }
  }

  Future<void> _syncFromFirestore() async {
    if (_userId == null || _collection == null) return;

    try {
      final snapshot = await _collection!.get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final record = DayRecord.fromJson(data);
        _records[record.dateKey] = record;
      }

      await _saveRecords();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing tracking records from Firestore: $e');
    }
  }

  /// Save records to SharedPreferences
  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _records.values.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving tracking records: $e');
    }
  }

  /// Save a record to Firestore
  Future<void> _saveToFirestore(DayRecord record) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(record.dateKey).set(record.toJson());
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  /// Set status for a specific date
  Future<void> setDayStatus(DateTime date, DayStatus status) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final record = DayRecord(date: normalizedDate, status: status);
    
    // 1. Update local state immediately
    _records[record.dateKey] = record;
    notifyListeners();
    
    // 2. Persist locally (APK only)
    await _saveRecords();
    
    // 3. Save to Supabase (always, AWAITED)
    await SupabaseService.saveTrackingRecord(
      dateKey: record.dateKey,
      status: status.name,
      date: record.date.toIso8601String(),
      recordedAt: record.recordedAt.toIso8601String(),
    ).catchError((e) => debugPrint('Supabase Tracking Sync Error: $e'));
    
    // 4. Background sync to Firestore
    _saveToFirestore(record).catchError((e) => debugPrint('Tracking Sync Error: $e'));
  }

  /// Get status for a specific date
  DayStatus getDayStatus(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _records[key]?.status ?? DayStatus.unknown;
  }

  /// Get record for a specific date
  DayRecord? getDayRecord(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _records[key];
  }

  /// Get count of success days
  int getSuccessCount() {
    return _records.values.where((r) => r.status == DayStatus.success).length;
  }

  /// Get count of slip days
  int getSlipCount() {
    return _records.values.where((r) => r.status == DayStatus.slip).length;
  }

  /// Get count of relapse days
  int getRelapseCount() {
    return _records.values.where((r) => r.status == DayStatus.relapse).length;
  }

  /// Get count of unknown days (not recorded)
  int getUnknownCount() {
    return _records.values.where((r) => r.status == DayStatus.unknown).length;
  }

  /// Get records for a specific month
  List<DayRecord> getRecordsForMonth(int year, int month) {
    return _records.values
        .where((r) => r.date.year == year && r.date.month == month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Check if today has been recorded
  bool isTodayRecorded() {
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final record = _records[key];
    return record != null && record.status != DayStatus.unknown;
  }

  /// Get current streak of success days
  int getCurrentSuccessStreak() {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    while (true) {
      final status = getDayStatus(checkDate);
      if (status == DayStatus.success) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (status == DayStatus.unknown && checkDate.day == DateTime.now().day) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Clear all records (for testing/reset)
  Future<void> clearAllRecords() async {
    _records.clear();
    notifyListeners();
    await _saveRecords();
  }
}
