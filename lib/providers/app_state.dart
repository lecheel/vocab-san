
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_jp/models/vocabulary_entry.dart';
import 'package:vocab_jp/models/vocab_pack.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:vocab_jp/providers/audio_service.dart';

class AppState with ChangeNotifier {
  // This is now the default fallback URL.
  static const String DEFAULT_MANIFEST_URL =
      'https://raw.githubusercontent.com/lecheel/vocab-san/download_pack/main/manifest.json';

  // New variable to hold the current URL.
  String _manifestUrl = DEFAULT_MANIFEST_URL;

  List<File> _files = [];
  List<VocabularyEntry> _vocabulary = [];
  int _currentCardIndex = 0;
  String? _activeFilePath;

  // States for download and manifest loading
  bool _isLoading = false;
  String _statusMessage = '';
  List<VocabPack> _availablePacks = [];
  // Settings
  int _jpRepeats = 2;
  int _enRepeats = 1;
  int _delaySeconds = 1;

  Set<String> _downloadedPackIds = {};
  TabController? tabController;

  // Auto-play state
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  AudioService? _audioServiceForAutoplay;

  // Getters
  Set<String> get downloadedPackIds => _downloadedPackIds;
  String get manifestUrl => _manifestUrl;
  List<File> get files => _files;
  List<VocabularyEntry> get vocabulary => _vocabulary;
  List<VocabPack> get availablePacks => _availablePacks;
  int get currentCardIndex => _currentCardIndex;
  VocabularyEntry? get currentCard =>
      _vocabulary.isEmpty ? null : _vocabulary[_currentCardIndex];
  String? get activeFilePath => _activeFilePath;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  int get jpRepeats => _jpRepeats;
  int get enRepeats => _enRepeats;
  int get delaySeconds => _delaySeconds;

  bool get isAutoPlaying => _isAutoPlaying;

  @override
  void dispose() {
    stopAutoPlay();
    super.dispose();
  }

  // NEW: A single method to orchestrate app startup.
  Future<void> initialize() async {
    await loadSettings();
    await _resumeLastPractice();
  }

