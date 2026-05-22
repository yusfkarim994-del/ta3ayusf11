import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Partner request status
enum RequestStatus { pending, accepted, rejected }

// Partner request model
class PartnerRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final RequestStatus status;
  final DateTime createdAt;

  PartnerRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.status,
    required this.createdAt,
  });

  factory PartnerRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toUserName: data['toUserName'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// Accountability partner model
class AccountabilityPartner {
  final String partnerId;
  final String partnerName;
  final String? photoUrl;
  final bool isOnline;
  final DateTime partnershipStartDate;
  final int partnerDaysClean;
  final double partnerTodayProgress;
  final int streakDays;
  final int todayHabitsTotal;
  final int todayHabitsCompleted;
  final int journalCount;
  final DateTime? lastActiveAt;

  AccountabilityPartner({
    required this.partnerId,
    required this.partnerName,
    this.photoUrl,
    this.isOnline = false,
    required this.partnershipStartDate,
    this.partnerDaysClean = 0,
    this.partnerTodayProgress = 0.0,
    this.streakDays = 0,
    this.todayHabitsTotal = 0,
    this.todayHabitsCompleted = 0,
    this.journalCount = 0,
    this.lastActiveAt,
  });

  // Get habits completion percentage
  int get habitsPercent => todayHabitsTotal > 0 
      ? ((todayHabitsCompleted / todayHabitsTotal) * 100).round() 
      : 0;
}

// User search result for finding partners
class UserSearchResult {
  final String id;
  final String name;
  final String? photoUrl;
  final bool hasPartner;
  final String? userId;

  UserSearchResult({
    required this.id,
    required this.name,
    this.photoUrl,
    this.hasPartner = false,
    this.userId,
  });
}

class AccountabilityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Maximum number of partners allowed
  static const int MAX_PARTNERS = 5;

  List<AccountabilityPartner> _currentPartners = [];
  List<PartnerRequest> _pendingOutgoingRequests = [];
  List<PartnerRequest> _incomingRequests = [];
  bool _isLoading = false;

  // Getters
  List<AccountabilityPartner> get currentPartners => _currentPartners;
  List<PartnerRequest> get pendingOutgoingRequests => _pendingOutgoingRequests;
  List<PartnerRequest> get incomingRequests => _incomingRequests;
  bool get isLoading => _isLoading;
  bool get hasPartners => _currentPartners.isNotEmpty;
  bool get canAddPartner => _currentPartners.length < MAX_PARTNERS;
  int get partnersCount => _currentPartners.length;
  bool get hasPendingRequests => _pendingOutgoingRequests.isNotEmpty;

  String? get _currentUserId => _auth.currentUser?.uid;
  String get _currentUserName => _auth.currentUser?.displayName ?? 'User';

  // Initialize and load data
  Future<void> initialize() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadCurrentPartners(),
      _loadPendingOutgoingRequests(),
      _loadIncomingRequests(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  // Load current partners (supports multiple)
  Future<void> _loadCurrentPartners() async {
    try {
      final doc = await _firestore
          .collection('accountability_partners')
          .doc(_currentUserId)
          .get();

      _currentPartners = [];

      if (!doc.exists) return;

      final data = doc.data()!;
      
      // Support both old (partnerId) and new (partnerIds) formats
      List<String> partnerIds = [];
      if (data['partnerIds'] != null) {
        partnerIds = List<String>.from(data['partnerIds'] ?? []);
      } else if (data['partnerId'] != null) {
        // Backwards compatibility
        partnerIds = [data['partnerId'] as String];
      }

      if (partnerIds.isEmpty) return;

      // Load all partners in parallel
      final futures = partnerIds.map((partnerId) => _loadPartnerData(partnerId, doc));
      final partners = await Future.wait(futures);
      
      _currentPartners = partners.whereType<AccountabilityPartner>().toList();
    } catch (e) {
      debugPrint('Error loading partners: $e');
    }
  }

  // Load single partner data
  Future<AccountabilityPartner?> _loadPartnerData(String partnerId, DocumentSnapshot partnershipDoc) async {
    try {
      final partnerDoc = await _firestore.collection('users').doc(partnerId).get();
      
      if (!partnerDoc.exists) return null;

      final partnerData = partnerDoc.data()!;
      
      // Calculate partner's days clean
      int daysClean = 0;
      int streakDays = 0;
      if (partnerData['recoveryStartDate'] != null) {
        final startDate = (partnerData['recoveryStartDate'] as Timestamp).toDate();
        daysClean = DateTime.now().difference(startDate).inDays;
        streakDays = daysClean;
      }

      // Get photo URL
      final photoUrl = partnerData['photoURL'] as String?;
      
      // Check if online (active in last 5 minutes)
      DateTime? lastActiveAt;
      bool isOnline = false;
      if (partnerData['lastActiveAt'] != null) {
        lastActiveAt = (partnerData['lastActiveAt'] as Timestamp).toDate();
        isOnline = DateTime.now().difference(lastActiveAt).inMinutes < 5;
      }

      // Get today's habits data
      int habitsTotal = 0;
      int habitsCompleted = 0;
      try {
        final today = DateTime.now();
        final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final habitsDoc = await _firestore
            .collection('user_habits')
            .doc(partnerId)
            .collection('daily')
            .doc(dateKey)
            .get();
        
        if (habitsDoc.exists) {
          final data = habitsDoc.data()!;
          habitsTotal = (data['total'] ?? 0) as int;
          habitsCompleted = (data['completed'] ?? 0) as int;
        }
      } catch (e) {
        debugPrint('Error loading partner habits: $e');
      }

      // Get journal count
      int journalCount = 0;
      try {
        final journalQuery = await _firestore
            .collection('journals')
            .where('userId', isEqualTo: partnerId)
            .limit(100)
            .get();
        journalCount = journalQuery.docs.length;
      } catch (e) {
        debugPrint('Error loading journal count: $e');
      }

      return AccountabilityPartner(
        partnerId: partnerId,
        partnerName: partnerData['displayName'] ?? 'Partner',
        photoUrl: photoUrl,
        isOnline: isOnline,
        partnershipStartDate: (partnershipDoc.data() as Map<String, dynamic>?)?['createdAt'] != null 
            ? ((partnershipDoc.data() as Map<String, dynamic>)['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        partnerDaysClean: daysClean,
        streakDays: streakDays,
        todayHabitsTotal: habitsTotal,
        todayHabitsCompleted: habitsCompleted,
        journalCount: journalCount,
        lastActiveAt: lastActiveAt,
      );
    } catch (e) {
      debugPrint('Error loading partner data: $e');
      return null;
    }
  }


  // Load pending outgoing requests (all of them)
  Future<void> _loadPendingOutgoingRequests() async {
    try {
      final query = await _firestore
          .collection('accountability_requests')
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      _pendingOutgoingRequests = query.docs
          .map((doc) => PartnerRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }
  }

  // Load incoming requests
  Future<void> _loadIncomingRequests() async {
    try {
      final query = await _firestore
          .collection('accountability_requests')
          .where('toUserId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      _incomingRequests = query.docs
          .map((doc) => PartnerRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading incoming requests: $e');
    }
  }

  // Stream incoming requests
  Stream<List<PartnerRequest>> getIncomingRequestsStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('accountability_requests')
        .where('toUserId', isEqualTo: _currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnerRequest.fromFirestore(doc))
            .toList());
  }

  // Stream outgoing requests (sent by current user)
  Stream<List<PartnerRequest>> getOutgoingRequestsStream() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('accountability_requests')
        .where('fromUserId', isEqualTo: _currentUserId)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PartnerRequest.fromFirestore(doc))
            .toList());
  }

  // Search users by name
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.isEmpty || _currentUserId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      List<UserSearchResult> results = [];
      for (var doc in querySnapshot.docs) {
        if (doc.id == _currentUserId) continue; // Skip self

        // Check if user already has partner
        final partnerDoc = await _firestore
            .collection('accountability_partners')
            .doc(doc.id)
            .get();
        final hasPartner = partnerDoc.exists && partnerDoc.data()?['partnerId'] != null;

        results.add(UserSearchResult(
          id: doc.id,
          name: doc.data()['displayName'] ?? 'User',
          photoUrl: doc.data()['photoURL'] ?? doc.data()['photoUrl'],
          hasPartner: hasPartner,
          userId: doc.data()['userId'],
        ));
      }
      return results;
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Search user by unique user ID (6-digit code)
  Future<UserSearchResult?> searchUserById(String userId) async {
    if (userId.isEmpty || _currentUserId == null) return null;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      if (doc.id == _currentUserId) return null; // Can't add self

      // Check if user already has max partners
      final partnerDoc = await _firestore
          .collection('accountability_partners')
          .doc(doc.id)
          .get();
      
      bool hasMaxPartners = false;
      if (partnerDoc.exists) {
        final partnerIds = List<String>.from(partnerDoc.data()?['partnerIds'] ?? []);
        if (partnerDoc.data()?['partnerId'] != null && partnerIds.isEmpty) {
          partnerIds.add(partnerDoc.data()!['partnerId'] as String);
        }
        hasMaxPartners = partnerIds.length >= MAX_PARTNERS;
      }

      return UserSearchResult(
        id: doc.id,
        name: doc.data()['displayName'] ?? 'User',
        photoUrl: doc.data()['photoURL'] ?? doc.data()['photoUrl'],
        hasPartner: hasMaxPartners,
        userId: doc.data()['userId'],
      );
    } catch (e) {
      debugPrint('Error searching user by ID: $e');
      return null;
    }
  }

  // Send partner request
  Future<bool> sendPartnerRequest(String toUserId, String toUserName) async {
    if (_currentUserId == null || !canAddPartner) return false;

    // Check if already partners
    if (_currentPartners.any((p) => p.partnerId == toUserId)) return false;

    try {
      // Check if already sent a pending request to this user
      final existingRequest = await _firestore
          .collection('accountability_requests')
          .where('fromUserId', isEqualTo: _currentUserId)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existingRequest.docs.isNotEmpty) return false;
      // Check if target user has reached partner limit
      final targetPartnerDoc = await _firestore
          .collection('accountability_partners')
          .doc(toUserId)
          .get();
      if (targetPartnerDoc.exists) {
        final partnerIds = List<String>.from(targetPartnerDoc.data()?['partnerIds'] ?? []);
        // Also check old format
        if (targetPartnerDoc.data()?['partnerId'] != null && partnerIds.isEmpty) {
          partnerIds.add(targetPartnerDoc.data()!['partnerId'] as String);
        }
        if (partnerIds.length >= MAX_PARTNERS) {
          return false; // Target has reached max partners
        }
      }

      // Create request
      final requestRef = await _firestore.collection('accountability_requests').add({
        'fromUserId': _currentUserId,
        'fromUserName': _currentUserName,
        'toUserId': toUserId,
        'toUserName': toUserName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _pendingOutgoingRequests.add(PartnerRequest(
        id: requestRef.id,
        fromUserId: _currentUserId!,
        fromUserName: _currentUserName,
        toUserId: toUserId,
        toUserName: toUserName,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
      ));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error sending request: $e');
      return false;
    }
  }

  // Cancel a specific outgoing request by ID
  Future<bool> cancelOutgoingRequestById(String requestId) async {
    try {
      await _firestore
          .collection('accountability_requests')
          .doc(requestId)
          .delete();

      _pendingOutgoingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error canceling request: $e');
      return false;
    }
  }

  // Accept partner request
  Future<bool> acceptRequest(PartnerRequest request) async {
    if (_currentUserId == null || !canAddPartner) return false;

    try {
      final batch = _firestore.batch();

      // Update request status
      batch.update(
        _firestore.collection('accountability_requests').doc(request.id),
        {'status': 'accepted'},
      );

      // Add partner to both users' partnerIds array
      final now = FieldValue.serverTimestamp();
      
      // Add to current user's partners
      batch.set(
        _firestore.collection('accountability_partners').doc(_currentUserId),
        {
          'partnerIds': FieldValue.arrayUnion([request.fromUserId]),
          'createdAt': now,
        },
        SetOptions(merge: true),
      );

      // Add current user to sender's partners
      batch.set(
        _firestore.collection('accountability_partners').doc(request.fromUserId),
        {
          'partnerIds': FieldValue.arrayUnion([_currentUserId]),
          'createdAt': now,
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      // Reload data
      await initialize();
      return true;
    } catch (e) {
      debugPrint('Error accepting request: $e');
      return false;
    }
  }

  // Reject partner request
  Future<bool> rejectRequest(PartnerRequest request) async {
    try {
      await _firestore
          .collection('accountability_requests')
          .doc(request.id)
          .update({'status': 'rejected'});

      _incomingRequests.removeWhere((r) => r.id == request.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  // Remove a specific partner by ID
  Future<bool> removePartnerById(String partnerId) async {
    if (_currentUserId == null || !hasPartners) return false;

    try {
      final batch = _firestore.batch();

      // Remove partner from current user's partnerIds
      batch.set(
        _firestore.collection('accountability_partners').doc(_currentUserId),
        {'partnerIds': FieldValue.arrayRemove([partnerId]), 'partnerId': FieldValue.delete()},
        SetOptions(merge: true)
      );

      // Remove current user from partner's partnerIds
      batch.set(
        _firestore.collection('accountability_partners').doc(partnerId),
        {'partnerIds': FieldValue.arrayRemove([_currentUserId]), 'partnerId': FieldValue.delete()},
        SetOptions(merge: true)
      );

      await batch.commit();

      // Remove from local list
      _currentPartners.removeWhere((p) => p.partnerId == partnerId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing partner: $e');
      return false;
    }
  }

  // Remove all partners (end all partnerships)
  Future<bool> removeAllPartners() async {
    if (_currentUserId == null || !hasPartners) return false;

    try {
      final batch = _firestore.batch();

      // Remove current user from all partners' lists
      for (final partner in _currentPartners) {
        batch.set(
          _firestore.collection('accountability_partners').doc(partner.partnerId),
          {'partnerIds': FieldValue.arrayRemove([_currentUserId]), 'partnerId': FieldValue.delete()},
          SetOptions(merge: true)
        );
      }

      // Clear current user's partnership document
      batch.delete(_firestore.collection('accountability_partners').doc(_currentUserId));

      await batch.commit();

      _currentPartners = [];
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing all partners: $e');
      return false;
    }
  }

  // Get specific partner's detailed progress by ID
  Future<Map<String, dynamic>?> getPartnerProgressById(String partnerId) async {
    try {
      // Get partner's user data
      final userDoc = await _firestore.collection('users').doc(partnerId).get();
      if (!userDoc.exists) return null;

      // Calculate days clean
      int daysClean = 0;
      DateTime? startDate;
      if (userDoc.data()?['recoveryStartDate'] != null) {
        startDate = (userDoc.data()!['recoveryStartDate'] as Timestamp).toDate();
        daysClean = DateTime.now().difference(startDate).inDays;
      }

      return {
        'daysClean': daysClean,
        'startDate': startDate,
        'displayName': userDoc.data()?['displayName'] ?? 'Partner',
        'photoUrl': userDoc.data()?['photoUrl'],
      };
    } catch (e) {
      debugPrint('Error getting partner progress: $e');
      return null;
    }
  }

  // Notify all partners of relapse (called when timer is reset)
  Future<void> notifyPartnersOfRelapse() async {
    if (!hasPartners || _currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      
      // Create a relapse notification for each partner
      for (final partner in _currentPartners) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'type': 'partner_relapse',
          'toUserId': partner.partnerId,
          'fromUserId': _currentUserId,
          'fromUserName': _currentUserName,
          'message': 'Your accountability partner needs your support',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error notifying partners: $e');
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
