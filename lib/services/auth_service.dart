import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is guest
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // Generate unique 6-digit user ID
  Future<String> _generateUniqueUserId() async {
    final random = Random();
    String userId;
    bool exists = true;
    
    do {
      // Generate 6-digit number (100000 - 999999)
      userId = (100000 + random.nextInt(900000)).toString();
      
      // Check if this ID already exists
      final query = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      exists = query.docs.isNotEmpty;
    } while (exists);
    
    return userId;
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ensure user document exists in Firestore for leaderboard (sync old users)
      if (credential.user != null) {
        await _ensureUserDocumentExists(credential.user!);
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Helper method to ensure user has Firestore document (for old users without documents)
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      
      // Only create if document doesn't exist (don't overwrite existing data)
      if (!doc.exists) {
        final userId = await _generateUniqueUserId();
        await docRef.set({
          'email': user.email,
          'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
          'createdAt': FieldValue.serverTimestamp(),
          'recoveryStartDate': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
          'userId': userId,
        });
      } else {
        // If document exists but no userId, add one
        final data = doc.data();
        if (data != null && data['userId'] == null) {
          final userId = await _generateUniqueUserId();
          await docRef.update({'userId': userId});
        }
      }
    } catch (e) {
      // Silently fail - don't block login if Firestore sync fails
    }
  }

  // Create account with email and password (no verification required)
  Future<UserCredential?> createAccountWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name if provided asynchronously
      if (displayName != null && displayName.isNotEmpty) {
        credential.user?.updateDisplayName(displayName);
      }
      
      // Create user document in Firestore asynchronously to prevent UI hang
      if (credential.user != null) {
        _generateUniqueUserId().then((userId) {
          _firestore.collection('users').doc(credential.user!.uid).set({
            'email': email,
            'displayName': displayName ?? email.split('@').first,
            'createdAt': FieldValue.serverTimestamp(),
            'recoveryStartDate': FieldValue.serverTimestamp(),
            'photoURL': null,
            'userId': userId,
          }, SetOptions(merge: true));
        });
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in as guest (anonymous)
  Future<UserCredential?> signInAsGuest() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions - Arabic messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (أقل من 6 أحرف)';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'operation-not-allowed':
        return 'هذا النوع من تسجيل الدخول غير مفعل';
      case 'too-many-requests':
        return 'محاولات كثيرة، الرجاء الانتظار قليلاً';
      case 'invalid-credential':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      default:
        return 'حدث خطأ: ${e.message}';
    }
  }
}