  // NEW: Saves the current practice state to SharedPreferences.
  Future<void> _savePracticeState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeFilePath != null && _vocabulary.isNotEmpty) {
      await prefs.setString('lastActiveFilePath', _activeFilePath!);
      await prefs.setInt('lastCardIndex', _currentCardIndex);
    } else {
      // Clear the state if no file is active or vocabulary is empty.
      await prefs.remove('lastActiveFilePath');
      await prefs.remove('lastCardIndex');
    }
  }

  // NEW: Attempts to resume the last practice session on startup.
  Future<void> _resumeLastPractice() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPath = prefs.getString('lastActiveFilePath');
    if (lastPath == null) {
      return; // No session to resume.
    }

    // We need the list of all local files to find the correct File object.
    await scanForLocalVocabulary();

    // Find the file that matches the saved path.
    final lastFile = _files.firstWhere(
      (f) => f.path == lastPath,
      orElse: () => File(''), // Return a dummy if not found.
    );

    if (lastFile.path.isNotEmpty) {
      final lastIndex = prefs.getInt('lastCardIndex') ?? 0;
      // Load the vocabulary from the found file, starting at the saved index.
      await loadVocabulary(lastFile, initialIndex: lastIndex);
    }
  }


  // NEW: A method to update the URL and save it to SharedPreferences
  Future<void> updateManifestUrl(String newUrl) async {
    _manifestUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manifestUrl', newUrl);
    notifyListeners();
  }

  // MODIFIED: Accepts an optional initial index and saves state.
  Future<void> loadVocabulary(File file, {int initialIndex = 0}) async {
    _isLoading = true;
    _activeFilePath = file.path;
    _currentCardIndex = initialIndex;
    notifyListeners();

    try {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      _vocabulary = jsonList
          .map((json) => VocabularyEntry.fromJson(json))
          .toList();
      if (tabController != null) {
        tabController!.animateTo(1);
      }
    } catch (e) {
      debugPrint("Error loading or parsing JSON file: $e");
      _vocabulary = [];
      _activeFilePath = null;
    } finally {
      // Persist the state. This will save the new session on success,
      // or clear the session state if loading failed.
      await _savePracticeState();
    }

    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load playback settings
    _jpRepeats = prefs.getInt('jpRepeats') ?? 2;
    _enRepeats = prefs.getInt('enRepeats') ?? 1;
    _delaySeconds = prefs.getInt('delaySeconds') ?? 1;

    // Load the custom manifest URL, falling back to the default if not set.
    _manifestUrl = prefs.getString('manifestUrl') ?? DEFAULT_MANIFEST_URL;

    notifyListeners();
  }

  // UPDATED: fetchManifest now uses the _manifestUrl variable
  Future<void> fetchManifest() async {
    _isLoading = true;
    _statusMessage = 'Fetching available vocabulary packs...';
    _availablePacks = []; // Clear old packs
    notifyListeners();

    try {
      // Use the (potentially custom) URL from our state variable
      final response = await http.get(Uri.parse(_manifestUrl));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        _availablePacks = jsonList
            .map((json) => VocabPack.fromJson(json))
            .toList();
        _statusMessage = 'Please select a pack to download.';
      } else {
        throw Exception('Failed to load manifest: ${response.statusCode}');
      }
    } catch (e) {
      _statusMessage =
          'Could not fetch pack list from $_manifestUrl. Error: $e';
      _availablePacks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadAndUnzipVocabulary(VocabPack pack) async {
    _isLoading = true;
    _statusMessage = 'Starting download for "${pack.name}"...';
    notifyListeners();

    try {
      final documentsDir = await getApplicationDocumentsDirectory();

      _statusMessage = 'Downloading from ${pack.url}...';
      notifyListeners();
      final response = await http.get(Uri.parse(pack.url));
      if (response.statusCode != 200)
        throw Exception('Failed to download file: ${response.statusCode}');

      final bytes = response.bodyBytes;

      _statusMessage = 'Extracting files...';
      notifyListeners();
      final archive = ZipDecoder().decodeBytes(bytes);

      final packDir = Directory(p.join(documentsDir.path, pack.id));
      if (await packDir.exists()) await packDir.delete(recursive: true);
      await packDir.create(recursive: true);

      for (final file in archive) {
        final filename = file.name;
        final filePath = p.join(packDir.path, filename);

        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(filePath);
          await f.writeAsBytes(data, flush: true);
        }
      }
      _statusMessage = 'Download of "${pack.name}" complete!';

      // MODIFICATION: The following block that auto-loaded the vocabulary
      // and switched tabs has been removed.
    } catch (e) {
      _statusMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
      // Rescan for the new files. This will update the UI to show the
      // pack is downloaded, but will not auto-load it.
      await scanForLocalVocabulary();
    }
  }

  // UPDATED: Now scans all subdirectories in the documents folder.
  Future<void> scanForLocalVocabulary() async {
    _isLoading = true;
    notifyListeners();

    final documentsDir = await getApplicationDocumentsDirectory();
    final List<File> jsonFiles = [];
    final Set<String> newDownloadedPackIds = {};

    if (await documentsDir.exists()) {
      await for (var entity in documentsDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          jsonFiles.add(entity);
          final packId = p.basename(p.dirname(entity.path));
          newDownloadedPackIds.add(packId);
        }
      }
    }

    _downloadedPackIds = newDownloadedPackIds;
    _files = jsonFiles;

    // Check if the currently active file has been deleted.
    final activeFileExists =
        _activeFilePath != null && _files.any((f) => f.path == _activeFilePath);
    if (!activeFileExists) {
      _vocabulary = [];
      _activeFilePath = null;
      _currentCardIndex = 0;
      // If the file is gone, clear the persisted practice state.
      await _savePracticeState();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Methods for file and vocabulary management
  Future<void> addFiles(List<File> newFiles) async {
    _isLoading = true;
    notifyListeners();

    for (var file in newFiles) {
      if (!_files.any((f) => f.path == file.path)) {
        _files.add(file);
      }
    }

    // FIX: Remove auto-loading from here as well for consistent behavior.
    if (_files.isEmpty) {
      _vocabulary = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  void nextCard() {
    if (_vocabulary.isNotEmpty) {
      _currentCardIndex = (_currentCardIndex + 1) % _vocabulary.length;
      _savePracticeState();
      notifyListeners();
    }
  }

  void previousCard() {
    if (_vocabulary.isNotEmpty) {
      _currentCardIndex =
          (_currentCardIndex - 1 + _vocabulary.length) % _vocabulary.length;
      _savePracticeState();
      notifyListeners();
    }
  }

  Future<void> updateJpRepeats(int value) async {
    _jpRepeats = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jpRepeats', value);
    notifyListeners();
  }

  Future<void> updateEnRepeats(int value) async {
    _enRepeats = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('enRepeats', value);
    notifyListeners();
  }


  Future<void> updateDelay(int value) async {
    _delaySeconds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('delaySeconds', value);
    notifyListeners();
  }

  // Auto-play Methods
  void toggleAutoPlay(AudioService audioService) {
    if (_isAutoPlaying) {
      stopAutoPlay();
    } else {
      startAutoPlay(audioService);
    }
  }

  void startAutoPlay(AudioService audioService) {
    if (vocabulary.isEmpty || _isAutoPlaying) return;

    _isAutoPlaying = true;
    _audioServiceForAutoplay = audioService; // Store service for cycle
    notifyListeners();
    _runAutoPlayCycle();
  }

  void stopAutoPlay() {
    if (!_isAutoPlaying) return;

    _isAutoPlaying = false;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    _audioServiceForAutoplay?.stop(); // Stop any active audio
    _audioServiceForAutoplay = null;
    notifyListeners();
  }

  void _runAutoPlayCycle() async {
    if (!_isAutoPlaying || _audioServiceForAutoplay == null) return;

    final audioService = _audioServiceForAutoplay!;
    final card = currentCard;

    if (card == null || activeFilePath == null) {
      stopAutoPlay();
      return;
    }

    try {
      final mediaDir = p.dirname(activeFilePath!);

      for (int i = 0; i < jpRepeats; i++) {
        if (!_isAutoPlaying) return; // Check before each playback
        await audioService.playAudio(card.word, mediaDir, lang: 'ja');
        if (i < jpRepeats - 1) await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!_isAutoPlaying) return;
      await Future.delayed(Duration(seconds: delaySeconds));

      for (int i = 0; i < enRepeats; i++) {
        if (!_isAutoPlaying) return;
        await audioService.playAudio(card.english, mediaDir, lang: 'en');
        if (i < enRepeats - 1) await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!_isAutoPlaying) return;
      await Future.delayed(const Duration(seconds: 100));

      nextCard();

      // Schedule the next cycle
      _autoPlayTimer = Timer(const Duration(milliseconds: 100), _runAutoPlayCycle);
    } catch (e) {
      debugPrint("Error during auto-play cycle: $e");
      stopAutoPlay();
    }
  }
}
