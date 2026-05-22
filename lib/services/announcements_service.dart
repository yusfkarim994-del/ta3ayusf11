import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Announcement model for admin notifications
class Announcement {
  final String id;
  final String titleEn;
  final String titleAr;
  final String titleKu;
  final String bodyEn;
  final String bodyAr;
  final String bodyKu;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isImportant;

  Announcement({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.titleKu,
    required this.bodyEn,
    required this.bodyAr,
    required this.bodyKu,
    required this.createdAt,
    this.imageUrl,
    this.isImportant = false,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      DateTime createdAtVal = DateTime.now();
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          createdAtVal = (data['createdAt'] as Timestamp).toDate();
        } else if (data['createdAt'] is String) {
          createdAtVal = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
        }
      }
      return Announcement(
        id: doc.id,
        titleEn: data['titleEn']?.toString() ?? '',
        titleAr: data['titleAr']?.toString() ?? '',
        titleKu: data['titleKu']?.toString() ?? '',
        bodyEn: data['bodyEn']?.toString() ?? '',
        bodyAr: data['bodyAr']?.toString() ?? '',
        bodyKu: data['bodyKu']?.toString() ?? '',
        createdAt: createdAtVal,
        imageUrl: data['imageUrl']?.toString(),
        isImportant: data['isImportant'] == true,
      );
    } catch (e) {
      return Announcement(
        id: doc.id,
        titleEn: 'Error parsing announcement',
        titleAr: 'خطأ في قراءة الإشعار',
        titleKu: 'کێشە لە خوێندنەوەی ئاگاداری',
        bodyEn: e.toString(),
        bodyAr: e.toString(),
        bodyKu: e.toString(),
        createdAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'titleEn': titleEn,
    'titleAr': titleAr,
    'titleKu': titleKu,
    'bodyEn': bodyEn,
    'bodyAr': bodyAr,
    'bodyKu': bodyKu,
    'createdAt': Timestamp.fromDate(createdAt),
    'imageUrl': imageUrl,
    'isImportant': isImportant,
  };
}

/// Service to manage admin announcements
class AnnouncementsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collectionName = 'announcements';
  static const String _lastSeenKey = 'last_seen_announcement';
  
  // Admin emails who can post announcements
  static const List<String> adminEmails = [
    'karim1001@gmail.com',
    'yusfkarim2001@gmail.com',
  ];
  
  List<Announcement> _announcements = [];
  int _unreadCount = 0;
  DateTime? _lastSeenTime;
  
  List<Announcement> get announcements => _announcements;
  int get unreadCount => _unreadCount;
  
  bool get isAdmin {
    final user = _auth.currentUser;
    if (user == null) return false;
    return adminEmails.contains(user.email);
  }
  
  /// Initialize and load announcements
  Future<void> init() async {
    await _loadLastSeenTime();
    await loadAnnouncements();
  }
  
  /// Load last seen time from prefs
  Future<void> _loadLastSeenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastSeenKey);
    if (millis != null) {
      _lastSeenTime = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }
  
  /// Save last seen time
  Future<void> _saveLastSeenTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSeenKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  /// Mark all as read
  Future<void> markAllAsRead() async {
    _lastSeenTime = DateTime.now();
    _unreadCount = 0;
    await _saveLastSeenTime();
    notifyListeners();
  }
  
  /// Load announcements from Firestore
  Future<void> loadAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      _announcements = snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
      
      // Calculate unread count
      _unreadCount = _announcements.where((a) {
        if (_lastSeenTime == null) return true;
        return a.createdAt.isAfter(_lastSeenTime!);
      }).length;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    }
  }
  
  /// Stream of announcements
  Stream<List<Announcement>> getAnnouncementsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          _announcements = snapshot.docs
              .map((doc) => Announcement.fromFirestore(doc))
              .toList();
          
          // Update unread count
          _unreadCount = _announcements.where((a) {
            if (_lastSeenTime == null) return true;
            return a.createdAt.isAfter(_lastSeenTime!);
          }).length;
          
          notifyListeners();
          return _announcements;
        });
  }
  
  /// Post new announcement (admin only)
  Future<bool> postAnnouncement({
    required String titleEn,
    required String titleAr,
    required String titleKu,
    required String bodyEn,
    required String bodyAr,
    required String bodyKu,
    String? imageUrl,
    bool isImportant = false,
  }) async {
    if (!isAdmin) return false;
    
    try {
      await _firestore.collection(_collectionName).add({
        'titleEn': titleEn,
        'titleAr': titleAr,
        'titleKu': titleKu,
        'bodyEn': bodyEn,
        'bodyAr': bodyAr,
        'bodyKu': bodyKu,
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
        'isImportant': isImportant,
        'authorEmail': _auth.currentUser?.email,
      });
      
      await loadAnnouncements();
      return true;
    } catch (e) {
      debugPrint('Error posting announcement: $e');
      return false;
    }
  }
  
  /// Delete announcement (admin only)
  Future<bool> deleteAnnouncement(String id) async {
    if (!isAdmin) return false;
    
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      await loadAnnouncements();
      return true;
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      return false;
    }
  }
}
