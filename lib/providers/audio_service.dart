import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class AudioService with ChangeNotifier {
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

    final String filename = _getCacheFilename_rust_style(text, lang);
    final audioFile = File(p.join(mediaDirectoryPath, filename));

    final player = AudioPlayer();
    // A Completer allows us to create a Future that we can manually complete later.
    final completer = Completer<void>();
    StreamSubscription? subscription;

    try {
      if (!await audioFile.exists()) {
        await player.release(); // Clean up player if file doesn't exist
        return;
      }

      isPlaying = true;
      notifyListeners();

      // Listen for the onPlayerComplete event. When it fires, our sound is done.
      subscription = player.onPlayerComplete.listen((event) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Use DeviceFileSource as it is the most direct method for local files.
      await player.play(DeviceFileSource(audioFile.path));

      // Wait here until the onPlayerComplete listener calls completer.complete().
      await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    } finally {
      isPlaying = false;
      notifyListeners();
      // Clean up the stream subscription and release the player resources.
      await subscription?.cancel();
      await player.release();
    }
  }

  void stop() {}
}
