import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommitmentLetter {
  final String id;
  final String content;
  final String userName;
  final DateTime createdAt;

  CommitmentLetter({
    required this.id,
    required this.content,
    required this.userName,
    required this.createdAt,
  });

  factory CommitmentLetter.fromJson(Map<String, dynamic> json) {
    return CommitmentLetter(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      userName: json['userName'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'userName': userName,
    'createdAt': createdAt.toIso8601String(),
  };
}

class CommitmentService extends ChangeNotifier {
  List<CommitmentLetter> _letters = [];
  int _currentIndex = 0;
  static const String _lettersKey = 'commitment_letters';

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CommitmentLetter> get letters => _letters;
  int get totalLetters => _letters.length;
  CommitmentLetter? get currentLetter => _letters.isNotEmpty ? _letters[_currentIndex] : null;

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Get Firestore collection for current user
  CollectionReference? get _collection {
    final uid = _userId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('commitment_letters');
  }

  Future<void> loadLetters() async {
    // First try to load from Firestore if user is logged in
    if (_userId != null && _collection != null) {
      try {
        final snapshot = await _collection!.get();
        _letters = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CommitmentLetter.fromJson(data);
        }).toList();
        // Sort by date descending (newest first)
        _letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error loading commitment letters from Firestore: $e');
      }
    }
    
    // Fallback to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final lettersJson = prefs.getString(_lettersKey);
      
      if (lettersJson != null && lettersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(lettersJson);
        _letters = decoded.map((e) => CommitmentLetter.fromJson(e)).toList();
        _letters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading commitment letters: $e');
    }
  }

  Future<void> _saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lettersJson = jsonEncode(_letters.map((l) => l.toJson()).toList());
      await prefs.setString(_lettersKey, lettersJson);
    } catch (e) {
      debugPrint('Error saving commitment letters: $e');
    }
  }

  Future<void> _saveToFirestore(CommitmentLetter letter) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(letter.id).set(letter.toJson());
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

  void nextLetter() {
    if (_letters.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _letters.length;
      notifyListeners();
    }
  }

  void previousLetter() {
    if (_letters.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _letters.length) % _letters.length;
      notifyListeners();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _letters.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<bool> addLetter(String content, String userName) async {
    try {
      final letter = CommitmentLetter(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        userName: userName,
        createdAt: DateTime.now(),
      );
      _letters.insert(0, letter);
      _currentIndex = 0;
      await _saveLocally();
      await _saveToFirestore(letter);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding commitment letter: $e');
      return false;
    }
  }

  Future<void> updateLetter(String id, String content) async {
    try {
      final index = _letters.indexWhere((l) => l.id == id);
      if (index != -1) {
        final updatedLetter = CommitmentLetter(
          id: id,
          content: content,
          userName: _letters[index].userName,
          createdAt: _letters[index].createdAt,
        );
        _letters[index] = updatedLetter;
        await _saveLocally();
        await _saveToFirestore(updatedLetter);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating commitment letter: $e');
    }
  }

  Future<void> deleteLetter(String id) async {
    try {
      _letters.removeWhere((l) => l.id == id);
      if (_currentIndex >= _letters.length && _letters.isNotEmpty) {
        _currentIndex = _letters.length - 1;
      }
      await _saveLocally();
      await _deleteFromFirestore(id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting commitment letter: $e');
    }
  }

  String formatDate(DateTime date, String language) {
    final months = language == 'arabic' 
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : language == 'kurdish'
            ? ['کانوونی دووەم', 'شوبات', 'ئازار', 'نیسان', 'ئایار', 'حوزەیران', 'تەمووز', 'ئاب', 'ئەیلوول', 'تشرینی یەکەم', 'تشرینی دووەم', 'کانوونی یەکەم']
            : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
