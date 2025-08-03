import 'package:flutter/material.dart';
import 'package:vocab_jp/models/vocabulary_entry.dart';

class VocabularyCard extends StatelessWidget {
  final VocabularyEntry entry;

  const VocabularyCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextRow(
                'Japanese:',
                entry.word,
                style: textTheme.headlineSmall?.copyWith(fontSize: 32),
              ),
              if (entry.kanji.isNotEmpty && entry.kanji != entry.word)
                _buildTextRow(
                  'Kanji:',
                  entry.kanji,
                  style: textTheme.headlineSmall,
                ),
              if (entry.romaji.isNotEmpty)
                _buildTextRow(
                  'Romaji:',
                  entry.romaji,
                  style: textTheme.titleLarge,
                ),
              if (entry.chinese.isNotEmpty)
                _buildTextRow(
                  'Chinese:',
                  entry.chinese,
                  style: textTheme.titleMedium,
                ),
              const Divider(height: 40, thickness: 1),
              _buildTextRow(
                'English:',
                entry.english,
                style: textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: style?.copyWith(color: Colors.white70),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
