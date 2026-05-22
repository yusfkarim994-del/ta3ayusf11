import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a call room
class CallRoom {
  final String id;
  final String name;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isVideoCall;
  final List<CallParticipant> participants;
  final String groupId; // For group calls
  final String roomType; // 'community', 'group', 'private'

  CallRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.isVideoCall,
    required this.participants,
    required this.groupId,
    required this.roomType,
  });

  factory CallRoom.fromMap(Map<String, dynamic> map, String id) {
    return CallRoom(
      id: id,
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVideoCall: map['isVideoCall'] ?? true,
      participants: (map['participants'] as List<dynamic>?)
          ?.map((p) => CallParticipant.fromMap(p as Map<String, dynamic>))
          .toList() ?? [],
      groupId: map['groupId'] ?? '',
      roomType: map['roomType'] ?? 'community',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVideoCall': isVideoCall,
      'participants': participants.map((p) => p.toMap()).toList(),
      'groupId': groupId,
      'roomType': roomType,
    };
  }

  int get participantCount => participants.length;
}

/// Model for a call participant
class CallParticipant {
  final String odaID;
  final String name;
  final String? photoUrl;
  final DateTime joinedAt;
  final DateTime lastActive;

  CallParticipant({
    required this.odaID,
    required this.name,
    this.photoUrl,
    required this.joinedAt,
    required this.lastActive,
  });

  factory CallParticipant.fromMap(Map<String, dynamic> map) {
    return CallParticipant(
      odaID: map['odaID'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'odaID': odaID,
      'name': name,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }
}

/// Service to manage call rooms in Firebase
class CallRoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _callRoomsRef => _firestore.collection('call_rooms');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;
  String? get currentUserPhoto => _auth.currentUser?.photoURL;

  /// Create or join a call room
  Future<String> createOrJoinRoom({
    required String roomName,
    required String roomId,
    required bool isVideoCall,
    required String groupId,
    required String roomType,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    final roomRef = _callRoomsRef.doc(roomId);
    final roomDoc = await roomRef.get();

    final participant = CallParticipant(
      odaID: currentUserId!,
      name: currentUserName ?? 'User',
      photoUrl: currentUserPhoto,
      joinedAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    if (roomDoc.exists) {
      // Room exists, add participant if not already in, or update lastActive if already in
      final data = roomDoc.data() as Map<String, dynamic>;
      final participants = (data['participants'] as List<dynamic>?) ?? [];
      final existingIndex = participants.indexWhere((p) => p['odaID'] == currentUserId);

      if (existingIndex == -1) {
        await roomRef.update({
          'participants': FieldValue.arrayUnion([participant.toMap()]),
        });
      } else {
        // Update lastActive for existing user
        participants[existingIndex]['lastActive'] = Timestamp.now();
        await roomRef.update({
          'participants': participants,
        });
      }
    } else {
      // Create new room
      final room = CallRoom(
        id: roomId,
        name: roomName,
        createdBy: currentUserId!,
        createdByName: currentUserName ?? 'User',
        createdAt: DateTime.now(),
        isVideoCall: isVideoCall,
        participants: [participant],
        groupId: groupId,
        roomType: roomType,
      );

      await roomRef.set(room.toMap());
    }

    return roomId;
  }

  /// Leave a call room
  Future<void> leaveRoom(String roomId) async {
    if (currentUserId == null) return;

    final roomRef = _callRoomsRef.doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) return;

    final data = roomDoc.data() as Map<String, dynamic>;
    final participants = (data['participants'] as List<dynamic>?) ?? [];

    // Remove current user from participants
    final updatedParticipants = participants
        .where((p) => p['odaID'] != currentUserId)
        .toList();

    if (updatedParticipants.isEmpty) {
      // No more participants, delete the room
      await roomRef.delete();
    } else {
      // Update participants list
      await roomRef.update({
        'participants': updatedParticipants,
      });
    }
  }

  /// Send heartbeat to keep participant alive
  Future<void> sendHeartbeat(String roomId) async {
    if (currentUserId == null) return;
    
    try {
      final roomRef = _callRoomsRef.doc(roomId);
      final roomDoc = await roomRef.get();
      if (!roomDoc.exists) return;

      final data = roomDoc.data() as Map<String, dynamic>;
      final participants = (data['participants'] as List<dynamic>?) ?? [];
      bool updated = false;

      for (var p in participants) {
        if (p['odaID'] == currentUserId) {
          p['lastActive'] = Timestamp.now();
          updated = true;
          break;
        }
      }

      if (updated) {
        await roomRef.update({'participants': participants});
      }
    } catch (e) {
      // Ignore heartbeat errors
    }
  }

  // Helper to filter active participants from a CallRoom
  CallRoom _filterActiveParticipants(CallRoom room) {
    if (room.participants.isEmpty) return room;
    
    final now = DateTime.now();
    final cutoffTime = now.subtract(const Duration(seconds: 45));
    
    final activeParticipants = room.participants.where((p) {
      return p.lastActive.isAfter(cutoffTime);
    }).toList();
    
    return CallRoom(
      id: room.id,
      name: room.name,
      createdBy: room.createdBy,
      createdByName: room.createdByName,
      createdAt: room.createdAt,
      isVideoCall: room.isVideoCall,
      participants: activeParticipants,
      groupId: room.groupId,
      roomType: room.roomType,
    );
  }

  /// Get all active call rooms
  Stream<List<CallRoom>> getActiveRooms() {
    return _callRoomsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CallRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .map(_filterActiveParticipants)
              .where((room) => room.participants.isNotEmpty)
              .toList();
        });
  }

