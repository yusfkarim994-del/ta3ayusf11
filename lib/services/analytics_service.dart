import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Developer emails
  static const List<String> developerEmails = [
    'yusfkarim2001@gmail.com',
    'yusfkarim1001@gmail.com',
  ];

  bool get isDeveloper {
    final email = _auth.currentUser?.email;
    return email != null && developerEmails.contains(email.toLowerCase());
  }

  // Track user activity - call on app open
  Future<void> trackUserActivity() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // User doc might not exist, try set with merge
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // Get daily active users count stream
  Stream<int> getDailyActiveUsersStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get weekly active users count stream
  Stream<int> getWeeklyActiveUsersStream() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: 7));

    return _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get monthly active users count stream
  Stream<int> getMonthlyActiveUsersStream() {
    final now = DateTime.now();
    final monthStart = now.subtract(Duration(days: 30));

    return _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get daily user counts for the past 7 days (for chart)
  Future<List<Map<String, dynamic>>> getDailyUserCounts() async {
    final now = DateTime.now();
    List<Map<String, dynamic>> data = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayEnd = DateTime(now.year, now.month, now.day - i + 1);
      
      try {
        final query = await _firestore
            .collection('users')
            .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
            .where('lastActiveAt', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        data.add({
          'date': day,
          'count': query.docs.length,
          'dayName': _getDayName(day.weekday),
        });
      } catch (e) {
        data.add({
          'date': day,
          'count': 0,
          'dayName': _getDayName(day.weekday),
        });
      }
    }

    return data;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  // Get total registered users
  Future<int> getTotalRegisteredUsers() async {
    try {
      final query = await _firestore.collection('users').get();
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get recent logins stream (live updates - shows users who logged in today)
  Stream<List<Map<String, dynamic>>> getRecentLoginsStream() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('lastActiveAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final lastActiveAt = data['lastActiveAt'] as Timestamp?;
            return {
              'name': data['displayName'] ?? 'User',
              'time': lastActiveAt?.toDate(),
              'photoUrl': data['photoURL'],
            };
          }).toList();
        });
  }
}
