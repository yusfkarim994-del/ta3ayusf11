import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/faith_quotes_data.dart';

class Story {
  final String id;
  final String textAr;
  final String textKu;
  final String textEn;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.textAr,
    this.textKu = '',
    this.textEn = '',
    required this.createdAt,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] ?? '',
      textAr: json['textAr'] ?? '',
      textKu: json['textKu'] ?? '',
      textEn: json['textEn'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'textAr': textAr,
    'textKu': textKu,
    'textEn': textEn,
    'createdAt': createdAt.toIso8601String(),
  };
}

class StoriesService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Story> _stories = [];
  int _currentIndex = 0;
  static const String _storiesKey = 'islamic_stories';

  List<Story> get stories => _stories;
  int get totalStories => _stories.length;
  int get currentIndex => _currentIndex;
  Story? get currentStory => _stories.isNotEmpty ? _stories[_currentIndex % _stories.length] : null;

  Future<void> loadStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getString(_storiesKey);
      
      if (storiesJson != null && storiesJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(storiesJson);
        _stories = decoded.map((e) => Story.fromJson(e)).toList();
      } else {
        // Load 300 faith dose quotes
        _stories = faithDoseQuotes.asMap().entries.map((entry) {
          return Story(
            id: 'default_${entry.key}',
            textAr: entry.value['textAr'] ?? '',
            textKu: entry.value['textKu'] ?? '',
            textEn: entry.value['textEn'] ?? '',
            createdAt: DateTime.now(),
          );
        }).toList();
        await _saveLocally();
      }
      
      // Load user's last seen story index
      await _loadUserStoryIndex();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stories: $e');
    }
  }

  Future<void> _loadUserStoryIndex() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['lastStoryIndex'] != null) {
          _currentIndex = doc.data()!['lastStoryIndex'] as int;
          // Ensure index is valid
          if (_stories.isNotEmpty && _currentIndex >= _stories.length) {
            _currentIndex = 0;
          }
        }
      } catch (e) {
        debugPrint('Error loading story index: $e');
      }
    } else {
      // For anonymous/guest users, use local storage
      final prefs = await SharedPreferences.getInstance();
      _currentIndex = prefs.getInt('lastStoryIndex') ?? 0;
      if (_stories.isNotEmpty && _currentIndex >= _stories.length) {
        _currentIndex = 0;
      }
    }
  }

  Future<void> _saveUserStoryIndex() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastStoryIndex': _currentIndex,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving story index: $e');
      }
    } else {
      // For anonymous/guest users, use local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastStoryIndex', _currentIndex);
    }
  }

  Future<void> _saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = jsonEncode(_stories.map((s) => s.toJson()).toList());
      await prefs.setString(_storiesKey, storiesJson);
    } catch (e) {
      debugPrint('Error saving stories: $e');
    }
  }

  void nextStory() {
    if (_stories.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _stories.length;
      _saveUserStoryIndex();
      notifyListeners();
    }
  }

  void previousStory() {
    if (_stories.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _stories.length) % _stories.length;
      _saveUserStoryIndex();
      notifyListeners();
    }
  }

  Future<bool> addStory(String textAr, {String? textKu, String? textEn}) async {
    try {
      final story = Story(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        textAr: textAr,
        textKu: textKu ?? '',
        textEn: textEn ?? '',
        createdAt: DateTime.now(),
      );
      _stories.insert(0, story);
      await _saveLocally();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding story: $e');
      return false;
    }
  }

  Future<void> updateStory(String id, String textAr, {String? textKu, String? textEn}) async {
    try {
      final index = _stories.indexWhere((s) => s.id == id);
      if (index != -1) {
        _stories[index] = Story(
          id: id,
          textAr: textAr,
          textKu: textKu ?? _stories[index].textKu,
          textEn: textEn ?? _stories[index].textEn,
          createdAt: _stories[index].createdAt,
        );
        await _saveLocally();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating story: $e');
    }
  }

  Future<void> deleteStory(String id) async {
    try {
      _stories.removeWhere((s) => s.id == id);
      if (_currentIndex >= _stories.length && _stories.isNotEmpty) {
        _currentIndex = _stories.length - 1;
      }
      await _saveLocally();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting story: $e');
    }
  }
}
