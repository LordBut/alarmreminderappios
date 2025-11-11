// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Storage helper for profile images and post media.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile picture -> returns download URL
  Future<String> uploadProfilePicture(File file, String uid) async {
    final ref = _storage.ref().child('profiles/$uid/${DateTime.now().millisecondsSinceEpoch}');
    final task = await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Upload media used in posts (image/video)
  Future<String> uploadPostMedia(File file, String uid) async {
    final ref = _storage.ref().child('posts/$uid/${DateTime.now().millisecondsSinceEpoch}');
    final task = await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
