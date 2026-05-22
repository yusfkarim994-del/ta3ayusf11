import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Group privacy type
enum GroupPrivacy { public, private }

/// Group member role
enum GroupMemberRole { owner, admin, member }

/// Chat Group model
class ChatGroup {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final bool isPrivate;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final List<String> pendingRequestIds;
  final DateTime createdAt;

  ChatGroup({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.isPrivate,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    required this.pendingRequestIds,
    required this.createdAt,
  });

  factory ChatGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatGroup(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      description: data['description'],
      isPrivate: data['isPrivate'] ?? false,
      ownerId: data['ownerId'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      pendingRequestIds: List<String>.from(data['pendingRequestIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'isPrivate': isPrivate,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'pendingRequestIds': pendingRequestIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if user is owner
  bool isOwner(String userId) => ownerId == userId;

  /// Check if user is admin
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);

  /// Check if user is member
  bool isMember(String userId) => memberIds.contains(userId) || isAdmin(userId);

  /// Check if user has pending request
  bool hasPendingRequest(String userId) => pendingRequestIds.contains(userId);

  /// Get user's role in group
  GroupMemberRole? getUserRole(String userId) {
    if (isOwner(userId)) return GroupMemberRole.owner;
    if (adminIds.contains(userId)) return GroupMemberRole.admin;
    if (memberIds.contains(userId)) return GroupMemberRole.member;
    return null;
  }
}

/// Group message model
class GroupMessage {
  final String id;
  final String groupId;
  final String text;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final DateTime createdAt;
  final bool isEdited;
  final Map<String, List<String>> reactions;
  // Reply fields
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;
  // Audio fields
  final String? audioUrl;
  final int? audioDuration;
  // Pinned message
  final bool isPinned;

  /// Check if this message is an audio message
  bool get isAudio => audioUrl != null && audioUrl!.isNotEmpty;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.createdAt,
    this.isEdited = false,
    this.reactions = const {},
    this.audioUrl,
    this.audioDuration,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.isPinned = false,
  });

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse reactions map
    Map<String, List<String>> reactions = {};
    if (data['reactions'] != null && data['reactions'] is Map) {
      final reactionsData = data['reactions'] as Map;
      reactionsData.forEach((emoji, userIds) {
        if (userIds is List) {
          reactions[emoji.toString()] = userIds.map((e) => e.toString()).toList();
        }
      });
    }
    
    return GroupMessage(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: data['isEdited'] ?? false,
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      reactions: reactions,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      replyToSenderName: data['replyToSenderName'],
      isPinned: data['isPinned'] ?? false,
    );
  }
}

