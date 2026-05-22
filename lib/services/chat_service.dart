import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// User roles in the chat system
enum UserRole { user, moderator, admin }

/// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final DateTime createdAt;
  final bool isPinned;
  final bool isEdited;
  // Reply fields
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToText;
  // Audio fields
  final String? audioUrl;
  final int? audioDuration; // in seconds
  // Reactions: emoji -> list of userIds
  final Map<String, List<String>> reactions;

  ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.createdAt,
    this.isPinned = false,
    this.isEdited = false,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
    this.audioUrl,
    this.audioDuration,
    this.reactions = const {},
  });

  /// Check if this message is a reply
  bool get isReply => replyToId != null && replyToId!.isNotEmpty;

  /// Check if this message is an audio message
  bool get isAudio => audioUrl != null && audioUrl!.isNotEmpty;

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse reactions map
    Map<String, List<String>> reactions = {};
    if (data['reactions'] != null) {
      final reactionsData = data['reactions'] as Map<String, dynamic>;
      reactionsData.forEach((emoji, userIds) {
        if (userIds is List) {
          reactions[emoji] = List<String>.from(userIds);
        }
      });
    }
    
    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderRole: _parseRole(data['senderRole']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: data['isPinned'] ?? false,
      isEdited: data['isEdited'] ?? false,
      replyToId: data['replyToId'],
      replyToSenderName: data['replyToSenderName'],
      replyToText: data['replyToText'],
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      reactions: reactions,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.moderator:
        return 'moderator';
      default:
        return 'user';
    }
  }
}

/// Chat user model
class ChatUser {
  final String id;
  final String name;
  final UserRole role;
  final bool isMuted;
  final bool isBlocked;

