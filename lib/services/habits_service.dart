import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

// Habit category with emoji
class HabitItem {
  final String id;
  final String emoji;
  final String nameArabic;
  final String nameKurdish;
  final String nameEnglish;
  final Color color;
  final String category;
  final bool isCustom;

  const HabitItem({
    required this.id,
    required this.emoji,
    required this.nameArabic,
    required this.nameKurdish,
    required this.nameEnglish,
    required this.color,
    required this.category,
    this.isCustom = false,
  });

  String getName(String languageCode) {
    if (isCustom && (languageCode == 'arabic' || languageCode == 'kurdish')) {
      return nameEnglish; 
    }
    switch (languageCode) {
      case 'arabic': return nameArabic;
      case 'kurdish': return nameKurdish;
      default: return nameEnglish;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'name': nameEnglish,
    'color': color.value,
    'category': category,
    'isCustom': true,
  };

  factory HabitItem.fromJson(Map<String, dynamic> json) => HabitItem(
    id: json['id'],
    emoji: json['emoji'],
    nameArabic: json['name'],
    nameKurdish: json['name'],
    nameEnglish: json['name'],
    color: Color(json['color']),
    category: json['category'],
    isCustom: true,
  );
}

// Default habits
class HabitsList {
  static const List<HabitItem> defaultHabits = [
    // Health & Fitness
    HabitItem(id: 'exercise', emoji: '🏃', nameArabic: 'تمارين رياضية', nameKurdish: 'وەرزش', nameEnglish: 'Exercise', color: Color(0xFF4CAF50), category: 'health'),
    HabitItem(id: 'gym', emoji: '🏋️', nameArabic: 'صالة الرياضة', nameKurdish: 'جیم', nameEnglish: 'Gym', color: Color(0xFF4CAF50), category: 'health'),
    HabitItem(id: 'tafakkur', emoji: '🧠', nameArabic: 'التفكر', nameKurdish: 'تەفەکور', nameEnglish: 'Tafakkur', color: Color(0xFF673AB7), category: 'health'),
    HabitItem(id: 'sleep', emoji: '😴', nameArabic: 'نوم كافي', nameKurdish: 'خەوی باش', nameEnglish: 'Good Sleep', color: Color(0xFF3F51B5), category: 'health'),
    HabitItem(id: 'water', emoji: '💧', nameArabic: 'شرب الماء', nameKurdish: 'ئاو خواردنەوە', nameEnglish: 'Drink Water', color: Color(0xFF2196F3), category: 'health'),
    HabitItem(id: 'healthy_food', emoji: '🥗', nameArabic: 'أكل صحي', nameKurdish: 'خواردنی تەندروست', nameEnglish: 'Healthy Food', color: Color(0xFF8BC34A), category: 'health'),
    HabitItem(id: 'walking', emoji: '🚶', nameArabic: 'المشي', nameKurdish: 'ڕێکردن', nameEnglish: 'Walking', color: Color(0xFF009688), category: 'health'),
    HabitItem(id: 'swimming', emoji: '🏊', nameArabic: 'السباحة', nameKurdish: 'مەلە', nameEnglish: 'Swimming', color: Color(0xFF03A9F4), category: 'health'),

    // Spiritual
    HabitItem(id: 'prayer', emoji: '🕌', nameArabic: 'الصلاة', nameKurdish: 'نوێژ', nameEnglish: 'Prayer', color: Color(0xFF009688), category: 'spiritual'),
    HabitItem(id: 'quran', emoji: '📖', nameArabic: 'قراءة القرآن', nameKurdish: 'قورئان', nameEnglish: 'Reading Quran', color: Color(0xFF4CAF50), category: 'spiritual'),
    HabitItem(id: 'dhikr', emoji: '📿', nameArabic: 'الذكر', nameKurdish: 'زیکر', nameEnglish: 'Dhikr', color: Color(0xFF795548), category: 'spiritual'),
    HabitItem(id: 'dua', emoji: '🤲', nameArabic: 'الدعاء', nameKurdish: 'دوعا', nameEnglish: "Du'a", color: Color(0xFF607D8B), category: 'spiritual'),
    HabitItem(id: 'fasting', emoji: '🌙', nameArabic: 'الصيام', nameKurdish: 'ڕۆژوو', nameEnglish: 'Fasting', color: Color(0xFF3F51B5), category: 'spiritual'),
    HabitItem(id: 'charity', emoji: '🤝', nameArabic: 'الصدقة', nameKurdish: 'خێرات', nameEnglish: 'Charity', color: Color(0xFF0D9488), category: 'spiritual'),
    HabitItem(id: 'gratitude', emoji: '✨', nameArabic: 'الامتنان', nameKurdish: 'سوپاس', nameEnglish: 'Gratitude', color: Color(0xFFFFC107), category: 'spiritual'),
    
    // Productivity
    HabitItem(id: 'reading', emoji: '📚', nameArabic: 'القراءة', nameKurdish: 'خوێندنەوە', nameEnglish: 'Reading', color: Color(0xFF795548), category: 'productivity'),
    HabitItem(id: 'learning', emoji: '🎓', nameArabic: 'التعلم', nameKurdish: 'فێربوون', nameEnglish: 'Learning', color: Color(0xFF2196F3), category: 'productivity'),
    HabitItem(id: 'work', emoji: '💼', nameArabic: 'العمل', nameKurdish: 'کار', nameEnglish: 'Work', color: Color(0xFF607D8B), category: 'productivity'),
    HabitItem(id: 'planning', emoji: '📝', nameArabic: 'التخطيط', nameKurdish: 'پلان', nameEnglish: 'Planning', color: Color(0xFF9C27B0), category: 'productivity'),
    HabitItem(id: 'studying', emoji: '✏️', nameArabic: 'الدراسة', nameKurdish: 'خوێندن', nameEnglish: 'Studying', color: Color(0xFFFF9800), category: 'productivity'),
    
    // Social
    HabitItem(id: 'family', emoji: '👨‍👩‍👧‍👦', nameArabic: 'وقت العائلة', nameKurdish: 'کاتی خێزان', nameEnglish: 'Family Time', color: Color(0xFF0D9488), category: 'social'),
    HabitItem(id: 'friends', emoji: '👥', nameArabic: 'وقت الأصدقاء', nameKurdish: 'کاتی هاوڕێیان', nameEnglish: 'Friends Time', color: Color(0xFF2196F3), category: 'social'),
    HabitItem(id: 'call_parents', emoji: '📞', nameArabic: 'اتصل بالوالدين', nameKurdish: 'پەیوەندی بە دایک و باوک', nameEnglish: 'Call Parents', color: Color(0xFF4CAF50), category: 'social'),
    HabitItem(id: 'volunteer', emoji: '🤗', nameArabic: 'التطوع', nameKurdish: 'خۆبەخشی', nameEnglish: 'Volunteer', color: Color(0xFFFF9800), category: 'social'),
    HabitItem(id: 'smile', emoji: '😊', nameArabic: 'الابتسامة', nameKurdish: 'پێکەنین', nameEnglish: 'Smile', color: Color(0xFFFFC107), category: 'social'),
    
    // Self-care
    HabitItem(id: 'skincare', emoji: '🧴', nameArabic: 'العناية بالبشرة', nameKurdish: 'چاودێری پێست', nameEnglish: 'Skincare', color: Color(0xFF0D9488), category: 'selfcare'),
    HabitItem(id: 'shower', emoji: '🚿', nameArabic: 'الاستحمام', nameKurdish: 'خۆشۆردن', nameEnglish: 'Shower', color: Color(0xFF2196F3), category: 'selfcare'),
    HabitItem(id: 'teeth', emoji: '🦷', nameArabic: 'تنظيف الأسنان', nameKurdish: 'ددان شۆردن', nameEnglish: 'Brush Teeth', color: Color(0xFFFFFFFF), category: 'selfcare'),
    HabitItem(id: 'lecture', emoji: '🎧', nameArabic: 'محاضرة دينية', nameKurdish: 'وتاری ئاینی', nameEnglish: 'Islamic Lecture', color: Color(0xFF673AB7), category: 'selfcare'),
    HabitItem(id: 'journaling', emoji: '📓', nameArabic: 'كتابة اليوميات', nameKurdish: 'ڕۆژنامە', nameEnglish: 'Journaling', color: Color(0xFFFF9800), category: 'selfcare'),
    HabitItem(id: 'nature', emoji: '🌳', nameArabic: 'وقت في الطبيعة', nameKurdish: 'سروشت', nameEnglish: 'Nature Time', color: Color(0xFF4CAF50), category: 'selfcare'),
    
    // Avoid Bad Habits
    HabitItem(id: 'no_smoking', emoji: '🚭', nameArabic: 'بدون تدخين', nameKurdish: 'جگەرە نەکێشان', nameEnglish: 'No Smoking', color: Color(0xFFF44336), category: 'avoid'),
    HabitItem(id: 'no_junkfood', emoji: '🍔', nameArabic: 'بدون وجبات سريعة', nameKurdish: 'فاست فوود نا', nameEnglish: 'No Junk Food', color: Color(0xFFFF9800), category: 'avoid'),
    HabitItem(id: 'no_sugar', emoji: '🍬', nameArabic: 'بدون سكر', nameKurdish: 'شەکر نا', nameEnglish: 'No Sugar', color: Color(0xFF0D9488), category: 'avoid'),
    HabitItem(id: 'no_caffeine', emoji: '☕', nameArabic: 'بدون كافيين', nameKurdish: 'کافین نا', nameEnglish: 'No Caffeine', color: Color(0xFF795548), category: 'avoid'),
    HabitItem(id: 'no_social_media', emoji: '📱', nameArabic: 'بدون سوشيال ميديا', nameKurdish: 'سۆشیال میدیا نا', nameEnglish: 'No Social Media', color: Color(0xFF2196F3), category: 'avoid'),
    HabitItem(id: 'no_tv', emoji: '📺', nameArabic: 'بدون تلفزيون', nameKurdish: 'تەلەڤزیۆن نا', nameEnglish: 'No TV', color: Color(0xFF607D8B), category: 'avoid'),
    HabitItem(id: 'no_anger', emoji: '😤', nameArabic: 'التحكم بالغضب', nameKurdish: 'تووڕەیی نا', nameEnglish: 'No Anger', color: Color(0xFFF44336), category: 'avoid'),
    HabitItem(id: 'no_gossip', emoji: '🤐', nameArabic: 'بدون غيبة', nameKurdish: 'غیبەت نا', nameEnglish: 'No Gossip', color: Color(0xFF9E9E9E), category: 'avoid'),
    HabitItem(id: 'no_lying', emoji: '🤥', nameArabic: 'بدون كذب', nameKurdish: 'درۆ نا', nameEnglish: 'No Lying', color: Color(0xFF14B8A6), category: 'avoid'),
  ];

