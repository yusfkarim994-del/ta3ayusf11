import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// XP values for different activities
class XPValues {
  static const int dailyStreak = 10;      // هەر ڕۆژێک بەردەوامبوون
  static const int challengeComplete = 50; // تەواوکردنی چاڵنج
  static const int journalEntry = 15;      // نوسینی ڕۆژنامە
  static const int communityAction = 5;    // هاوکاری لە کۆمەڵگە (like, post)
  static const int commentAction = 3;      // کۆمێنت
}

/// XP Activity types
enum XPActivityType {
  daily,
  challenge,
  journal,
  post,
  like,
  comment,
}

/// XP History entry
class XPHistoryEntry {
  final String id;
  final XPActivityType type;
  final int amount;
  final DateTime date;
  final String? description;

  XPHistoryEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'description': description,
  };

  factory XPHistoryEntry.fromJson(Map<String, dynamic> json) => XPHistoryEntry(
    id: json['id'] ?? '',
    type: XPActivityType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => XPActivityType.daily,
    ),
    amount: json['amount'] ?? 0,
    date: json['date'] is Timestamp 
        ? (json['date'] as Timestamp).toDate()
        : DateTime.now(),
    description: json['description'],
  );
}

/// User XP data
class UserXP {
  final int total;
  final int level;
  final int xpForCurrentLevel;
  final int xpNeededForNextLevel;
  final double progress; // 0.0 to 1.0
  final DateTime? lastDailyXP;

  UserXP({
    required this.total,
    required this.level,
    required this.xpForCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.progress,
    this.lastDailyXP,
  });

  factory UserXP.empty() => UserXP(
    total: 0,
    level: 1,
    xpForCurrentLevel: 0,
    xpNeededForNextLevel: 100,
    progress: 0.0,
  );
}

