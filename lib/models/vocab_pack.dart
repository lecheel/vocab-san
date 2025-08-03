// lib/models/vocab_pack.dart

class VocabPack {
  final String id;
  final String name;
  final String description;
  final String version;
  final String url;

  VocabPack({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.url,
  });

  factory VocabPack.fromJson(Map<String, dynamic> json) {
    return VocabPack(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      version: json['version'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
