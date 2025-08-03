import 'dart:io'; // <-- IMPORTANT: Import 'dart:io' to use the Platform class
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AudioService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _cachePath; // This will only be used on Desktop
  bool isPlaying = false;

  AudioService() {
    _init();
  }

  // This initialization step is now conditional.
  Future<void> _init() async {
    // Only set up a writable cache path on desktop platforms.
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      _cachePath = '${Directory.current.path}/assets';
      await Directory(_cachePath!).create(recursive: true);
      debugPrint("Desktop Mode: Writable audio cache path set to: $_cachePath");
    } else {
      debugPrint("Mobile Mode: Using bundled assets only.");
    }
  }

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

  Future<void> playAudio(String text, {String lang = "ja"}) async {
    if (text.trim().isEmpty) return;

    // This filename is generated the same way on all platforms.
    final String filename = _getCacheFilename_rust_style(text, lang);

    // --- PLATFORM-SPECIFIC LOGIC ---
    try {
      isPlaying = true;
      notifyListeners();

      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        // --- DESKTOP LOGIC ---
        final audioFile = File('$_cachePath/$filename');

        if (!await audioFile.exists()) {
          debugPrint("Desktop Cache Miss. Generating audio for: '$text'");
          try {
            final result = await Process.run('etalk', [
              '-t',
              text,
              '-v',
              lang,
              '-o',
              audioFile.path,
            ]);
            if (result.exitCode != 0) {
              debugPrint('etalk CLI Error: ${result.stderr}');
              // Stop playback attempt if generation fails
              isPlaying = false;
              notifyListeners();
              return;
            }
          } catch (e) {
            debugPrint(
              "Failed to run etalk process. Is it installed and in your PATH? Error: $e",
            );
            isPlaying = false;
            notifyListeners();
            return;
          }
        } else {
          debugPrint("Desktop Cache Hit. Playing from: ${audioFile.path}");
        }
        await _audioPlayer.setFilePath(audioFile.path);
      } else {
        // --- MOBILE (Android/iOS) LOGIC ---
        final assetPath = 'assets/$filename';
        debugPrint("Mobile Mode: Attempting to play bundled asset: $assetPath");
        await _audioPlayer.setAsset(assetPath);
      }

      // --- COMMON PLAYBACK LOGIC ---
      await _audioPlayer.play();
      await _audioPlayer.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint(
        "Error playing audio for '$filename'. Asset may be missing. Error: $e",
      );
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
