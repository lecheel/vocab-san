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

  // NEW: A method to update the URL and save it to SharedPreferences
  Future<void> updateManifestUrl(String newUrl) async {
    _manifestUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('manifestUrl', newUrl);
    notifyListeners();
  }

  // Modified: This is now just for switching between already loaded files
  Future<void> loadVocabulary(File file) async {
    _isLoading = true;
    _activeFilePath = file.path;
    _currentCardIndex = 0;
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
    }

    _isLoading = false;
    notifyListeners();
  }

  // UPDATED: Now part of the loadSettings method
  @override
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
    final Set<String> newDownloadedPackIds = {}; // Create a temporary set

    if (await documentsDir.exists()) {
      // Scan subdirectories for json files
      await for (var entity in documentsDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.json')) {
          jsonFiles.add(entity);
          // NEW: Extract the pack ID from the path.
          // The pack ID is the name of the parent directory.
          final packId = p.basename(p.dirname(entity.path));
          newDownloadedPackIds.add(packId);
        }
      }
    }

    _downloadedPackIds = newDownloadedPackIds; // Update the main set
    _files = jsonFiles;

    // FIX: Do NOT auto-load a file. Instead, check if the *currently active*
    // file has been deleted. If so, clear the practice view.
    final activeFileExists =
        _activeFilePath != null && _files.any((f) => f.path == _activeFilePath);
    if (!activeFileExists) {
      _vocabulary = [];
      _activeFilePath = null;
      _currentCardIndex = 0;
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
      notifyListeners();
    }
  }

  void previousCard() {
    if (_vocabulary.isNotEmpty) {
      _currentCardIndex =
          (_currentCardIndex - 1 + _vocabulary.length) % _vocabulary.length;
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
}
