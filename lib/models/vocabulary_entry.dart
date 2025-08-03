// lib/models/vocabulary_entry.dart

class VocabularyEntry {
  final String word;
  final String romaji;
  final String kanji;
  final String chinese;
  final String english;

  VocabularyEntry({
    required this.word,
    required this.romaji,
    required this.kanji,
    required this.chinese,
    required this.english,
  });

  // Factory constructor to create a VocabularyEntry from a JSON object.
  // It gracefully handles missing keys by providing empty strings as defaults.
  factory VocabularyEntry.fromJson(Map<String, dynamic> json) {
    return VocabularyEntry(
      word: json['word'] as String? ?? '',
      romaji: json['romaji'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      chinese: json['chinese'] as String? ?? '',
      english: json['english'] as String? ?? '',
    );
  }
}
