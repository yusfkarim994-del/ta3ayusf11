// Script to delete all posts with "Unknown" author from Firestore
// Run this with: flutter run -t lib/delete_unknown_posts.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  print('🔍 Searching for posts with Unknown author...');
  
  try {
    // Query for posts with "Unknown" author
    final querySnapshot = await firestore
        .collection('community_posts')
        .where('authorName', isEqualTo: 'Unknown')
        .get();

    print('📊 Found ${querySnapshot.docs.length} posts with Unknown author');

    if (querySnapshot.docs.isEmpty) {
      print('✅ No Unknown posts to delete');
      return;
    }

    // Delete each document
    int deletedCount = 0;
    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
      deletedCount++;
      if (deletedCount % 10 == 0) {
        print('🗑️ Deleted $deletedCount posts...');
      }
    }

    print('✅ Successfully deleted $deletedCount posts with Unknown author!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