  static List<String> get categories => ['health', 'spiritual', 'productivity', 'social', 'selfcare', 'avoid'];

  static String getCategoryName(String category, String languageCode) {
    switch (category) {
      case 'health':
        return languageCode == 'arabic' ? 'الصحة واللياقة' : languageCode == 'kurdish' ? 'تەندروستی و لەش ساز' : 'Health & Fitness';
      case 'spiritual':
        return languageCode == 'arabic' ? 'الروحانية' : languageCode == 'kurdish' ? 'ڕۆحی' : 'Spiritual';
      case 'productivity':
        return languageCode == 'arabic' ? 'الإنتاجية' : languageCode == 'kurdish' ? 'بەرهەمداری' : 'Productivity';
      case 'social':
        return languageCode == 'arabic' ? 'الاجتماعية' : languageCode == 'kurdish' ? 'کۆمەڵایەتی' : 'Social';
      case 'selfcare':
        return languageCode == 'arabic' ? 'العناية بالنفس' : languageCode == 'kurdish' ? 'چاودێری خۆ' : 'Self-care';
      case 'avoid':
        return languageCode == 'arabic' ? 'عادات للتجنب' : languageCode == 'kurdish' ? 'دووربوون لە' : 'Avoid';
      default:
        return category;
    }
  }
}

// User's habit tracking data
class UserHabit {
  final String habitId;
  final DateTime startDate;
  final List<DateTime> completedDates;
  int currentStreak;
  int bestStreak;
  String? reminderTime;
  int? reminderId;

