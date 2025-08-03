import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';
import 'package:vocab_jp/providers/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

    // Tab switching (Ctrl + 1/2/3)
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
        appState.tabController?.animateTo(2);
        return;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        _openFile(context);
        return;
      }
    }

    // Only handle practice shortcuts if on the practice tab
    if (appState.tabController?.index != 1) return;

    final currentCard = appState.currentCard;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        appState.previousCard();
        break;
      case LogicalKeyboardKey.arrowRight:
        appState.nextCard();
        break;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.space:
        if (currentCard != null) {
          audioService.playAudio(currentCard.word, lang: 'ja');
        }
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (currentCard != null) {
          audioService.playAudio(currentCard.english, lang: 'en');
        }
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
