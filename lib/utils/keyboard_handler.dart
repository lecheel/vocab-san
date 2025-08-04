import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';
import 'package:vocab_jp/providers/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class KeyboardHandler extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;

  const KeyboardHandler({
    super.key,
    required this.child,
    required this.focusNode,
  });

  void _handleKeyEvent(BuildContext context, RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final audioService = Provider.of<AudioService>(context, listen: false);

    // Tab switching (Ctrl + 1/2/3/4/5)
    if (event.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        appState.tabController?.animateTo(0);
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        appState.tabController?.animateTo(1);
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        appState.tabController?.animateTo(2); // Favorites
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit4) {
        appState.tabController?.animateTo(3); // Playback
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit5) {
        appState.tabController?.animateTo(4); // Settings
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        _openFile(context);
        return;
      }
    }

    // Only handle practice shortcuts if on the practice tab (index 1)
    if (appState.tabController?.index == 1) {
      _handlePracticeKeys(event, appState, audioService);
    }
    // NEW: Handle shortcuts if on the favorites tab (index 2)
    else if (appState.tabController?.index == 2) {
      _handleFavoritesKeys(event, appState, audioService);
    }
  }

  // NEW: Extracted key handling for practice view for clarity
  void _handlePracticeKeys(RawKeyEvent event, AppState appState, AudioService audioService) {
    final currentCard = appState.currentCard;
    final mediaDir = appState.activeFilePath != null
        ? p.dirname(appState.activeFilePath!)
        : null;

    if (currentCard == null || mediaDir == null) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        appState.previousCard();
        break;
      case LogicalKeyboardKey.arrowRight:
        appState.nextCard();
        break;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.space:
        audioService.playAudio(currentCard.word, mediaDir, lang: 'ja');
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        audioService.playAudio(currentCard.english, mediaDir, lang: 'en');
        break;
      // NEW: Shortcut to favorite a card
      case LogicalKeyboardKey.keyF:
        appState.toggleFavorite(currentCard);
        break;
    }
  }

  // NEW: Key handling for the new favorites view
  void _handleFavoritesKeys(RawKeyEvent event, AppState appState, AudioService audioService) {
    final currentCard = appState.currentFavoriteCard;
    if (currentCard == null) return;

    // To play audio, we need to find the original media directory.
    // This is a limitation: favorited words must have their packs still downloaded.
    final mediaDir = appState.files
            .firstWhere(
                (file) => file.path.contains(p.dirname(currentCard.word)), // Heuristic
                orElse: () => File(''))
            .path;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        appState.previousFavoriteCard();
        break;
      case LogicalKeyboardKey.arrowRight:
        appState.nextFavoriteCard();
        break;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.space:
        if (mediaDir.isNotEmpty) {
          audioService.playAudio(currentCard.word, p.dirname(mediaDir), lang: 'ja');
        }
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (mediaDir.isNotEmpty) {
          audioService.playAudio(currentCard.english, p.dirname(mediaDir), lang: 'en');
        }
        break;
      case LogicalKeyboardKey.keyF:
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        appState.toggleFavorite(currentCard);
        break;
    }
  }

  Future<void> _openFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );
    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      await Provider.of<AppState>(context, listen: false).addFiles(files);
    }
  }


  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: (event) => _handleKeyEvent(context, event),
      child: child,
    );
  }
}