  UserHabit({
    required this.habitId,
    required this.startDate,
    required this.completedDates,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.reminderTime,
    this.reminderId,
  });

  Map<String, dynamic> toJson() => {
    'habitId': habitId,
    'startDate': startDate.toIso8601String(),
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'reminderTime': reminderTime,
    'reminderId': reminderId,
  };

  factory UserHabit.fromJson(Map<String, dynamic> json) => UserHabit(
    habitId: json['habitId'],
    startDate: DateTime.parse(json['startDate']),
    completedDates: (json['completedDates'] as List).map((d) => DateTime.parse(d)).toList(),
    currentStreak: json['currentStreak'] ?? 0,
    bestStreak: json['bestStreak'] ?? 0,
    reminderTime: json['reminderTime'],
    reminderId: json['reminderId'],
  );

  bool isCompletedToday() {
    final now = DateTime.now();
    return completedDates.any((d) => 
      d.year == now.year && d.month == now.month && d.day == now.day
    );
  }
}

class HabitsService extends ChangeNotifier {
  static const String _userHabitsKey = 'user_habits';
  static const String _customHabitsKey = 'custom_habits';
  
  List<UserHabit> _userHabits = [];
  List<HabitItem> _customHabits = [];
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserHabit> get userHabits => List.unmodifiable(_userHabits);
  
