import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final String userName;
  final String? storedPhotoUrl;
  final double radius;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final bool useGradient;

  const UserAvatar({
    Key? key,
    required this.userId,
    required this.userName,
    this.storedPhotoUrl,
    this.radius = 20,
    this.fontSize = 16,
    this.backgroundColor,
    this.textColor,
    this.useGradient = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Try stored URL
    if (storedPhotoUrl != null && storedPhotoUrl!.isNotEmpty) {
      return _buildAvatarImage(storedPhotoUrl!);
    }

    // 2. Fetch from Firestore if stored URL is empty
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return _buildInitials(); // Show initials while loading to prevent flickering
        }

        String? fetchedUrl;
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          fetchedUrl = data?['photoURL'] ?? data?['photoUrl'];
        }

        if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
          return _buildAvatarImage(fetchedUrl);
        }

        // 3. Fallback to initials
        return _buildInitials();
      },
    );
  }

  Widget _buildAvatarImage(String url) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final bgColor = backgroundColor ?? const Color(0xFF667eea);
    final txtColor = textColor ?? (useGradient ? Colors.white : bgColor);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: useGradient ? null : bgColor.withOpacity(0.2),
        gradient: useGradient 
           ? const LinearGradient(colors: [Color(0xFF667eea), Color(0xFFf093fb)])
           : null,
      ),
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
