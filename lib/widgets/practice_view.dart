// lib/widgets/practice_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';
import 'package:vocab_jp/providers/audio_service.dart';
import 'package:vocab_jp/widgets/vocabulary_card.dart';

class PracticeView extends StatefulWidget {
  const PracticeView({super.key});

  @override
  State<PracticeView> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;

  // Helper function to play the Japanese audio for the current card
  void _playCurrentJapanese() {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (appState.currentCard != null) {
      audioService.playAudio(appState.currentCard!.word, lang: 'ja');
    }
  }

  // Helper function to play the English audio for the current card
  void _playCurrentEnglish() {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    if (appState.currentCard != null) {
      audioService.playAudio(appState.currentCard!.english, lang: 'en');
    }
  }

  // Toggles the auto-play state
  void _toggleAutoPlay() {
    if (_isAutoPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.vocabulary.isEmpty || _isAutoPlaying) return;

    setState(() => _isAutoPlaying = true);
    _runAutoPlayCycle();
  }

  // The core loop for auto-play functionality
  void _runAutoPlayCycle() async {
    // Safety check: stop if the user has cancelled auto-play
    if (!_isAutoPlaying) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);
    final card = appState.currentCard;

    if (card == null) {
      _stopAutoPlay();
      return;
    }

    try {
      // Play Japanese audio for the configured number of repeats
      for (int i = 0; i < appState.jpRepeats; i++) {
        if (!_isAutoPlaying) return; // Allow interruption
        await audioService.playAudio(card.word, lang: 'ja');
        if (i < appState.jpRepeats - 1)
          await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!_isAutoPlaying) return;
      await Future.delayed(Duration(seconds: appState.delaySeconds));

      // Play English audio for the configured number of repeats
      for (int i = 0; i < appState.enRepeats; i++) {
        if (!_isAutoPlaying) return; // Allow interruption
        await audioService.playAudio(card.english, lang: 'en');
        if (i < appState.enRepeats - 1)
          await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!_isAutoPlaying) return;
      await Future.delayed(Duration(seconds: appState.delaySeconds));

      // Move to the next card
      appState.nextCard();

      // Schedule the next cycle using a Timer to avoid deep recursion stacks
      _autoPlayTimer = Timer(
        const Duration(milliseconds: 100),
        _runAutoPlayCycle,
      );
    } catch (e) {
      print("Error during auto-play cycle: $e");
      _stopAutoPlay();
    }
  }

  // Stops the auto-play loop and cleans up resources
  void _stopAutoPlay() {
    setState(() {
      _isAutoPlaying = false;
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
      Provider.of<AudioService>(context, listen: false).stop();
    });
  }

  @override
  void dispose() {
    _stopAutoPlay(); // Ensure the timer is cancelled when the widget is disposed
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
              'No vocabulary file loaded.\nPlease add a JSON file in the "File List" tab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Padding(
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
                    onPressed: _isAutoPlaying ? null : appState.previousCard,
                    iconSize: 32,
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    tooltip: 'Play Japanese (Up Arrow / Space)',
                    onPressed: _isAutoPlaying ? null : _playCurrentJapanese,
                    color: Colors.lightBlueAccent,
                    iconSize: 40,
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    tooltip: 'Play English (Down Arrow / Enter)',
                    onPressed: _isAutoPlaying ? null : _playCurrentEnglish,
                    color: Colors.greenAccent,
                    iconSize: 40,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    tooltip: 'Next Card (Right Arrow)',
                    onPressed: _isAutoPlaying ? null : appState.nextCard,
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Auto-play button
              ElevatedButton.icon(
                onPressed: _toggleAutoPlay,
                icon: Icon(
                  _isAutoPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline,
                ),
                label: Text(
                  _isAutoPlaying ? '⏹️ Stop Auto-Play' : '▶️ Start Auto-Play',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAutoPlaying
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
        );
      },
    );
  }
}
