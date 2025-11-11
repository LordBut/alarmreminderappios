// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a weekly accomplishment post (text/image/video)
class PostModel {
  final String id;
  final String ownerUid;
  final String? text;
  final String? mediaUrl; // image or video URL (Firebase Storage)
  final String? mediaType; // 'image', 'video', or null
  final DateTime createdAt;
  final DateTime expiresAt;

  PostModel({
    required this.id,
    required this.ownerUid,
    this.text,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Create instance from Firestore doc
  factory PostModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PostModel(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': createdAt,
        'expiresAt': expiresAt,
      };

  /// Check if this post has expired (used for weekly reset)
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  String toString() =>
      'PostModel(id: $id, owner: $ownerUid, text: ${text ?? ""}, expiresAt: $expiresAt)';
}