  ChatUser({
    required this.id,
    required this.name,
    required this.role,
    this.isMuted = false,
    this.isBlocked = false,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatUser(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      role: ChatMessage._parseRole(data['role']),
      isMuted: data['isMuted'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
    );
  }
}

/// Chat service for community messaging
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Developer emails - these are always admin
  static const List<String> _developerEmails = [
    'yusfkarim2001@gmail.com',
    'yusfkarim1001@gmail.com',
  ];

  // Cached user role
  UserRole? _cachedRole;
  bool? _cachedIsMuted;
  bool? _cachedIsBlocked;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get _currentUserEmail => _auth.currentUser?.email;

  /// Get current user name
  String get _currentUserName => _auth.currentUser?.displayName ?? 
      _auth.currentUser?.email?.split('@').first ?? 
      'User';

  /// Check if current user is a developer by email
  bool get _isDeveloperByEmail {
    final email = _currentUserEmail;
    if (email == null) return false;
    return _developerEmails.contains(email.toLowerCase());
  }

  /// Check if current user is admin (developer)
  Future<bool> isCurrentUserAdminAsync() async {
    if (_isDeveloperByEmail) return true;
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  /// Check if current user is admin (sync - uses cache or email check)
  bool get isCurrentUserAdmin {
    if (_isDeveloperByEmail) return true;
    return _cachedRole == UserRole.admin;
  }

  /// Check if current user is moderator
  bool get isCurrentUserModerator {
    if (_isDeveloperByEmail) return false; // Developers are admin, not moderator
    return _cachedRole == UserRole.moderator;
  }

  /// Check if current user is muted (developers are never muted)
  bool get isCurrentUserMuted {
    if (_isDeveloperByEmail) return false;
    return _cachedIsMuted ?? false;
  }

  /// Check if current user is blocked (developers are never blocked)
  bool get isCurrentUserBlocked {
    if (_isDeveloperByEmail) return false;
    return _cachedIsBlocked ?? false;
  }

  /// Get current user's role
  Future<UserRole> getCurrentUserRole() async {
    // Developer by email is always admin
    if (_isDeveloperByEmail) {
      _cachedRole = UserRole.admin;
      _cachedIsMuted = false;
      _cachedIsBlocked = false;
      return UserRole.admin;
    }

    final uid = _currentUserId;
    if (uid == null) return UserRole.user;
    
    try {
      final doc = await _firestore.collection('chat_users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final role = ChatMessage._parseRole(data['role'] as String?);
        _cachedRole = role;
        _cachedIsMuted = data['isMuted'] ?? false;
        _cachedIsBlocked = data['isBlocked'] ?? false;
        return role;
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
    }
    
    _cachedRole = UserRole.user;
    return UserRole.user;
  }

  /// Initialize and cache current user role
  Future<void> initializeUserRole() async {
    await getCurrentUserRole();
  }

  /// Get current user data stream
  Stream<ChatUser?> getCurrentUserStream() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value(null);
    
    return _firestore
        .collection('chat_users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final user = ChatUser.fromFirestore(doc);
          _cachedRole = user.role;
          _cachedIsMuted = user.isMuted;
          _cachedIsBlocked = user.isBlocked;
          return user;
        });
  }

  /// Get all messages stream
  Stream<List<ChatMessage>> getMessages({int limit = 20}) {
    debugPrint('🔵 [ChatService] getMessages() called with limit: $limit');
    return _firestore
        .collection('chat_messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) {
            final data = doc.data();
            // Fallback for null timestamp (newly sent local messages)
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            return ChatMessage(
              id: doc.id,
              text: data['text'] ?? '',
              senderId: data['senderId'] ?? '',
              senderName: data['senderName'] ?? 'Unknown',
              senderRole: ChatMessage._parseRole(data['senderRole']),
              createdAt: createdAt,
              isPinned: data['isPinned'] ?? false,
              isEdited: data['isEdited'] ?? false,
              replyToId: data['replyToId'],
              replyToSenderName: data['replyToSenderName'],
              replyToText: data['replyToText'],
              audioUrl: data['audioUrl'],
              audioDuration: data['audioDuration'],
              reactions: Map<String, List<String>>.from(data['reactions'] ?? {}),
            );
          }).toList();
          
          return messages; // Return descending (Newest first)
        });
  }

  /// Get pinned messages (simplified - no composite index needed)
  Stream<List<ChatMessage>> getPinnedMessages() {
    return _firestore
        .collection('chat_messages')
        .where('isPinned', isEqualTo: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          // Sort locally instead of in query
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages;
        });
  }

  /// Send a new message with optional reply
  Future<bool> sendMessage(String text, {ChatMessage? replyTo}) async {
    final uid = _currentUserId;
    debugPrint('🔵 [ChatService] sendMessage called with text: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."');
    debugPrint('🔵 [ChatService] Current user ID: $uid');
    if (uid == null) {
      debugPrint('🔴 [ChatService] User not authenticated, cannot send message');
      return false;
    }

    try {
      // Check if user is blocked or muted
      final userDoc = await _firestore.collection('chat_users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['isBlocked'] == true) {
          debugPrint('🔴 [ChatService] User is blocked from sending messages');
          return false;
        }
        if (data['isMuted'] == true) {
          debugPrint('🔴 [ChatService] User is muted from sending messages');
          return false;
        }
      }

      // Get user role
      final role = await getCurrentUserRole();
      debugPrint('🔵 [ChatService] User role: $role');

      // Ensure user exists in chat_users
      await _firestore.collection('chat_users').doc(uid).set({
        'name': _currentUserName,
        'role': ChatMessage.roleToString(role),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Build message data
      final messageData = <String, dynamic>{
        'text': text,
        'senderId': uid,
        'senderName': _currentUserName,
        'senderRole': ChatMessage.roleToString(role),
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
        'isEdited': false,
      };

      // Add reply data if replying
      if (replyTo != null) {
        messageData['replyToId'] = replyTo.id;
        messageData['replyToSenderName'] = replyTo.senderName;
        messageData['replyToText'] = replyTo.text.length > 100 
            ? '${replyTo.text.substring(0, 100)}...' 
            : replyTo.text;
      }

      // Send message
      debugPrint('🔵 [ChatService] Sending message to chat_messages collection...');
      final docRef = await _firestore.collection('chat_messages').add(messageData);
      debugPrint('🟢 [ChatService] Message sent successfully! Document ID: ${docRef.id}');

      // Enforce 1000 message limit - delete oldest if over limit
      _enforceMessageLimit();

      return true;
    } catch (e) {
      debugPrint('🔴 [ChatService] Error sending message: $e');
      return false;
    }
  }

  /// Send an audio message
  Future<bool> sendAudioMessage(String audioUrl, int durationSeconds, {ChatMessage? replyTo}) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      // Check if user is blocked or muted
      final userDoc = await _firestore.collection('chat_users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['isBlocked'] == true || data['isMuted'] == true) return false;
      }

      final role = await getCurrentUserRole();

      await _firestore.collection('chat_users').doc(uid).set({
        'name': _currentUserName,
        'role': ChatMessage.roleToString(role),
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final messageData = <String, dynamic>{
        'text': '🎤',
        'senderId': uid,
        'senderName': _currentUserName,
        'senderRole': ChatMessage.roleToString(role),
        'createdAt': FieldValue.serverTimestamp(),
        'isPinned': false,
        'isEdited': false,
        'audioUrl': audioUrl,
        'audioDuration': durationSeconds,
      };

      if (replyTo != null) {
        messageData['replyToId'] = replyTo.id;
        messageData['replyToSenderName'] = replyTo.senderName;
        messageData['replyToText'] = replyTo.text.length > 100 
            ? '${replyTo.text.substring(0, 100)}...' 
            : replyTo.text;
      }

      await _firestore.collection('chat_messages').add(messageData);
      _enforceMessageLimit();
      return true;
    } catch (e) {
      debugPrint('🔴 [ChatService] Error sending audio message: $e');
      return false;
    }
  }

  /// Enforce 2000 message limit - delete oldest messages if over limit
  Future<void> _enforceMessageLimit() async {
    const int maxMessages = 2000;
    try {
      // Get count of messages
      final countSnapshot = await _firestore.collection('chat_messages').count().get();
      final count = countSnapshot.count ?? 0;
      
      if (count > maxMessages) {
        final excess = count - maxMessages;
        debugPrint('🔵 [ChatService] Message limit exceeded: $count messages, deleting $excess oldest');
        
        // Get oldest messages to delete
        final oldestMessages = await _firestore
            .collection('chat_messages')
            .orderBy('createdAt', descending: false)
            .limit(excess)
            .get();
        
        // Delete oldest messages
        for (final doc in oldestMessages.docs) {
          await doc.reference.delete();
        }
        debugPrint('🟢 [ChatService] Deleted $excess old messages to maintain limit');
      }
    } catch (e) {
      debugPrint('🔴 [ChatService] Error enforcing message limit: $e');
    }
  }

  /// Edit a message (own messages only)
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      await _firestore.collection('chat_messages').doc(messageId).update({
        'text': newText,
        'isEdited': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('chat_messages').doc(messageId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Pin a message (admin/mod only)
  Future<bool> pinMessage(String messageId) async {
    try {
      // Unpin all currently pinned messages first
      final pinnedDocs = await _firestore.collection('chat_messages').where('isPinned', isEqualTo: true).get();
      for (var doc in pinnedDocs.docs) {
        await doc.reference.update({'isPinned': false});
      }

      await _firestore.collection('chat_messages').doc(messageId).update({
        'isPinned': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error pinning message: $e');
      return false;
    }
  }

  /// Unpin a message
  Future<bool> unpinMessage(String messageId) async {
    try {
      await _firestore.collection('chat_messages').doc(messageId).update({
        'isPinned': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error unpinning message: $e');
      return false;
    }
  }

  /// Block a user (admin only)
  Future<bool> blockUser(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'isBlocked': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'isBlocked': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Mute a user (admin only)
  Future<bool> muteUser(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'isMuted': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error muting user: $e');
      return false;
    }
  }

  /// Unmute a user
  Future<bool> unmuteUser(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'isMuted': false,
      });
      return true;
    } catch (e) {
      debugPrint('Error unmuting user: $e');
      return false;
    }
  }

  /// Promote user to moderator (admin only)
  Future<bool> promoteToModerator(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'role': 'moderator',
      });
      return true;
    } catch (e) {
      debugPrint('Error promoting user: $e');
      return false;
    }
  }

  /// Demote moderator to user
  Future<bool> demoteFromModerator(String userId) async {
    try {
      await _firestore.collection('chat_users').doc(userId).update({
        'role': 'user',
      });
      return true;
    } catch (e) {
      debugPrint('Error demoting user: $e');
      return false;
    }
  }

  /// Get all users stream (for admin panel)
  Stream<List<ChatUser>> getAllUsers() {
    return _firestore
        .collection('chat_users')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) => ChatUser.fromFirestore(doc))
              .toList();
          // Sort locally by name
          users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return users;
        });
  }

  /// Set current user as developer/admin (use with secret code)
  Future<bool> setAsDeveloper(String secretCode) async {
    // Secret code to become admin - change this to your secret
    const validCode = 'qalay2024dev';
    
    if (secretCode != validCode) return false;
    
    final uid = _currentUserId;
    if (uid == null) return false;
    
    try {
      await _firestore.collection('chat_users').doc(uid).set({
        'name': _currentUserName,
        'role': 'admin',
        'isMuted': false,
        'isBlocked': false,
      }, SetOptions(merge: true));
      
      _cachedRole = UserRole.admin;
      return true;
    } catch (e) {
      debugPrint('Error setting as developer: $e');
      return false;
    }
  }

  /// Add reaction to a message
  Future<bool> addReaction(String messageId, String emoji) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      await _firestore.collection('chat_messages').doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayUnion([uid]),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      return false;
    }
  }

  /// Remove reaction from a message
  Future<bool> removeReaction(String messageId, String emoji) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      await _firestore.collection('chat_messages').doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayRemove([uid]),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      return false;
    }
  }

  /// Toggle reaction (add if not exists, remove if exists)
  Future<bool> toggleReaction(String messageId, String emoji, bool hasReacted) async {
    if (hasReacted) {
      return removeReaction(messageId, emoji);
    } else {
      return addReaction(messageId, emoji);
    }
  }
}
