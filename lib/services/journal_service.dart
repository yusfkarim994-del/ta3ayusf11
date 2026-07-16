import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'supabase_service.dart';
import 'xp_service.dart';

// Mood enum with emoji
enum JournalMood {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
  angry,
  anxious,
  hopeful,
  tired,
}

extension JournalMoodExtension on JournalMood {
  String get emoji {
    switch (this) {
      case JournalMood.veryHappy: return '😄';
      case JournalMood.happy: return '😊';
      case JournalMood.neutral: return '😐';
      case JournalMood.sad: return '😢';
      case JournalMood.verySad: return '😭';
      case JournalMood.angry: return '😠';
      case JournalMood.anxious: return '😰';
      case JournalMood.hopeful: return '🌟';
      case JournalMood.tired: return '😴';
    }
  }

  String getName(String languageCode) {
    switch (this) {
      case JournalMood.veryHappy:
        return languageCode == 'arabic' ? 'سعيد جداً' : languageCode == 'kurdish' ? 'زۆر دڵخۆش' : 'Very Happy';
      case JournalMood.happy:
        return languageCode == 'arabic' ? 'سعيد' : languageCode == 'kurdish' ? 'دڵخۆش' : 'Happy';
      case JournalMood.neutral:
        return languageCode == 'arabic' ? 'عادي' : languageCode == 'kurdish' ? 'ئاسایی' : 'Neutral';
      case JournalMood.sad:
        return languageCode == 'arabic' ? 'حزين' : languageCode == 'kurdish' ? 'خەمبار' : 'Sad';
      case JournalMood.verySad:
        return languageCode == 'arabic' ? 'حزين جداً' : languageCode == 'kurdish' ? 'زۆر خەمبار' : 'Very Sad';
      case JournalMood.angry:
        return languageCode == 'arabic' ? 'غاضب' : languageCode == 'kurdish' ? 'تووڕە' : 'Angry';
      case JournalMood.anxious:
        return languageCode == 'arabic' ? 'قلق' : languageCode == 'kurdish' ? 'نیگەران' : 'Anxious';
      case JournalMood.hopeful:
        return languageCode == 'arabic' ? 'متفائل' : languageCode == 'kurdish' ? 'هیوادار' : 'Hopeful';
      case JournalMood.tired:
        return languageCode == 'arabic' ? 'متعب' : languageCode == 'kurdish' ? 'ماندوو' : 'Tired';
    }
  }

  Color get color {
    switch (this) {
      case JournalMood.veryHappy: return const Color(0xFFFFD700);
      case JournalMood.happy: return const Color(0xFF4CAF50);
      case JournalMood.neutral: return const Color(0xFF9E9E9E);
      case JournalMood.sad: return const Color(0xFF2196F3);
      case JournalMood.verySad: return const Color(0xFF1565C0);
      case JournalMood.angry: return const Color(0xFFF44336);
      case JournalMood.anxious: return const Color(0xFFFF9800);
      case JournalMood.hopeful: return const Color(0xFF9C27B0);
      case JournalMood.tired: return const Color(0xFF795548);
    }
  }
}

