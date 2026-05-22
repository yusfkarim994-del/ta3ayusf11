import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivateMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final String text;
  final DateTime createdAt;
  final bool isRead;
  final bool isEdited;
  final String? audioUrl;
  final int? audioDuration;
  final Map<String, List<String>> reactions;

  /// Check if this message is an audio message
  bool get isAudio => audioUrl != null && audioUrl!.isNotEmpty;

  PrivateMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.isEdited = false,
    this.audioUrl,
    this.audioDuration,
    this.reactions = const {},
  });

  factory PrivateMessage.fromFirestore(DocumentSnapshot doc) {
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
    
    return PrivateMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      receiverName: data['receiverName'] ?? 'Unknown',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      reactions: reactions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'isEdited': isEdited,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'reactions': reactions,
    };
  }
}

class Conversation {
  final String odirUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isBlocked;

  Conversation({
    required this.odirUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isBlocked = false,
  });
}

class PrivateMessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;
  String? get _currentUserName => _auth.currentUser?.displayName ?? 'User';

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0 
        ? '${userId1}_$userId2' 
        : '${userId2}_$userId1';
  }

  // Send a private message
  Future<bool> sendMessage(String receiverId, String receiverName, String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return false;

    // Check if blocked
    final isBlocked = await isUserBlocked(receiverId);
    if (isBlocked) return false;

    try {
      final chatId = _getChatId(_currentUserId!, receiverId);
      
      await _firestore.collection('private_messages').add({
        'chatId': chatId,
        'senderId': _currentUserId,
        'receiverId': receiverId,
        'senderName': _currentUserName,
        'receiverName': receiverName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'isEdited': false,
      });
      
      // Enforce 1000 message limit for this chat
      _enforceChatMessageLimit(chatId);
      
      return true;
    } catch (e) {
      print('Error sending private message: $e');
      return false;
    }
  }

  // Send an audio message
  Future<bool> sendAudioMessage(String receiverId, String receiverName, String audioUrl, int durationSeconds) async {
    if (_currentUserId == null) return false;

    // Check if blocked
    final isBlocked = await isUserBlocked(receiverId);
    if (isBlocked) return false;

    try {
      final chatId = _getChatId(_currentUserId!, receiverId);
      
      await _firestore.collection('private_messages').add({
        'chatId': chatId,
        'senderId': _currentUserId,
        'receiverId': receiverId,
        'senderName': _currentUserName,
        'receiverName': receiverName,
        'text': '🎤', // Fallback text
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'isEdited': false,
        'audioUrl': audioUrl,
        'audioDuration': durationSeconds,
      });
      
      // Enforce 1000 message limit for this chat
      _enforceChatMessageLimit(chatId);
      
      return true;
    } catch (e) {
      print('Error sending private audio message: $e');
      return false;
    }
  }

  /// Enforce 1000 message limit for a private chat - delete oldest messages if over limit
  Future<void> _enforceChatMessageLimit(String chatId) async {
    const int maxMessages = 1000;
    try {
      // Get count of messages in this chat
      final countSnapshot = await _firestore
          .collection('private_messages')
          .where('chatId', isEqualTo: chatId)
          .count()
          .get();
      final count = countSnapshot.count ?? 0;
      
      if (count > maxMessages) {
        final excess = count - maxMessages;
        
        // Get oldest messages to delete
        final oldestMessages = await _firestore
            .collection('private_messages')
            .where('chatId', isEqualTo: chatId)
            .orderBy('createdAt', descending: false)
            .limit(excess)
            .get();
        
        // Delete oldest messages
        for (final doc in oldestMessages.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Error enforcing message limit: $e');
    }
  }

  // Get all conversations for current user
  Stream<List<Conversation>> getConversations() {
    if (_currentUserId == null) return Stream.value([]);

    // We must execute two separate queries because OR queries with ordering require
    // composite indexes that may not exist. We'll merge them client-side.
    
    final sentStream = _firestore
        .collection('private_messages')
        .where('senderId', isEqualTo: _currentUserId)
        .snapshots();
        
    final receivedStream = _firestore
        .collection('private_messages')
        .where('receiverId', isEqualTo: _currentUserId)
        .snapshots();

    // Combine streams using a simple merge controller approach would be best,
    // but without rxdart, we can nested-listen or use a custom generator.
    // simpler: Return one stream that re-evaluates when either updates.
    // Actually, simple StreamBuilder in UI can't handle two streams easily.
    // Let's use a standard implementation for merging snapshots.
    
    late StreamController<List<Conversation>> controller;
    controller = StreamController<List<Conversation>>.broadcast(onListen: () {
      List<PrivateMessage> sentMessages = [];
      List<PrivateMessage> receivedMessages = [];
      bool isCancelled = false;
      
      void update() async {
        if (isCancelled) return;
        
        final allMessages = [...sentMessages, ...receivedMessages];
        
        // Group by conversation partner
        final Map<String, List<PrivateMessage>> conversationsMap = {};
        final Map<String, String> userNames = {};
        
        for (var message in allMessages) {
          final otherId = message.senderId == _currentUserId 
              ? message.receiverId 
              : message.senderId;
          final otherName = message.senderId == _currentUserId 
              ? (message.receiverName.isNotEmpty ? message.receiverName : 'User')
              : message.senderName;
          
          if (!conversationsMap.containsKey(otherId)) {
            conversationsMap[otherId] = [];
            userNames[otherId] = otherName;
          }
          conversationsMap[otherId]!.add(message);
        }

        final conversations = <Conversation>[];
        for (var entry in conversationsMap.entries) {
          final messages = entry.value;
          // Sort messages to find last one
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          final lastMsg = messages.first;
          final unread = messages.where((m) => 
              m.receiverId == _currentUserId && !m.isRead
          ).length;
          
          bool isBlocked = false;
          try {
             isBlocked = await isUserBlocked(entry.key);
          } catch (_) {}
          
          conversations.add(Conversation(
            odirUserId: entry.key,
            otherUserName: userNames[entry.key] ?? 'User',
            lastMessage: lastMsg.text,
            lastMessageTime: lastMsg.createdAt,
            unreadCount: unread,
            isBlocked: isBlocked,
          ));
        }

        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        if (!isCancelled && !controller.isClosed) {
          controller.add(conversations);
        }
      }

      final sub1 = sentStream.listen((snapshot) {
        sentMessages = snapshot.docs.map((d) => PrivateMessage.fromFirestore(d)).toList();
        update();
      });
      
      final sub2 = receivedStream.listen((snapshot) {
        receivedMessages = snapshot.docs.map((d) => PrivateMessage.fromFirestore(d)).toList();
        update();
      });
      
      controller.onCancel = () {
        isCancelled = true;
        sub1.cancel();
        sub2.cancel();
      };
    });
    return controller.stream;
  }

  // Get messages with a specific user
  Stream<List<PrivateMessage>> getMessages(String otherUserId, {int limit = 20}) {
    if (_currentUserId == null) return Stream.value([]);
    
    final chatId = _getChatId(_currentUserId!, otherUserId);

    // Fetch all messages for this chatId and sort/limit in Dart to avoid composite index requirements
    return _firestore
        .collection('private_messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => PrivateMessage.fromFirestore(doc)).toList();
          
          // Sort by date (Oldest first)
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Apply pagination limit in Dart
          if (messages.length > limit) {
            return messages.sublist(messages.length - limit);
          }
          return messages;
        });
  }
  
  // Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _firestore.collection('private_messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Mark all messages from user as read
  Future<void> markAllAsRead(String otherUserId) async {
    if (_currentUserId == null) return;

    try {
      final messages = await _firestore
          .collection('private_messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: _currentUserId)
          //.where('isRead', isEqualTo: false) // Avoid composite index
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        final data = doc.data();
        if (data['isRead'] == false) {
           batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      _firestore.collection('private_messages').doc(messageId).delete();
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Edit a message
  Future<bool> editMessage(String messageId, String newText) async {
    if (newText.trim().isEmpty) return false;
    
    try {
      await _firestore.collection('private_messages').doc(messageId).update({
        'text': newText.trim(),
        'isEdited': true,
      });
      return true;
    } catch (e) {
      print('Error editing message: $e');
      return false;
    }
  }

  // Delete entire conversation with a user
  Future<bool> deleteConversation(String otherUserId) async {
    if (_currentUserId == null) return false;

    try {
      // Get all messages between the two users
      final sent = await _firestore
          .collection('private_messages')
          .where('senderId', isEqualTo: _currentUserId)
          .where('receiverId', isEqualTo: otherUserId)
          .get();

      final received = await _firestore
          .collection('private_messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: _currentUserId)
          .get();

      final batch = _firestore.batch();
      for (var doc in sent.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in received.docs) {
        batch.delete(doc.reference);
      }
      batch.commit(); // Fire and forget
      return true;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }

  // Block a user
  Future<bool> blockUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('blocked_users').add({
        'blockerId': _currentUserId,
        'blockedId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Unblock a user
  Future<bool> unblockUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      final blocks = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: _currentUserId)
          .where('blockedId', isEqualTo: userId)
          .get();

      for (var doc in blocks.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // Check if user is blocked by current user
  Future<bool> isUserBlocked(String userId) async {
    if (_currentUserId == null) return false;

    try {
      final blocks = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: _currentUserId)
          .where('blockedId', isEqualTo: userId)
          .get();

      return blocks.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Check if current user is blocked by another user
  Future<bool> isBlockedByUser(String userId) async {
    if (_currentUserId == null) return false;

    try {
      final blocks = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: userId)
          .where('blockedId', isEqualTo: _currentUserId)
          .get();

      return blocks.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get total unread count
  Stream<int> getUnreadCount() {
    if (_currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('private_messages')
        .where('receiverId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
           // Filter for unread messages client-side to avoid index composite requirement
           return snapshot.docs
              .map((doc) => doc.data()['isRead'] as bool? ?? false)
              .where((isRead) => !isRead)
              .length;
        });
  }

  /// Add reaction to a message
  Future<bool> addReaction(String messageId, String emoji) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('private_messages').doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayUnion([_currentUserId]),
      });
      return true;
    } catch (e) {
      print('Error adding reaction: $e');
      return false;
    }
  }

  /// Remove reaction from a message
  Future<bool> removeReaction(String messageId, String emoji) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('private_messages').doc(messageId).update({
        'reactions.$emoji': FieldValue.arrayRemove([_currentUserId]),
      });
      return true;
    } catch (e) {
      print('Error removing reaction: $e');
      return false;
    }
  }

  /// Toggle reaction
  Future<bool> toggleReaction(String messageId, String emoji, bool hasReacted) async {
    if (hasReacted) {
      return removeReaction(messageId, emoji);
    } else {
      return addReaction(messageId, emoji);
    }
  }
}
