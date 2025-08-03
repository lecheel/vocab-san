import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class AudioService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _cachePath;
  bool isPlaying = false;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    // This cache path is compatible with the etalk CLI's default
    final cacheDir = await getApplicationCacheDirectory();
    _cachePath = '${cacheDir.path}/etalk';
    await Directory(_cachePath!).create(recursive: true);
  }

  // Generates a predictable filename based on content and voice.
  // This logic should match `etalk`'s internal caching to find existing files.
  String _getCacheKey(String text, String voice) {
    final bytes = utf8.encode('$text-$voice');
    return sha256.convert(bytes).toString();
  }

  Future<void> playAudio(String text, {String lang = "ja"}) async {
    if (_cachePath == null || text.trim().isEmpty) return;

    // Use appropriate voices for etalk
    final voice = lang == 'ja' ? 'ja' : 'en';
    final cacheKey = _getCacheKey(text, voice);
    final audioFile = File('$_cachePath/$cacheKey.mp3');

    if (!await audioFile.exists()) {
      print("Cache miss. Generating audio for: '$text'");
      try {
        final result = await Process.run('etalk', [
          '-t',
          text,
          '-v',
          voice,
          '-o',
          audioFile.path,
        ]);
        if (result.exitCode != 0) {
          print('etalk CLI Error: ${result.stderr}');
          // Optionally, show an error to the user via a dialog or snackbar
          return;
        }
      } catch (e) {
        print(
          "Failed to run etalk process. Is it installed and in your PATH? Error: $e",
        );
        return;
      }
    } else {
      print("Cache hit for: '$text'");
    }

    try {
      isPlaying = true;
      notifyListeners();
      await _audioPlayer.setFilePath(audioFile.path);
      await _audioPlayer.play();
      // Wait for playback to finish
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (e) {
      print("Error playing audio: $e");
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
