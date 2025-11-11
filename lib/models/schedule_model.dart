// lib/models/schedule_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user-created reminder or scheduled notification.
class ScheduleModel {
  final String id; // Firestore document ID
  final String title;
  final String body;
  final int hour; // 0–23
  final int minute; // 0–59
  final bool repeats; // whether to repeat daily
  final bool enabled;
  final int intId; // integer used for local notification ID
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    required this.repeats,
    required this.enabled,
    required this.intId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Converts Firestore doc → model
  factory ScheduleModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ScheduleModel(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      hour: data['hour'] ?? 0,
      minute: data['minute'] ?? 0,
      repeats: data['repeats'] ?? true,
      enabled: data['enabled'] ?? true,
      intId: data['intId'] ?? _docIdToInt(doc.id),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts model → Firestore map
  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
        'repeats': repeats,
        'enabled': enabled,
        'intId': intId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  /// Simple deterministic hash for string → int
  static int _docIdToInt(String id) {
    var hash = 0;
    for (var i = 0; i < id.length; i++) {
      hash = ((hash << 5) - hash) + id.codeUnitAt(i);
      hash &= 0x7fffffff;
    }
    return hash;
  }

  ScheduleModel copyWith({
    String? title,
    String? body,
    int? hour,
    int? minute,
    bool? repeats,
    bool? enabled,
  }) {
    return ScheduleModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeats: repeats ?? this.repeats,
      enabled: enabled ?? this.enabled,
      intId: intId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'ScheduleModel(id: $id, title: $title, time: $hour:$minute, repeats: $repeats, enabled: $enabled)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