  /// Get active rooms for a specific group
  Stream<List<CallRoom>> getGroupRooms(String groupId) {
    return _callRoomsRef
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CallRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .map(_filterActiveParticipants)
              .where((room) => room.participants.isNotEmpty)
              .toList();
        });
  }

  /// Get community call rooms
  Stream<List<CallRoom>> getCommunityRooms() {
    return _callRoomsRef
        .where('roomType', isEqualTo: 'community')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CallRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .map(_filterActiveParticipants)
              .where((room) => room.participants.isNotEmpty)
              .toList();
        });
  }

  /// Check if there's an active call in a room
  Stream<CallRoom?> getRoomStream(String roomId) {
    return _callRoomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final room = CallRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final activeRoom = _filterActiveParticipants(room);
      if (activeRoom.participants.isEmpty) return null;
      return activeRoom;
    });
  }

  /// Get count of active calls
  Stream<int> getActiveCallsCount() {
    return _callRoomsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CallRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .map(_filterActiveParticipants)
          .where((room) => room.participants.isNotEmpty)
          .length;
    });
  }

  /// Clean up old empty rooms and ghost participants
  Future<void> cleanupEmptyRooms() async {
    final snapshot = await _callRoomsRef.get();
    final now = DateTime.now();
    // Consider participants dead if no heartbeat for 45 seconds
    final cutoffTime = now.subtract(const Duration(seconds: 45));

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = (data['participants'] as List<dynamic>?) ?? [];
      
      if (participants.isEmpty) {
        await doc.reference.delete();
        continue;
      }

      // Filter active participants
      final List<dynamic> activeParticipants = [];
      bool hasGhosts = false;

      for (var p in participants) {
        final lastActiveData = p['lastActive'];
        if (lastActiveData != null) {
          final lastActiveTime = (lastActiveData as Timestamp).toDate();
          if (lastActiveTime.isAfter(cutoffTime)) {
            activeParticipants.add(p);
          } else {
            hasGhosts = true; // Found a dead participant
          }
        } else {
          hasGhosts = true; // Legacy participant without lastActive is a ghost
        }
      }

      // If everyone is a ghost, delete the room; otherwise, update it.
      if (activeParticipants.isEmpty) {
        await doc.reference.delete();
      } else if (hasGhosts) {
        await doc.reference.update({'participants': activeParticipants});
      }
    }
  }
}
