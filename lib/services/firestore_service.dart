// lib/services/firestore_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/sound_config_model.dart';
import '../models/coach_data.dart';
import 'notification_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------
  // Schedule synchronization / CRUD (core for reminders)
  // ---------------------------------------------------------------------

  /// Call on user login or app start for a signed-in user.
  /// Reads enabled schedules and schedules them locally on this device.
  static Future<void> syncSchedulesToLocal(String uid) async {
    final coll = _db.collection('users').doc(uid).collection('schedules');

    try {
      final snap = await coll.where('enabled', isEqualTo: true).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        // Defensive parsing: allow strings or numbers
        final hour = (data['hour'] is int) ? data['hour'] as int : int.tryParse('${data['hour']}') ?? 0;
        final minute = (data['minute'] is int) ? data['minute'] as int : int.tryParse('${data['minute']}') ?? 0;
        final title = data['title'] as String? ?? 'Reminder';
        final body = data['body'] as String? ?? '';
        final repeats = data['repeats'] as bool? ?? true;

        final intId = (data['intId'] is int) ? data['intId'] as int : _docIdToInt(doc.id);

        // schedule locally
        await NotificationService.scheduleDaily(
          id: intId,
          title: title,
          body: body,
          hour: hour,
          minute: minute,
          repeats: repeats,
          payload: doc.id,
        );
      }
    } catch (e) {
      // Consider logging the error in production
      rethrow;
    }
  }

  /// When the user creates or updates a schedule -> write to Firestore and schedule locally.
  /// `docId` may be provided; pass `null` to create a new document (this helper will create a new doc id).
  static Future<String> saveSchedule(String uid, {String? docId, required Map<String, dynamic> payload}) async {
    final coll = _db.collection('users').doc(uid).collection('schedules');

    try {
      DocumentReference<Map<String, dynamic>> docRef;
      if (docId == null || docId.isEmpty) {
        docRef = coll.doc();
        docId = docRef.id;
      } else {
        docRef = coll.doc(docId);
      }

      // Ensure server timestamps for created/updated
      final dataToSave = <String, dynamic>{
        ...payload,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!payload.containsKey('createdAt')) 'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(dataToSave, SetOptions(merge: true));

      // compute intId (prefer provided intId)
      final intId = (payload['intId'] is int) ? payload['intId'] as int : _docIdToInt(docId);

      // Immediately schedule locally (device)
      await NotificationService.scheduleDaily(
        id: intId,
        title: payload['title'] as String? ?? 'Reminder',
        body: payload['body'] as String? ?? '',
        hour: payload['hour'] as int? ?? 0,
        minute: payload['minute'] as int? ?? 0,
        repeats: payload['repeats'] as bool? ?? true,
        payload: docId,
      );

      return docId;
    } catch (e) {
      rethrow;
    }
  }

  /// Backwards-compatible wrapper for callers that used positional arguments earlier.
  static Future<String> saveSchedulePositional(String uid, String docId, Map<String, dynamic> payload) {
    // If UI passed an empty docId as '', pass null so a new doc will be created.
    final normalizedDocId = (docId.isEmpty) ? null : docId;
    return saveSchedule(uid, docId: normalizedDocId, payload: payload);
  }

  /// Delete schedule doc and cancel local notification
  static Future<void> deleteSchedule(String uid, String docId) async {
    final docRef = _db.collection('users').doc(uid).collection('schedules').doc(docId);
    try {
      final snap = await docRef.get();
      final data = snap.data();
      final intId = (data != null && data['intId'] is int) ? data['intId'] as int : _docIdToInt(docId);

      await docRef.delete();
      await NotificationService.cancel(intId);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Utilities & helpers
  // ---------------------------------------------------------------------

  /// Simple deterministic conversion of string id -> int (32-bit)
  /// Keep positive 32-bit range to be safe for local notification ids.
  static int _docIdToInt(String id) {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = ((hash << 5) - hash) + id.codeUnitAt(i);
      hash &= 0x7FFFFFFF; // keep positive 32-bit
    }
    return hash;
  }

  /// Optional: read user prefs (monitoring replaced by schedule behavior)
  static Future<Map<String, dynamic>> getUserPrefs(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  static Future<void> updateUserPref(String uid, String key, dynamic value) async {
    await _db.collection('users').doc(uid).set({key: value}, SetOptions(merge: true));
  }

  /// (Optional) Helper: listen for remote changes to schedules and apply local updates.
  /// Use this if you want real-time sync (e.g. when user modifies schedules on another device).
  /// Caller should cancel the returned subscription when no longer needed.
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenAndSyncSchedules(String uid) {
    final coll = _db.collection('users').doc(uid).collection('schedules');

    return coll.snapshots().listen((snapshot) {
      // Handle changes asynchronously but don't await each change in sequence here.
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();
        final intId = (data != null && data['intId'] is int) ? data['intId'] as int : _docIdToInt(doc.id);

        if (change.type == DocumentChangeType.removed) {
          // Fire-and-forget cancellation
          NotificationService.cancel(intId);
        } else {
          final enabled = data?['enabled'] as bool? ?? true;
          if (enabled) {
            final hour = (data?['hour'] is int) ? data!['hour'] as int : int.tryParse('${data?['hour']}') ?? 0;
            final minute = (data?['minute'] is int) ? data!['minute'] as int : int.tryParse('${data?['minute']}') ?? 0;
            final title = data?['title'] as String? ?? 'Reminder';
            final body = data?['body'] as String? ?? '';
            final repeats = data?['repeats'] as bool? ?? true;

            NotificationService.scheduleDaily(
              id: intId,
              title: title,
              body: body,
              hour: hour,
              minute: minute,
              repeats: repeats,
              payload: doc.id,
            );
          } else {
            NotificationService.cancel(intId);
          }
        }
      }
    }, onError: (e) {
      // Consider logging
    });
  }

  // ---------------------------------------------------------------------
  // Additional helpers used by UI screens
  // ---------------------------------------------------------------------

  /// Create an initial user profile document under `users/{uid}`.
  static Future<void> createInitialUserProfile(String uid, String username, String email) async {
    final docRef = _db.collection('users').doc(uid);
    await docRef.set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'subscriptionTier': 'Free',
    }, SetOptions(merge: true));
  }

  /// Read user document and return UserModel
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  /// Return a list of ScheduleModel for a user (all schedules)
  static Future<List<ScheduleModel>> getUserSchedules(String uid) async {
    final coll = _db.collection('users').doc(uid).collection('schedules');
    final snap = await coll.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => ScheduleModel.fromDoc(d)).toList();
  }

  /// Create a post (accomplishment). Expects PostModel with id='' (id assigned by server).
  static Future<String> createPost(PostModel post) async {
    final docRef = _db.collection('posts').doc();
    final data = post.toMap();
    // Only add expiresAt if provided
    final mapToSave = <String, dynamic>{...data, 'createdAt': FieldValue.serverTimestamp()};
    if (post.expiresAt != null) {
      mapToSave['expiresAt'] = Timestamp.fromDate(post.expiresAt!);
    }
    await docRef.set(mapToSave);
    return docRef.id;
  }

  /// Get recent non-expired posts (global or you can scope to user)
  static Future<List<PostModel>> getRecentPosts({int limit = 50}) async {
    final now = DateTime.now();
    final snap = await _db
        .collection('posts')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => PostModel.fromDoc(d)).toList();
  }

  /// Fetch notification-sound metadata from Firestore
  static Future<List<SoundConfigModel>> fetchNotificationSounds() async {
    final snap = await _db.collection('notification_sounds').orderBy('name').get();
    return snap.docs.map((d) {
      final data = d.data();
      return SoundConfigModel.fromMap(data, d.id);
    }).toList();
  }

  /// Fetch coaches data as typed CoachData list.
  static Future<List<CoachData>> fetchCoaches() async {
    final snap = await _db.collection('coaches').orderBy('displayName').get();
    return snap.docs.map((d) {
      final data = d.data();
      final name = (data['displayName'] as String?) ?? (data['name'] as String?) ?? 'Coach';
      return CoachData(id: d.id, name: name, meta: data);
    }).toList();
  }

  /// Save user selections for coaches/videos (simple save under users/{uid}/coachSelections)
  static Future<void> saveSelectedCoaches(
      String uid, Map<String, Map<String, String?>> videoMap, Map<String, Map<String, bool>> enabledMap) async {
    final doc = _db.collection('users').doc(uid);
    await doc.set({
      'coachVideoMap': videoMap,
      'coachEnabledMap': enabledMap,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
