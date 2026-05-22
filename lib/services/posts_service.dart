import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'xp_service.dart';

/// Community post model
class CommunityPost {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final bool isPinned;
  final bool isEdited;

  CommunityPost({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.isPinned = false,
    this.isEdited = false,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorPhotoUrl: data['authorPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      isPinned: data['isPinned'] ?? false,
      isEdited: data['isEdited'] ?? false,
    );
  }
}

/// Blocked user model for posts
class BlockedPostUser {
  final String id;
  final String name;
  final DateTime blockedAt;

  BlockedPostUser({
    required this.id,
    required this.name,
    required this.blockedAt,
  });

  factory BlockedPostUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlockedPostUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      blockedAt: (data['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Posts service for community posts
class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Developer emails - these are always admin (same as chat_service)
  static const List<String> _developerEmails = [
    'yusfkarim2001@gmail.com',
    'yusfkarim1001@gmail.com',
  ];

  // Cached values
  bool? _cachedIsBlocked;
  bool? _cachedIsAdmin;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get _currentUserEmail => _auth.currentUser?.email;

  /// Get current user name (with number for guests)
  String get _currentUserName {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    
    // If user has email, return displayName or email prefix
    if (!user.isAnonymous && user.email != null) {
      return user.displayName ?? user.email!.split('@').first;
    }
    
    // For guest/anonymous users, generate a number from their UID
    final uid = user.uid;
    final userNumber = uid.hashCode.abs() % 10000; // 0-9999
    return 'User #$userNumber';
  }

  /// Check if current user is a developer by email
  bool get isDeveloperByEmail {
    final email = _currentUserEmail;
    if (email == null) return false;
    return _developerEmails.contains(email.toLowerCase());
  }

  /// Check if current user is admin (developer)
  Future<bool> isCurrentUserAdmin() async {
    if (isDeveloperByEmail) return true;
    
    // Also check if user has admin role in chat_users
    final uid = _currentUserId;
    if (uid == null) return false;
    
    try {
      final doc = await _firestore.collection('chat_users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final role = data['role'] as String?;
        final isAdmin = role == 'admin';
        _cachedIsAdmin = isAdmin;
        return isAdmin;
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
    
    return false;
  }

  /// Sync check for admin status
  bool get isAdmin => isDeveloperByEmail || (_cachedIsAdmin ?? false);

  /// Initialize user status
  Future<void> initializeUserStatus() async {
    await isCurrentUserAdmin();
    await _checkIfBlocked();
  }

  /// Check if current user is blocked from posting
  Future<bool> _checkIfBlocked() async {
    if (isDeveloperByEmail) {
      _cachedIsBlocked = false;
      return false;
    }
    
    final uid = _currentUserId;
    if (uid == null) return false;
    
    try {
      final doc = await _firestore.collection('blocked_post_users').doc(uid).get();
      _cachedIsBlocked = doc.exists;
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking blocked status: $e');
      return false;
    }
  }

  /// Get blocked status (sync)
  bool get isBlocked => _cachedIsBlocked ?? false;

  /// Get all posts stream (pinned first, then by date)
  Stream<List<CommunityPost>> getPosts({int limit = 10}) {
    return _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) => CommunityPost.fromFirestore(doc))
              .toList();
          // Sort: pinned first, then by date
          posts.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
          return posts;
        });
  }

  // Post limit constants
  static const int maxPostsPer12Hours = 5;
  static const Duration postLimitDuration = Duration(hours: 12);

  /// Get number of posts user made in last 12 hours
  Future<int> getUserPostCountLast12Hours() async {
    final uid = _currentUserId;
    if (uid == null) return 0;

    // Admin/developers have no limit
    if (isDeveloperByEmail) return 0;

    try {
      final cutoffTime = DateTime.now().subtract(postLimitDuration);
      final querySnapshot = await _firestore
          .collection('community_posts')
          .where('authorId', isEqualTo: uid)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting user post count: $e');
      return 0;
    }
  }

  /// Get remaining posts user can make
  Future<int> getRemainingPosts() async {
    // Admin/developers have unlimited posts
    if (isDeveloperByEmail) return 999;
    
    final postCount = await getUserPostCountLast12Hours();
    return (maxPostsPer12Hours - postCount).clamp(0, maxPostsPer12Hours);
  }

