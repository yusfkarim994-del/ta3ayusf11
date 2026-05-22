// Script to delete posts with generic author names from Firestore
// Run this with: flutter run -t lib/delete_user_posts.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  // List of author names to delete
  final namesToDelete = ['Unknown', 'User', 'unknown', 'user'];
  
  print('🔍 Fetching posts to delete...');
  
  try {
    final querySnapshot = await firestore
        .collection('community_posts')
        .get();

    print('📊 Total posts in collection: ${querySnapshot.docs.length}');

    int deletedCount = 0;
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final authorName = data['authorName'] ?? '';
      
      // Check if author name matches any to delete or starts with "User #"
      if (namesToDelete.contains(authorName) || 
          authorName.startsWith('User #') ||
          authorName.isEmpty) {
        await doc.reference.delete();
        deletedCount++;
        print('🗑️ Deleted post by "$authorName"');
      }
    }

    print('\n✅ Successfully deleted $deletedCount posts!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
