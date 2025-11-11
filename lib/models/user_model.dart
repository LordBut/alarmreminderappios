// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an app user with profile, preferences, and account data.
class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final String? subscriptionTier; // e.g., 'Free', 'Champ', 'Grandmaster', 'God'
  final String? notificationSoundId; // ID of selected sound preference
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.bio,
    this.subscriptionTier,
    this.notificationSoundId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a UserModel instance from a Firestore document snapshot.
  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      subscriptionTier: data['subscriptionTier'] ?? 'Free',
      notificationSoundId: data['notificationSoundId'],
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Converts this model to a Firestore-friendly map.
  Map<String, dynamic> toMap() => {
        'email': email,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'bio': bio,
        'subscriptionTier': subscriptionTier,
        'notificationSoundId': notificationSoundId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  /// Returns a modified copy of this model.
  UserModel copyWith({
    String? email,
    String? username,
    String? profileImageUrl,
    String? bio,
    String? subscriptionTier,
    String? notificationSoundId,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      notificationSoundId: notificationSoundId ?? this.notificationSoundId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, username: $username, email: $email, tier: $subscriptionTier, sound: $notificationSoundId)';
}