/// Group Service for managing groups
class GroupService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Developer emails - these are always app admin
  static const List<String> _developerEmails = [
    'yusfkarim2001@gmail.com',
    'yusfkarim1001@gmail.com',
  ];

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get current user email
  String? get _currentUserEmail => _auth.currentUser?.email;

  /// Get current user name
  String get _currentUserName =>
      _auth.currentUser?.displayName ??
      _auth.currentUser?.email?.split('@').first ??
      'User';

  /// Check if current user is an app-level admin (developer)
  bool get isAppAdmin {
    final email = _currentUserEmail;
    if (email == null) return false;
    return _developerEmails.contains(email.toLowerCase());
  }

  // ================= GROUP CRUD =================

  /// Create a new group
  Future<String?> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    bool isPrivate = false,
    List<String>? initialMemberIds,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return null;

    try {
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isPrivate': isPrivate,
        'ownerId': uid,
        'adminIds': [uid], // Owner is also admin
        'memberIds': [uid, ...(initialMemberIds ?? [])],
        'pendingRequestIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  /// Update group name
  Future<bool> updateGroupName(String groupId, String newName) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'name': newName,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating group name: $e');
      return false;
    }
  }

  /// Update group image
  Future<bool> updateGroupImage(String groupId, String? imageUrl) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'imageUrl': imageUrl,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating group image: $e');
      return false;
    }
  }

  /// Update group description
  Future<bool> updateGroupDescription(String groupId, String? description) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'description': description,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating group description: $e');
      return false;
    }
  }

  /// Toggle group privacy (public/private)
  Future<bool> updateGroupPrivacy(String groupId, bool isPrivate) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'isPrivate': isPrivate,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating group privacy: $e');
      return false;
    }
  }

  /// Delete group (owner only)
  Future<bool> deleteGroup(String groupId) async {
    try {
      // Delete all group messages first
      final messages = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .get();
      
      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete the group
      await _firestore.collection('groups').doc(groupId).delete();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting group: $e');
      return false;
    }
  }

  // ================= ADMIN MANAGEMENT =================

  /// Add admin to group
  Future<bool> addAdmin(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding admin: $e');
      return false;
    }
  }

  /// Remove admin from group
  Future<bool> removeAdmin(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing admin: $e');
      return false;
    }
  }

  // ================= MEMBER MANAGEMENT =================

  /// Add member to group (for public groups or by admin)
  Future<bool> addMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'pendingRequestIds': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding member: $e');
      return false;
    }
  }

  /// Remove member from group
  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return false;
    }
  }

  /// Leave group
  Future<bool> leaveGroup(String groupId) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    return removeMember(groupId, uid);
  }

  // ================= JOIN REQUESTS (for private groups) =================

  /// Request to join a private group
  Future<bool> requestToJoin(String groupId) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequestIds': FieldValue.arrayUnion([uid]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error requesting to join: $e');
      return false;
    }
  }

  /// Approve join request
  Future<bool> approveJoinRequest(String groupId, String userId) async {
    return addMember(groupId, userId);
  }

  /// Reject join request
  Future<bool> rejectJoinRequest(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'pendingRequestIds': FieldValue.arrayRemove([userId]),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      return false;
    }
  }

  /// Join public group directly
  Future<bool> joinPublicGroup(String groupId) async {
    final uid = _currentUserId;
    if (uid == null) return false;
    return addMember(groupId, uid);
  }

  // ================= STREAMS =================

  /// Get all groups for current user
  Stream<List<ChatGroup>> getMyGroups() {
    final uid = _currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs.map((doc) => ChatGroup.fromFirestore(doc)).toList();
          groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return groups;
        });
  }

  /// Get all public groups
  Stream<List<ChatGroup>> getPublicGroups() {
    return _firestore
        .collection('groups')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatGroup.fromFirestore(doc)).toList());
  }

  /// Get all private groups (for discovery)
  Stream<List<ChatGroup>> getPrivateGroups() {
    return _firestore
        .collection('groups')
        .where('isPrivate', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatGroup.fromFirestore(doc)).toList());
  }

  /// Get single group
  Stream<ChatGroup?> getGroup(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? ChatGroup.fromFirestore(doc) : null);
  }

  Stream<List<GroupMessage>> getGroupMessages(String groupId, {int limit = 20}) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final msgs = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Fallback for null timestamp (newly sent local messages)
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            // Re-parse reactions map carefully
            Map<String, List<String>> reactions = {};
            if (data['reactions'] != null && data['reactions'] is Map) {
              final reactionsData = data['reactions'] as Map;
              reactionsData.forEach((emoji, userIds) {
                if (userIds is List) {
                  reactions[emoji.toString()] = userIds.map((e) => e.toString()).toList();
                }
              });
            }

            return GroupMessage(
              id: doc.id,
              groupId: data['groupId'] ?? groupId,
              text: data['text'] ?? '',
              senderId: data['senderId'] ?? '',
              senderName: data['senderName'] ?? 'Unknown',
              senderPhotoUrl: data['senderPhotoUrl'],
              createdAt: createdAt,
              isEdited: data['isEdited'] ?? false,
              audioUrl: data['audioUrl'],
              audioDuration: data['audioDuration'],
              reactions: reactions,
              replyToId: data['replyToId'],
              replyToText: data['replyToText'],
              replyToSenderName: data['replyToSenderName'],
              isPinned: data['isPinned'] ?? false,
            );
          }).toList();
          return msgs; // Return newest first
        });
  }

  /// Get pending join requests for a group
  Stream<List<String>> getPendingRequests(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return [];
          final data = doc.data() as Map<String, dynamic>;
          return List<String>.from(data['pendingRequestIds'] ?? []);
        });
  }

  // ================= MESSAGING =================

  /// Send message to group (with optional reply)
  Future<bool> sendMessage(String groupId, String text, {GroupMessage? replyTo}) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final photoUrl = userDoc.data()?['photoURL'] ?? userDoc.data()?['photoUrl'];

      final messageData = <String, dynamic>{
        'text': text,
        'senderId': uid,
        'senderName': _currentUserName,
        'senderPhotoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isEdited': false,
        'isPinned': false,
      };

      // Add reply info if replying to a message
      if (replyTo != null) {
        messageData['replyToId'] = replyTo.id;
        messageData['replyToText'] = replyTo.isAudio 
            ? '🎤 Voice Message' 
            : (replyTo.text.length > 100 ? '${replyTo.text.substring(0, 100)}...' : replyTo.text);
        messageData['replyToSenderName'] = replyTo.senderName;
      }

      await _firestore.collection('groups').doc(groupId).collection('messages').add(messageData);
      
      // Enforce 1000 message limit for this group
      _enforceGroupMessageLimit(groupId);
      
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Send an audio message to group (with optional reply)
  Future<bool> sendAudioMessage(String groupId, String audioUrl, int durationSeconds, {GroupMessage? replyTo}) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final photoUrl = userDoc.data()?['photoURL'] ?? userDoc.data()?['photoUrl'];

      final messageData = <String, dynamic>{
        'text': '🎤', // Fallback text
        'senderId': uid,
        'senderName': _currentUserName,
        'senderPhotoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'isEdited': false,
        'isPinned': false,
        'audioUrl': audioUrl,
        'audioDuration': durationSeconds,
      };

      // Add reply info if replying to a message
      if (replyTo != null) {
        messageData['replyToId'] = replyTo.id;
        messageData['replyToText'] = replyTo.isAudio 
            ? '🎤 Voice Message' 
            : (replyTo.text.length > 100 ? '${replyTo.text.substring(0, 100)}...' : replyTo.text);
        messageData['replyToSenderName'] = replyTo.senderName;
      }

      await _firestore.collection('groups').doc(groupId).collection('messages').add(messageData);
      
      // Enforce 1000 message limit for this group
      _enforceGroupMessageLimit(groupId);
      
      return true;
    } catch (e) {
      debugPrint('Error sending audio message: $e');
      return false;
    }
  }

  /// No limit enforced for groups (keeps all messages)
  Future<void> _enforceGroupMessageLimit(String groupId) async {
     // User specifically requested to not delete group messages.
  }

  /// Pin a message
  Future<bool> pinMessage(String groupId, String messageId) async {
    try {
      // Unpin all previously pinned messages in this group
      final pinnedDocs = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('isPinned', isEqualTo: true)
          .get();
      for (var doc in pinnedDocs.docs) {
        await doc.reference.update({'isPinned': false});
      }

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': true});
      return true;
    } catch (e) {
      debugPrint('Error pinning message: $e');
      return false;
    }
  }

  /// Unpin a message
  Future<bool> unpinMessage(String groupId, String messageId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({'isPinned': false});
      return true;
    } catch (e) {
      debugPrint('Error unpinning message: $e');
      return false;
    }
  }

  /// Edit message
  Future<bool> editMessage(String groupId, String messageId, String newText) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': newText,
        'isEdited': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String groupId, String messageId) async {
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  // ================= HELPERS =================

  /// Get user info from Firestore
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _firestore.collection('chat_users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user info: $e');
      return null;
    }
  }

  // ================= REACTIONS =================

  /// Add reaction to a message
  Future<bool> addReaction(String groupId, String messageId, String emoji) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([uid]),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding reaction: $e');
      return false;
    }
  }

  /// Remove reaction from a message
  Future<bool> removeReaction(String groupId, String messageId, String emoji) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayRemove([uid]),
      });
      return true;
    } catch (e) {
      debugPrint('Error removing reaction: $e');
      return false;
    }
  }

  /// Toggle reaction
  Future<bool> toggleReaction(String groupId, String messageId, String emoji, bool hasReacted) async {
    if (hasReacted) {
      return removeReaction(groupId, messageId, emoji);
    } else {
      return addReaction(groupId, messageId, emoji);
    }
  }
}
