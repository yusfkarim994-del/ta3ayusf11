import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/partner_post.dart';

class PartnerDiscoveryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of all discovery posts (Legacy/Current - will be replaced in UI)
  Stream<List<PartnerPost>> getDiscoveryPosts() {
    return _firestore
        .collection('partner_discovery')
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
            .map((doc) => PartnerPost.fromFirestore(doc))
            .toList();
          posts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return posts;
        });
  }

  // Get a batch of posts for pagination
  Future<QuerySnapshot> getDiscoveryPostsSnapshot({int limit = 5, DocumentSnapshot? startAfter}) async {
    Query query = _firestore
        .collection('partner_discovery')
        .orderBy('updatedAt', descending: true)
        .limit(limit);
        
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    return await query.get();
  }

  // Get current user's post if it exists
  Future<PartnerPost?> getMyPost() async {
    if (currentUserId == null) return null;
    
    try {
      final doc = await _firestore
          .collection('partner_discovery')
          .doc(currentUserId)
          .get();
          
      if (doc.exists) {
        return PartnerPost.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error getting my post: $e');
    }
    return null;
  }

  // Create or update a post
  Future<void> savePost({
    required String contactInfo,
    required String contactType,
    required String message,
  }) async {
    if (currentUserId == null) return;
    
    final user = _auth.currentUser!;
    final postRef = _firestore.collection('partner_discovery').doc(currentUserId);
    
    _isLoading = true;
    notifyListeners();
    
    // Non-blocking Firestore update for instantaneous UI feel
    // We don't await this so the UI can proceed immediately
    postRef.set({
      'userId': currentUserId,
      'userName': user.displayName ?? 'User',
      'userPhotoUrl': user.photoURL,
      'contactInfo': contactInfo,
      'contactType': contactType,
      'message': message,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), 
    }, SetOptions(merge: true)).then((_) {
      _isLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint('Error saving post: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  // Delete current user's post
  Future<void> deleteMyPost() async {
    if (currentUserId == null) return;
    
    _firestore.collection('partner_discovery').doc(currentUserId).delete()
      .then((_) => notifyListeners())
      .catchError((e) => debugPrint('Error deleting post: $e'));
  }

  // Admin delete: Delete any post by userId
  Future<void> deletePost(String userId) async {
    _firestore.collection('partner_discovery').doc(userId).delete()
      .then((_) => notifyListeners())
      .catchError((e) => debugPrint('Error deleting post: $e'));
  }
}
