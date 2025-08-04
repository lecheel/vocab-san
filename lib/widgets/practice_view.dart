// lib/widgets/practice_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';
import 'package:vocab_jp/providers/audio_service.dart';
import 'package:vocab_jp/widgets/vocabulary_card.dart';
import 'package:path/path.dart' as p;

class PracticeView extends StatefulWidget {
  const PracticeView({super.key});

  @override
  State<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  // Auto-play state is now managed by AppState provider.

  void _playCurrentJapanese() {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (appState.currentCard != null && appState.activeFilePath != null) {
      final mediaDir = p.dirname(appState.activeFilePath!);
      audioService.playAudio(appState.currentCard!.word, mediaDir, lang: 'ja');
    }
  }

  void _playCurrentEnglish() {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (appState.currentCard != null && appState.activeFilePath != null) {
      final mediaDir = p.dirname(appState.activeFilePath!);
      // BUG FIX: Was playing .word, now correctly plays .english
      audioService.playAudio(
        appState.currentCard!.english,
        mediaDir,
        lang: 'en',
      );
    }
  }

  // This now delegates to the AppState provider
  void _toggleAutoPlay() {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    appState.toggleAutoPlay(audioService);
  }

  @override
  void dispose() {
    // The auto-play lifecycle is now managed by AppState,
    // so we do not stop it when this widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading && appState.vocabulary.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (appState.vocabulary.isEmpty) {
          return const Center(
            child: Text(
              'No vocabulary file loaded.\nPlease select a list from the "Packs" tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final isAutoPlaying = appState.isAutoPlaying;

        // We wrap the entire view's content in a SafeArea widget.
        return SafeArea(
          // We only need padding on the bottom. The AppBar handles the top.
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // The vocabulary card display
                Expanded(child: VocabularyCard(entry: appState.currentCard!)),
                const SizedBox(height: 16),
                // Progress indicator
                Text(
                  'Card ${appState.currentCardIndex + 1} of ${appState.vocabulary.length}',
                ),
                const SizedBox(height: 16),
                // Manual playback controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      tooltip: 'Previous Card (Left Arrow)',
                      onPressed: isAutoPlaying ? null : appState.previousCard,
                      iconSize: 32,
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded),
                      tooltip: 'Play Japanese (Up Arrow / Space)',
                      onPressed: isAutoPlaying ? null : _playCurrentJapanese,
                      color: Colors.lightBlueAccent,
                      iconSize: 40,
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded),
                      tooltip: 'Play English (Down Arrow / Enter)',
                      onPressed: isAutoPlaying ? null : _playCurrentEnglish,
                      color: Colors.greenAccent,
                      iconSize: 40,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      tooltip: 'Next Card (Right Arrow)',
                      onPressed: isAutoPlaying ? null : appState.nextCard,
                      iconSize: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Auto-play button
                ElevatedButton.icon(
                  onPressed: _toggleAutoPlay,
                  icon: Icon(
                    isAutoPlaying
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    isAutoPlaying ? '⏹️ Stop Auto-Play' : '▶️ Start Auto-Play',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAutoPlaying
                        ? Colors.red.shade700
                        : Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
