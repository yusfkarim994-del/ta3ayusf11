// Script to list all unique author names in community_posts
// Run this with: flutter run -t lib/list_authors.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  print('🔍 Fetching all posts...');
  
  try {
    final querySnapshot = await firestore
        .collection('community_posts')
        .get();

    print('📊 Total posts: ${querySnapshot.docs.length}');

    // Collect unique author names
    final authorCounts = <String, int>{};
    
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final authorName = data['authorName'] ?? 'NULL';
      authorCounts[authorName] = (authorCounts[authorName] ?? 0) + 1;
    }

    print('\n📝 Author name counts:');
    authorCounts.forEach((name, count) {
      print('  "$name": $count posts');
    });

  } catch (e) {
    print('❌ Error: $e');
  }
}
