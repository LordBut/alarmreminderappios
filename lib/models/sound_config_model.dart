// lib/models/sound_config_model.dart
class SoundConfigModel {
  final String id;
  final String name;
  final String uri;
  final String tier;

  SoundConfigModel({
    required this.id,
    required this.name,
    required this.uri,
    required this.tier,
  });

  factory SoundConfigModel.fromMap(Map<String, dynamic> map, String id) {
    return SoundConfigModel(
      id: id,
      name: map['name'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      tier: map['tier'] as String? ?? 'Free',
    );
  }
}