  /// Check if user can post
  Future<bool> canUserPost() async {
    if (isDeveloperByEmail) return true;
    final remaining = await getRemainingPosts();
    return remaining > 0;
  }

  /// Create a new post
  Future<bool> createPost(String content) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    // Check if user is blocked
    final isUserBlocked = await _checkIfBlocked();
    if (isUserBlocked) {
      debugPrint('User is blocked from posting');
      return false;
    }

    // Check post limit
    final canPost = await canUserPost();
    if (!canPost) {
      debugPrint('User has reached post limit');
      return false;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final photoUrl = userDoc.data()?['photoURL'] ?? userDoc.data()?['photoUrl']; // Read correct field with fallback

      await _firestore.collection('community_posts').add({
        'content': content,
        'authorId': uid,
        'authorName': _currentUserName,
        'authorPhotoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'isPinned': false,
        'isEdited': false,
      });
      
      // Award XP for creating post
      final xpService = XPService();
      await xpService.loadXP();
      await xpService.addXP(XPActivityType.post, description: 'Community post');
      
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  /// Like a post (any user can like)
  Future<bool> likePost(String postId) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final docRef = _firestore.collection('community_posts').doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      
      if (likedBy.contains(uid)) {
        // Already liked, unlike it
        likedBy.remove(uid);
        await docRef.update({
          'likedBy': likedBy,
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Not liked yet, like it
        likedBy.add(uid);
        await docRef.update({
          'likedBy': likedBy,
          'likes': FieldValue.increment(1),
        });
        
        // Award XP for liking (only when adding like)
        final xpService = XPService();
        await xpService.loadXP();
        await xpService.addXP(XPActivityType.like, description: 'Liked a post');
      }
      return true;
    } catch (e) {
      debugPrint('Error liking post: $e');
      return false;
    }
  }

  /// Check if current user has liked a post
  bool hasUserLiked(CommunityPost post) {
    final uid = _currentUserId;
    if (uid == null) return false;
    return post.likedBy.contains(uid);
  }

  /// Add likes to a post (developer only)
  Future<bool> addLikes(String postId, int count) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'likes': FieldValue.increment(count),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding likes: $e');
      return false;
    }
  }

  /// Set likes count directly (developer only)
  Future<bool> setLikes(String postId, int count) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'likes': count,
      });
      return true;
    } catch (e) {
      debugPrint('Error setting likes: $e');
      return false;
    }
  }

  /// Pin a post (developer only)
  Future<bool> pinPost(String postId) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'isPinned': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error pinning post: $e');
      return false;
    }
  }

  /// Unpin a post (developer only)
  Future<bool> unpinPost(String postId) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'isPinned': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error unpinning post: $e');
      return false;
    }
  }

  /// Edit a post (developer only)
  Future<bool> editPost(String postId, String newContent) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).update({
        'content': newContent,
        'isEdited': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error editing post: $e');
      return false;
    }
  }

  /// Delete a post (developer only)
  Future<bool> deletePost(String postId) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('community_posts').doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  /// Block a user from posting (developer only)
  Future<bool> blockUser(String userId, String userName) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('blocked_post_users').doc(userId).set({
        'name': userName,
        'blockedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user (developer only)
  Future<bool> unblockUser(String userId) async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return false;

    try {
      await _firestore.collection('blocked_post_users').doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Get all blocked users stream (for admin panel)
  Stream<List<BlockedPostUser>> getBlockedUsers() {
    return _firestore
        .collection('blocked_post_users')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BlockedPostUser.fromFirestore(doc))
            .toList());
  }

  /// Delete all posts with "Unknown" author name (developer only)
  Future<int> deleteUnknownPosts() async {
    final isAdminUser = await isCurrentUserAdmin();
    if (!isAdminUser) return 0;

    try {
      final querySnapshot = await _firestore
          .collection('community_posts')
          .where('authorName', isEqualTo: 'Unknown')
          .get();

      int deletedCount = 0;
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }
      
      debugPrint('Deleted $deletedCount posts with Unknown author');
      return deletedCount;
    } catch (e) {
      debugPrint('Error deleting unknown posts: $e');
      return 0;
    }
  }
}