class JournalEntry {
  final String id;
  final String content;
  final JournalMood mood;
  final DateTime createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.content,
    required this.mood,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'mood': mood.index,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'],
    content: json['content'],
    mood: JournalMood.values[json['mood']],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );

  JournalEntry copyWith({
    String? content,
    JournalMood? mood,
    DateTime? updatedAt,
  }) => JournalEntry(
    id: id,
    content: content ?? this.content,
    mood: mood ?? this.mood,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class JournalService extends ChangeNotifier {
  static const String _storageKey = 'journal_entries';
  List<JournalEntry> _entries = [];
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  
  List<JournalEntry> get sortedEntries {
    final sorted = List<JournalEntry>.from(_entries);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get Firestore collection for current user
  CollectionReference? get _collection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('journal_entries');
  }

  StreamSubscription? _journalSubscription;

  Future<void> loadEntries() async {
    // Cancel existing subscription if any
    await _journalSubscription?.cancel();

    // Load from local storage
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        try {
          final List<dynamic> jsonList = json.decode(data);
          _entries = jsonList.map((e) => JournalEntry.fromJson(e)).toList();
          notifyListeners();
        } catch (e) {
          debugPrint('Error loading cached journal: $e');
        }
      }

    // 2. Setup real-time sync from Firestore if user is logged in
    // Only update from Firestore — never let it wipe local data
    final uid = _userId;
    if (uid != null && _collection != null) {
      _journalSubscription = _collection!
          .orderBy('createdAt', descending: true)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            // Only update from Firestore if it has MORE data than local
            // This prevents Firestore from wiping local-only entries
            if (snapshot.docs.isNotEmpty && snapshot.docs.length >= _entries.length) {
              _entries = snapshot.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['createdAt'] == null) {
                  return JournalEntry.fromJson({...data, 'id': doc.id, 'createdAt': DateTime.now().toIso8601String()});
                }
                return JournalEntry.fromJson({...data, 'id': doc.id});
              }).toList();
              _saveEntries();
              notifyListeners();
            }
          }, onError: (e) {
            debugPrint('Journal Stream Error: $e');
          });
    }
  }

  Future<void> _loadFromSupabase() async {
    try {
      final supabaseEntries = await SupabaseService.loadJournalEntries();
      if (supabaseEntries.isNotEmpty) {
        _entries = supabaseEntries.map((e) => JournalEntry.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading journal from Supabase: $e');
    }
  }

  @override
  void dispose() {
    _journalSubscription?.cancel();
    super.dispose();
  }

  Future<void> _saveToFirestore(JournalEntry entry) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(entry.id).set(entry.toJson());
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
  }

  Future<void> _deleteFromFirestore(String id) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting from Firestore: $e');
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> addEntry(String content, JournalMood mood) async {
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      mood: mood,
      createdAt: DateTime.now(),
    );
    
    // 1. Update local state immediately for instant UI response
    _entries.insert(0, entry); // Insert at top
    await _saveEntries();
    notifyListeners();

    // 2. Save to Supabase (always, AWAITED)
    await SupabaseService.saveJournalEntries(_entries.map((e) => e.toJson()).toList())
        .catchError((e) => debugPrint('Supabase Journal Sync Error: $e'));

    // 3. Sync to Firestore in background
    _saveToFirestore(entry).catchError((e) => debugPrint('Background Journal Sync Error: $e'));
    
    // 3. Award XP in background
    try {
      final xpService = XPService();
      await xpService.loadXP();
      await xpService.addXP(XPActivityType.journal, description: 'Journal entry');
    } catch (e) {
      debugPrint('XP Error: $e');
    }
  }

  Future<void> updateEntry(String id, String content, JournalMood mood) async {
    final entryIndex = _entries.indexWhere((e) => e.id == id);
    if (entryIndex != -1) {
      final updatedEntry = _entries[entryIndex].copyWith(
        content: content,
        mood: mood,
        updatedAt: DateTime.now(),
      );
      
      // 1. Update local state
      _entries[entryIndex] = updatedEntry;
      await _saveEntries();
      notifyListeners();

      // 2. Sync in background
      _saveToFirestore(updatedEntry).catchError((e) => debugPrint('Background Journal Update Error: $e'));
    }
  }

  Future<void> deleteEntry(String id) async {
    // 1. Update local state
    _entries.removeWhere((e) => e.id == id);
    await _saveEntries();
    notifyListeners();

    // 2. Sync in background
    _deleteFromFirestore(id).catchError((e) => debugPrint('Background Journal Delete Error: $e'));
  }

  String formatDate(DateTime date, String languageCode) {
    final months = languageCode == 'arabic'
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : languageCode == 'kurdish'
            ? ['کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران', 'تەمموز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم']
            : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get mood statistics
  Map<JournalMood, int> getMoodStats() {
    final stats = <JournalMood, int>{};
    for (final entry in _entries) {
      stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
    }
    return stats;
  }

  // Get entries for a specific date
  List<JournalEntry> getEntriesForDate(DateTime date) {
    return _entries.where((e) =>
      e.createdAt.year == date.year &&
      e.createdAt.month == date.month &&
      e.createdAt.day == date.day
    ).toList();
  }
}
