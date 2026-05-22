import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Tip {
  final String id;
  final String textAr;
  final String textKu;
  final String textEn;
  final DateTime createdAt;

  Tip({
    required this.id,
    required this.textAr,
    required this.textKu,
    required this.textEn,
    required this.createdAt,
  });

  factory Tip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tip(
      id: doc.id,
      textAr: data['textAr'] ?? '',
      textKu: data['textKu'] ?? '',
      textEn: data['textEn'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'textAr': textAr,
    'textKu': textKu,
    'textEn': textEn,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class TipsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Admin emails - users who can manage tips
  static const List<String> adminEmails = [
    'yusfkarim2001@gmail.com',
    'yusfkarim1001@gmail.com',
  ];
  
  List<Tip> _tips = [];
  int _currentTipIndex = 0;
  
  List<Tip> get tips => _tips;
  Tip? get currentTip => _tips.isNotEmpty ? _tips[_currentTipIndex % _tips.length] : null;
  int get currentIndex => _currentTipIndex;
  int get totalTips => _tips.length;
  
  bool get isAdmin {
    final user = _auth.currentUser;
    if (user == null) return false;
    final email = user.email?.toLowerCase();
    return email != null && adminEmails.any((e) => e.toLowerCase() == email);
  }

  Future<void> loadTips() async {
    try {
      final snapshot = await _firestore
          .collection('urgeTips')
          .orderBy('createdAt', descending: false)
          .limit(30)
          .get(const GetOptions(source: Source.serverAndCache));
      _tips = snapshot.docs.map((doc) => Tip.fromFirestore(doc)).toList();
      
      // Load user's last seen tip index
      await _loadUserTipIndex();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tips: $e');
    }
  }

  Future<void> _loadUserTipIndex() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['lastTipIndex'] != null) {
          _currentTipIndex = doc.data()!['lastTipIndex'] as int;
          // Ensure index is valid
          if (_tips.isNotEmpty && _currentTipIndex >= _tips.length) {
            _currentTipIndex = 0;
          }
        }
      } catch (e) {
        debugPrint('Error loading tip index: $e');
      }
    } else {
      // For anonymous/guest users, use local storage
      final prefs = await SharedPreferences.getInstance();
      _currentTipIndex = prefs.getInt('lastTipIndex') ?? 0;
      if (_tips.isNotEmpty && _currentTipIndex >= _tips.length) {
        _currentTipIndex = 0;
      }
    }
  }

  Future<void> _saveUserTipIndex() async {
    final user = _auth.currentUser;
    if (user != null && !user.isAnonymous) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastTipIndex': _currentTipIndex,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving tip index: $e');
      }
    } else {
      // For anonymous/guest users, use local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastTipIndex', _currentTipIndex);
    }
  }

  void nextTip() {
    if (_tips.isNotEmpty) {
      _currentTipIndex = (_currentTipIndex + 1) % _tips.length;
      _saveUserTipIndex();
      notifyListeners();
    }
  }

  void previousTip() {
    if (_tips.isNotEmpty) {
      _currentTipIndex = (_currentTipIndex - 1 + _tips.length) % _tips.length;
      _saveUserTipIndex();
      notifyListeners();
    }
  }

  /// Translate Arabic text to target language using MyMemory API (free)
  Future<String> translateText(String arabicText, String targetLang) async {
    if (arabicText.isEmpty) return '';
    
    try {
      // MyMemory Translation API (free, no API key needed)
      final langPair = 'ar|$targetLang';
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(arabicText)}&langpair=$langPair'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'] ?? arabicText;
        }
      }
      return arabicText; // Fallback to original
    } catch (e) {
      debugPrint('Translation error: $e');
      return arabicText; // Fallback to original
    }
  }

  /// Add a new tip with auto-translation
  Future<bool> addTip(String textAr, {String? textKu, String? textEn}) async {
    if (!isAdmin) return false;
    if (textAr.trim().isEmpty) return false;
    
    try {
      // Auto-translate to English only if not provided (not Kurdish)
      String translatedKu = textKu ?? '';
      String translatedEn = textEn ?? '';
      
      // Only auto-translate to English, not Kurdish
      if (translatedEn.isEmpty) {
        translatedEn = await translateText(textAr, 'en');
      }
      
      await _firestore.collection('urgeTips').add({
        'textAr': textAr.trim(),
        'textKu': translatedKu.trim(),
        'textEn': translatedEn.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await loadTips();
      return true;
    } catch (e) {
      debugPrint('Error adding tip: $e');
      return false;
    }
  }

  /// Update an existing tip
  Future<bool> updateTip(String id, String textAr, {String? textKu, String? textEn}) async {
    if (!isAdmin) return false;
    
    try {
      // Auto-translate to English only if not provided (not Kurdish)
      String translatedKu = textKu ?? '';
      String translatedEn = textEn ?? '';
      
      // Only auto-translate to English, not Kurdish
      if (translatedEn.isEmpty) {
        translatedEn = await translateText(textAr, 'en');
      }
      
      await _firestore.collection('urgeTips').doc(id).update({
        'textAr': textAr.trim(),
        'textKu': translatedKu.trim(),
        'textEn': translatedEn.trim(),
      });
      
      await loadTips();
      return true;
    } catch (e) {
      debugPrint('Error updating tip: $e');
      return false;
    }
  }

  /// Delete a tip
  Future<bool> deleteTip(String id) async {
    if (!isAdmin) return false;
    
    try {
      await _firestore.collection('urgeTips').doc(id).delete();
      
      // Adjust current index if needed
      if (_currentTipIndex >= _tips.length - 1 && _currentTipIndex > 0) {
        _currentTipIndex--;
      }
      
      await loadTips();
      return true;
    } catch (e) {
      debugPrint('Error deleting tip: $e');
      return false;
    }
  }

  /// Get tip text based on language
  String getTipText(Tip tip, String language) {
    switch (language) {
      case 'ar':
        return tip.textAr;
      case 'ku':
        return tip.textKu.isNotEmpty ? tip.textKu : tip.textAr;
      case 'en':
        return tip.textEn.isNotEmpty ? tip.textEn : tip.textAr;
      default:
        return tip.textAr;
    }
  }
}
