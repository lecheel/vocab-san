import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class AudioService with ChangeNotifier {
  AudioPlayer? _player;
  Completer<void>? _completer;
  bool isPlaying = false;

  String _getCacheFilename_rust_style(String text, String lang) {
    // This function is correct.
    final String langCode;
    final String languageString;
    if (lang == 'ja') {
      langCode = 'ja';
      languageString = 'Japanese';
    } else {
      langCode = 'en';
      languageString = 'English';
    }
    final textBytes = utf8.encode(text);
    final langBytes = utf8.encode(languageString);
    final builder = BytesBuilder();
    builder.add(textBytes);
    builder.add(langBytes);
    final combinedBytes = builder.toBytes();
    final digest = sha256.convert(combinedBytes);
    final fullHash = digest.toString();
    final shortHash = fullHash.substring(0, 16);
    return 'hash_${shortHash}_$langCode.mp3';
  }

  Future<void> playAudio(
    String text,
    String mediaDirectoryPath, {
    String lang = "ja",
  }) async {
    if (text.trim().isEmpty) return;
    await stop(); // Ensure any existing playback is stopped.

    _player = AudioPlayer();
    _completer = Completer<void>();
    final String filename = _getCacheFilename_rust_style(text, lang);
    final audioFile = File(p.join(mediaDirectoryPath, filename));
    StreamSubscription? subscription;

    try {
      if (!await audioFile.exists()) {
        return;
      }

      isPlaying = true;
      notifyListeners();

      subscription = _player!.onPlayerComplete.listen((event) {
        if (_completer != null && !_completer!.isCompleted) {
          _completer!.complete();
        }
      });

      await _player!.play(DeviceFileSource(audioFile.path));
      await _completer!.future;
    } catch (e) {
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.completeError(e);
      }
    } finally {
      isPlaying = false;
      await subscription?.cancel();
      await _player?.release();
      _player = null;
      _completer = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_player != null) {
      // This call will trigger the onPlayerComplete listener in playAudio,
      // which handles the cleanup via its finally block.
      await _player!.stop();
    }
    // Manually complete the future as a fallback to ensure playAudio unblocks.
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }
}
