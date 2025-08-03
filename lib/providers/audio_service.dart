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

  String getCacheFilename(String text, String lang) {
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

    final String filename = getCacheFilename(text, lang);
    final audioFile = File(p.join(mediaDirectoryPath, filename));

    try {
      // Stop any current playback
      await _audioPlayer.stop();

      isPlaying = true;
      notifyListeners();

      if (await audioFile.exists()) {
        await _audioPlayer.setFilePath(audioFile.path);
        await _audioPlayer.play();

        // Wait for completion
        await _audioPlayer.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
        );
      } else {
        debugPrint("Playback failed because file was not found.");
      }
    } catch (e) {
      debugPrint("Error during audio playback: $e");
    } finally {
      isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error stopping audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
