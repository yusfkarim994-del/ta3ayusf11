import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import for dart:html on web
import 'dart:io' if (dart.library.html) 'dart:html' as html;

/// Read from web localStorage
String? _readFromLocalStorage(String key) {
  if (kIsWeb) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Write to web localStorage
void _writeToLocalStorage(String key, String value) {
  if (kIsWeb) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }
}

/// Supabase fallback service - saves data when Firestore is unavailable
class SupabaseService {
  static const String _supabaseUrl = 'https://ublvxamjrdpoggozrnue.supabase.co';
  static const String _supabaseKey = 'sb_publishable_9_389L3KkV8q-QMXffqk4A_UWZpHbnY';
  static const String _deviceIdKey = 'supabase_device_id';

  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase
  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }
  }

  /// Generate a random device ID
  static String _generateDeviceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Get user ID: use Firebase auth if logged in, otherwise generate a device ID
  static Future<String> _getUserId() async {
    // Try Firebase auth first
    final firebaseUser = _client?.auth.currentUser;
    if (firebaseUser != null) return firebaseUser.id;

    // For anonymous users: use localStorage on web, SharedPreferences on APK
    if (kIsWeb) {
      // Use dart:html localStorage directly (always persists on web)
      try {
        String? deviceId = _readFromLocalStorage(_deviceIdKey);
        if (deviceId == null || deviceId.isEmpty) {
          deviceId = _generateDeviceId();
          _writeToLocalStorage(_deviceIdKey, deviceId);
        }
        return 'anon_$deviceId';
      } catch (e) {
        debugPrint('Web storage error: $e');
        return 'anon_${_generateDeviceId()}';
      }
    } else {
      // APK: use SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
      }
      return 'anon_$deviceId';
    }
  }

  // ==================== TRACKING ====================

  static Future<void> saveTrackingRecord({
    required String dateKey,
    required String status,
    required String date,
    required String recordedAt,
  }) async {
    if (_client == null) return;
    try {
      final userId = await _getUserId();
      await _client!.from('tracking_records').upsert({
        'user_id': userId,
        'date_key': dateKey,
        'status': status,
        'date': date,
        'recorded_at': recordedAt,
      }, onConflict: 'user_id,date_key');
    } catch (e) {
      debugPrint('Supabase save tracking error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadTrackingRecords() async {
    if (_client == null) return [];
    try {
      final userId = await _getUserId();
      final response = await _client!
          .from('tracking_records')
          .select()
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase load tracking error: $e');
      return [];
    }
  }

  // ==================== HABITS ====================

  static Future<void> saveHabits(List<Map<String, dynamic>> habits) async {
    if (_client == null) return;
    try {
      final userId = await _getUserId();
      await _client!.from('user_habits').upsert({
        'user_id': userId,
        'habits': jsonEncode(habits),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase save habits error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadHabits() async {
    if (_client == null) return [];
    try {
      final userId = await _getUserId();
      final response = await _client!
          .from('user_habits')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (response.isNotEmpty) {
        final data = response.first;
        return List<Map<String, dynamic>>.from(jsonDecode(data['habits'] ?? '[]'));
      }
      return [];
    } catch (e) {
      debugPrint('Supabase load habits error: $e');
      return [];
    }
  }

  // ==================== JOURNAL ====================

  static Future<void> saveJournalEntries(List<Map<String, dynamic>> entries) async {
    if (_client == null) return;
    try {
      final userId = await _getUserId();
      await _client!.from('journal_entries').upsert({
        'user_id': userId,
        'entries': jsonEncode(entries),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase save journal error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadJournalEntries() async {
    if (_client == null) return [];
    try {
      final userId = await _getUserId();
      final response = await _client!
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (response.isNotEmpty) {
        final data = response.first;
        return List<Map<String, dynamic>>.from(jsonDecode(data['entries'] ?? '[]'));
      }
      return [];
    } catch (e) {
      debugPrint('Supabase load journal error: $e');
      return [];
    }
  }

  // ==================== COMMITMENT ====================

  static Future<void> saveCommitmentLetters(List<Map<String, dynamic>> letters) async {
    if (_client == null) return;
    try {
      final userId = await _getUserId();
      await _client!.from('commitment_letters').upsert({
        'user_id': userId,
        'letters': jsonEncode(letters),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase save commitment error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadCommitmentLetters() async {
    if (_client == null) return [];
    try {
      final userId = await _getUserId();
      final response = await _client!
          .from('commitment_letters')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (response.isNotEmpty) {
        final data = response.first;
        return List<Map<String, dynamic>>.from(jsonDecode(data['letters'] ?? '[]'));
      }
      return [];
    } catch (e) {
      debugPrint('Supabase load commitment error: $e');
      return [];
    }
  }

  // ==================== CHALLENGES ====================

  static Future<void> saveChallengeData(Map<String, dynamic> data) async {
    if (_client == null) return;
    try {
      final userId = await _getUserId();
      await _client!.from('challenge_data').upsert({
        'user_id': userId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Supabase save challenge error: $e');
    }
  }

  static Future<Map<String, dynamic>?> loadChallengeData() async {
    if (_client == null) return null;
    try {
      final userId = await _getUserId();
      final response = await _client!
          .from('challenge_data')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (response.isNotEmpty) {
        final data = response.first;
        return Map<String, dynamic>.from(jsonDecode(data['data'] ?? '{}'));
      }
      return null;
    } catch (e) {
      debugPrint('Supabase load challenge error: $e');
      return null;
    }
  }
}
