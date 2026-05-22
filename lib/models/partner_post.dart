import 'package:cloud_firestore/cloud_firestore.dart';

class PartnerPost {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String contactInfo;
  final String contactType; // 'whatsapp' or 'telegram'
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  PartnerPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.contactInfo,
    required this.contactType,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'contactInfo': contactInfo,
      'contactType': contactType,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PartnerPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      contactInfo: data['contactInfo'] ?? '',
      contactType: data['contactType'] ?? 'telegram',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
