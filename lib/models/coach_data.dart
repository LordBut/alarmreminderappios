// lib/models/coach_data.dart
class CoachData {
  final String id;
  final String name;
  final Map<String, dynamic>? meta;

  CoachData({required this.id, required this.name, this.meta});

  factory CoachData.fromMap(Map<String, dynamic> map) {
    return CoachData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      meta: map['meta'] as Map<String, dynamic>?,
    );
  }
}
