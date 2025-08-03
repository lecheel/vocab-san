import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

class AudioService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  // We no longer need _init or _documentsPath because the path will be dynamic.

  // The hashing logic remains identical for both platforms.
  String _getCacheFilename_rust_style(String text, String lang) {
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

  // UPDATED: It now requires the path of the *directory* containing the media.
  Future<void> playAudio(
    String text,
    String mediaDirectoryPath, {
    String lang = "ja",
  }) async {
    if (text.trim().isEmpty) return;

    final String filename = _getCacheFilename_rust_style(text, lang);
    final audioFile = File(p.join(mediaDirectoryPath, filename));

    try {
      isPlaying = true;
      notifyListeners();

      if (await audioFile.exists()) {
        debugPrint("Playing local file: ${audioFile.path}");
        await _audioPlayer.setFilePath(audioFile.path);
      } else {
        // On all platforms, if the file doesn't exist in the documents dir, we can't play it.
        debugPrint(
          "Error: Audio file not found: ${audioFile.path}. It was not in the downloaded ZIP.",
        );
        isPlaying = false;
        notifyListeners();
        return;
      }

      await _audioPlayer.play();
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint("Error playing audio for '$filename'. Error: $e");
    } finally {
      isPlaying = false;
      notifyListeners();
    }
  }

  void stop() {
    _audioPlayer.stop();
    isPlaying = false;
    notifyListeners();
  }
}