/// XP Service for managing user XP
class XPService extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  int _totalXP = 0;
  DateTime? _lastDailyXP;
  bool _isLoading = false;

  int get totalXP => _totalXP;
  bool get isLoading => _isLoading;

  /// XP per day constant
  static const int xpPerDay = 100;

  /// Calculate XP from days
  /// 1 day = 100 XP
  /// 1000 days = 100,000 XP
  static int calculateXPFromDays(int days) {
    return days * xpPerDay;
  }

  /// Calculate level from days
  /// 10 days = 1 level
  /// 1000 days = Level 100
  static int calculateLevelFromDays(int days) {
    if (days <= 0) return 1;
    final level = (days / 10).floor() + 1;
    return level > 100 ? 100 : level;
  }

  /// Calculate level from XP (for backward compatibility)
  /// 1000 XP = 1 level
  /// 100,000 XP = Level 100
  static int calculateLevel(int xp) {
    if (xp <= 0) return 1;
    final level = (xp / 1000).floor() + 1;
    return level > 100 ? 100 : level;
  }

  /// Get XP needed for a specific level
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (level - 1) * 1000; // 1000 XP per level
  }

  /// Get days needed for a specific level
  static int daysForLevel(int level) {
    if (level <= 1) return 0;
    return (level - 1) * 10; // 10 days per level
  }

  /// Get XP needed to reach next level
  static int xpNeededForNextLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    if (currentLevel >= 100) return 0;
    final nextLevelXP = xpForLevel(currentLevel + 1);
    return nextLevelXP - currentXP;
  }

  /// Get progress to next level (0.0 to 1.0)
  static double progressToNextLevel(int currentXP) {
    final currentLevel = calculateLevel(currentXP);
    if (currentLevel >= 100) return 1.0;
    final currentLevelXP = xpForLevel(currentLevel);
    final nextLevelXP = xpForLevel(currentLevel + 1);
    final xpInCurrentLevel = currentXP - currentLevelXP;
    final xpNeededInLevel = nextLevelXP - currentLevelXP;
    return xpNeededInLevel > 0 ? xpInCurrentLevel / xpNeededInLevel : 1.0;
  }

  /// Get user XP data
  UserXP getUserXP() {
    final level = calculateLevel(_totalXP);
    return UserXP(
      total: _totalXP,
      level: level,
      xpForCurrentLevel: _totalXP - xpForLevel(level),
      xpNeededForNextLevel: xpNeededForNextLevel(_totalXP),
      progress: progressToNextLevel(_totalXP),
      lastDailyXP: _lastDailyXP,
    );
  }

  /// Load XP data from Firestore
  Future<void> loadXP() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final xpData = data?['xp'] as Map<String, dynamic>?;
        if (xpData != null) {
          _totalXP = xpData['total'] ?? 0;
          if (xpData['lastDailyXP'] != null) {
            _lastDailyXP = (xpData['lastDailyXP'] as Timestamp).toDate();
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading XP: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add XP for an activity
  Future<bool> addXP(XPActivityType type, {String? description}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;

    int amount;
    switch (type) {
      case XPActivityType.daily:
        // Check if already claimed today
        if (_hasClaimedDailyXP()) return false;
        amount = XPValues.dailyStreak;
        break;
      case XPActivityType.challenge:
        amount = XPValues.challengeComplete;
        break;
      case XPActivityType.journal:
        amount = XPValues.journalEntry;
        break;
      case XPActivityType.post:
      case XPActivityType.like:
        amount = XPValues.communityAction;
        break;
      case XPActivityType.comment:
        amount = XPValues.commentAction;
        break;
    }

    try {
      final now = DateTime.now();
      final historyEntry = XPHistoryEntry(
        id: '${type.name}_${now.millisecondsSinceEpoch}',
        type: type,
        amount: amount,
        date: now,
        description: description,
      );

      final updateData = <String, dynamic>{
        'xp.total': FieldValue.increment(amount),
      };

      if (type == XPActivityType.daily) {
        updateData['xp.lastDailyXP'] = Timestamp.fromDate(now);
        _lastDailyXP = now;
      }

      // 1. Local update
      _totalXP += amount;
      notifyListeners();

      // 2. Background sync (non-blocking)
      _firestore.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      ).catchError((e) => debugPrint('XP Sync Error: $e'));

      // Add to history in background
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('xp_history')
          .doc(historyEntry.id)
          .set(historyEntry.toJson())
          .catchError((e) => debugPrint('XP History Sync Error: $e'));

      debugPrint('Added $amount XP for ${type.name}. Total: $_totalXP');
      return true;
    } catch (e) {
      debugPrint('Error adding XP: $e');
      return false;
    }
  }

  /// Check if daily XP has been claimed today
  bool _hasClaimedDailyXP() {
    if (_lastDailyXP == null) return false;
    final now = DateTime.now();
    return _lastDailyXP!.year == now.year &&
           _lastDailyXP!.month == now.month &&
           _lastDailyXP!.day == now.day;
  }

  /// Can claim daily XP
  bool canClaimDailyXP() => !_hasClaimedDailyXP();

  /// Get XP history stream
  Stream<List<XPHistoryEntry>> getXPHistory({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('xp_history')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => XPHistoryEntry.fromJson(doc.data()))
            .toList());
  }

  /// Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard({
    LeaderboardPeriod period = LeaderboardPeriod.allTime,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('email', isNull: false);

      final snapshot = await query.get();
      
      final now = DateTime.now();
      List<Map<String, dynamic>> users = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final email = data['email']?.toString() ?? '';
        
        // Skip anonymous or developer
        if (email.isEmpty || email.toLowerCase() == 'yusfkarim2001@gmail.com') {
          continue;
        }

        final xpData = data['xp'] as Map<String, dynamic>?;
        int totalXP = xpData?['total'] ?? 0;
        
        // For weekly/monthly, we would need to calculate from history
        // For now, use total XP
        int periodXP = totalXP;

        // Calculate days
        DateTime? startDate;
        if (data['recoveryStartDate'] != null) {
          if (data['recoveryStartDate'] is Timestamp) {
            startDate = (data['recoveryStartDate'] as Timestamp).toDate();
          }
        }
        int totalDays = startDate != null
            ? now.difference(startDate).inHours ~/ 24
            : 0;

        users.add({
          'userId': doc.id,
          'email': email,
          'displayName': data['displayName'] ?? email.split('@').first,
          'photoURL': data['photoURL'],
          'totalXP': totalXP,
          'periodXP': periodXP,
          'level': calculateLevel(totalXP),
          'totalDays': totalDays,
          'startDate': startDate,
        });
      }

      // Sort by period XP (or total XP)
      users.sort((a, b) => (b['periodXP'] as int).compareTo(a['periodXP'] as int));

      return users.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get level emoji/icon based on level
  static String getLevelEmoji(int level) {
    if (level >= 90) return '👑';
    if (level >= 80) return '💎';
    if (level >= 70) return '🏆';
    if (level >= 60) return '⭐';
    if (level >= 50) return '🌟';
    if (level >= 40) return '🔥';
    if (level >= 30) return '💪';
    if (level >= 20) return '🎯';
    if (level >= 10) return '🌱';
    return '🌿';
  }

  /// Get level title
  static String getLevelTitle(int level, String languageCode) {
    final titles = _getLevelTitles(languageCode);
    if (level >= 90) return titles['legendary']!;
    if (level >= 80) return titles['master']!;
    if (level >= 70) return titles['expert']!;
    if (level >= 60) return titles['advanced']!;
    if (level >= 50) return titles['skilled']!;
    if (level >= 40) return titles['intermediate']!;
    if (level >= 30) return titles['developing']!;
    if (level >= 20) return titles['growing']!;
    if (level >= 10) return titles['starter']!;
    return titles['beginner']!;
  }

  static Map<String, String> _getLevelTitles(String languageCode) {
    switch (languageCode) {
      case 'ku':
        return {
          'beginner': 'نوێکار',
          'starter': 'دەستپێکەر',
          'growing': 'گەشەکردوو',
          'developing': 'پێشکەوتوو',
          'intermediate': 'ناوەندی',
          'skilled': 'شارەزا',
          'advanced': 'پێشکەوتوو',
          'expert': 'شارەزا',
          'master': 'ماستەر',
          'legendary': 'ئەفسانەیی',
        };
      case 'ar':
        return {
          'beginner': 'مبتدئ',
          'starter': 'بادئ',
          'growing': 'نامٍ',
          'developing': 'متطور',
          'intermediate': 'متوسط',
          'skilled': 'ماهر',
          'advanced': 'متقدم',
          'expert': 'خبير',
          'master': 'محترف',
          'legendary': 'أسطوري',
        };
      default:
        return {
          'beginner': 'Beginner',
          'starter': 'Starter',
          'growing': 'Growing',
          'developing': 'Developing',
          'intermediate': 'Intermediate',
          'skilled': 'Skilled',
          'advanced': 'Advanced',
          'expert': 'Expert',
          'master': 'Master',
          'legendary': 'Legendary',
        };
    }
  }
}

/// Leaderboard period filter
enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime,
}