  List<HabitItem> get allAvailableHabits {
    return [...HabitsList.defaultHabits, ..._customHabits];
  }

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get Firestore collection for user habits
  CollectionReference? get _userHabitsCollection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('user_habits');
  }

  /// Get Firestore collection for custom habits
  CollectionReference? get _customHabitsCollection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('custom_habits');
  }

  TimeOfDay? get reminderTime => null;

  Future<void> loadHabits() async {
    // First try to load from Firestore if user is logged in
    if (_userId != null) {
      try {
        // Load custom habits from Firestore
        if (_customHabitsCollection != null) {
          final customSnapshot = await _customHabitsCollection!.get();
          _customHabits = customSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return HabitItem.fromJson(data);
          }).toList();
        }

        // Load user habits from Firestore
        if (_userHabitsCollection != null) {
          final userSnapshot = await _userHabitsCollection!.get();
          _userHabits = userSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return UserHabit.fromJson(data);
          }).toList();
          _updateStreaks();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Error loading from Firestore: $e');
      }
    }
    
    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    
    // Load Custom Habits
    final String? customData = prefs.getString(_customHabitsKey);
    if (customData != null) {
      final List<dynamic> jsonList = json.decode(customData);
      _customHabits = jsonList.map((e) => HabitItem.fromJson(e)).toList();
    }

    // Load User Habits
    final String? data = prefs.getString(_userHabitsKey);
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _userHabits = jsonList.map((e) => UserHabit.fromJson(e)).toList();
      _updateStreaks();
      notifyListeners();
    }
  }

  Future<void> _saveUserHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_userHabits.map((e) => e.toJson()).toList());
    await prefs.setString(_userHabitsKey, data);
  }
  
  Future<void> _saveCustomHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(_customHabits.map((e) => e.toJson()).toList());
    await prefs.setString(_customHabitsKey, data);
  }

  Future<void> _saveUserHabitToFirestore(UserHabit habit) async {
    if (_userHabitsCollection == null) return;
    try {
      await _userHabitsCollection!.doc(habit.habitId).set(habit.toJson());
    } catch (e) {
      debugPrint('Error saving user habit to Firestore: $e');
    }
  }

  Future<void> _deleteUserHabitFromFirestore(String habitId) async {
    if (_userHabitsCollection == null) return;
    try {
      await _userHabitsCollection!.doc(habitId).delete();
    } catch (e) {
      debugPrint('Error deleting user habit from Firestore: $e');
    }
  }

  Future<void> _saveCustomHabitToFirestore(HabitItem habit) async {
    if (_customHabitsCollection == null) return;
    try {
      await _customHabitsCollection!.doc(habit.id).set(habit.toJson());
    } catch (e) {
      debugPrint('Error saving custom habit to Firestore: $e');
    }
  }

  Future<void> _deleteCustomHabitFromFirestore(String habitId) async {
    if (_customHabitsCollection == null) return;
    try {
      await _customHabitsCollection!.doc(habitId).delete();
    } catch (e) {
      debugPrint('Error deleting custom habit from Firestore: $e');
    }
  }

  // --- Habit Management ---

  Future<void> addHabit(String habitId) async {
    if (_userHabits.any((h) => h.habitId == habitId)) return;
    
    int reminderId = habitId.hashCode;
    
    final habit = UserHabit(
      habitId: habitId,
      startDate: DateTime.now(),
      completedDates: [],
      reminderId: reminderId,
    );
    
    // 1. Update local state
    _userHabits.add(habit);
    _saveUserHabits();
    notifyListeners();

    // 2. Sync in background
    _saveUserHabitToFirestore(habit).catchError((e) => debugPrint('Habit Sync Error: $e'));
  }

  Future<void> removeHabit(String habitId) async {
    final habitIdx = _userHabits.indexWhere((h) => h.habitId == habitId);
    if (habitIdx == -1) return;

    // 1. Update local state
    _userHabits.removeAt(habitIdx);
    _saveUserHabits();
    notifyListeners();

    // 2. Sync in background
    _deleteUserHabitFromFirestore(habitId).catchError((e) => debugPrint('Habit Delete Error: $e'));
  }
  
  Future<void> createCustomHabit(String name, String emoji, Color color, String category) async {
    final String id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = HabitItem(
      id: id, 
      emoji: emoji, 
      nameArabic: name, 
      nameKurdish: name, 
      nameEnglish: name, 
      color: color, 
      category: category,
      isCustom: true,
    );
    
    // 1. Local Update
    _customHabits.add(newHabit);
    _saveCustomHabits();
    notifyListeners();

    // 2. Background Sync
    _saveCustomHabitToFirestore(newHabit).catchError((e) => debugPrint('Custom Habit Sync Error: $e'));
  }
  
  Future<void> deleteCustomHabitDefinition(String habitId) async {
    // 1. Local Updates
    _userHabits.removeWhere((h) => h.habitId == habitId);
    _customHabits.removeWhere((h) => h.id == habitId);
    _saveUserHabits();
    _saveCustomHabits();
    notifyListeners();

    // 2. Background Syncs
    _deleteUserHabitFromFirestore(habitId).catchError((e) => debugPrint('Delete Habit Sync Error: $e'));
    _deleteCustomHabitFromFirestore(habitId).catchError((e) => debugPrint('Delete Def Sync Error: $e'));
  }



  // --- Tracking ---

  void _updateStreaks() {
    for (var habit in _userHabits) {
      _calculateStreak(habit);
    }
  }

  void _calculateStreak(UserHabit habit) {
    if (habit.completedDates.isEmpty) {
      habit.currentStreak = 0;
      return;
    }

    habit.completedDates.sort((a, b) => b.compareTo(a));
    
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    for (var date in habit.completedDates) {
      if (_isSameDay(date, checkDate) || _isSameDay(date, checkDate.subtract(const Duration(days: 1)))) {
        streak++;
        checkDate = date;
      } else {
        break;
      }
    }
    
    habit.currentStreak = streak;
    if (streak > habit.bestStreak) {
      habit.bestStreak = streak;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _userHabits.firstWhere((h) => h.habitId == habitId, orElse: () => throw Exception('Habit not found'));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final existingIndex = habit.completedDates.indexWhere((d) => _isSameDay(d, today));
    
    if (existingIndex != -1) {
      habit.completedDates.removeAt(existingIndex);
    } else {
      habit.completedDates.add(today);
    }
    
    _calculateStreak(habit);
    
    // 1. Local update
    _saveUserHabits();
    notifyListeners();

    // 2. Sync in background
    _saveUserHabitToFirestore(habit).catchError((e) => debugPrint('Habit Toggle Sync Error: $e'));
  }

  bool isHabitAdded(String habitId) {
    return _userHabits.any((h) => h.habitId == habitId);
  }

  UserHabit? getUserHabit(String habitId) {
    try {
      return _userHabits.firstWhere((h) => h.habitId == habitId);
    } catch (e) {
      return null;
    }
  }
  
  HabitItem? getHabitDefinition(String habitId) {
    try {
      return allAvailableHabits.firstWhere((h) => h.id == habitId);
    } catch (e) {
      return null;
    }
  }
  
  List<HabitItem> getHabitsByCategory(String category) {
    return allAvailableHabits.where((h) => h.category == category).toList();
  }

  int getTodayCompletedCount() {
    return _userHabits.where((h) => h.isCompletedToday()).length;
  }

  int getTotalHabitsCount() {
    return _userHabits.length;
  }

  double getTodayProgress() {
    if (_userHabits.isEmpty) return 0;
    return getTodayCompletedCount() / getTotalHabitsCount();
  }
  
  int getTotalCompletions() {
    return _userHabits.fold(0, (sum, habit) => sum + habit.completedDates.length);
  }
  
  int getBestStreakOverall() {
    if (_userHabits.isEmpty) return 0;
    return _userHabits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  }
}
