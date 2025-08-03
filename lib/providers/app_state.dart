import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_jp/models/vocabulary_entry.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class AppState with ChangeNotifier {
  // The URL of your vocabulary pack.
  // Host this ZIP file somewhere public (e.g., GitHub, your own server).
  static const String DOWNLOAD_URL =
      'https://example.com/path/to/your/vocabulary.zip';

  List<File> _files = [];
  List<VocabularyEntry> _vocabulary = [];
  int _currentCardIndex = 0;
  String? _activeFilePath;

  // New state variables for download status
  bool _isLoading = false;
  String _statusMessage = '';

  // Settings
  int _jpRepeats = 2;
  int _enRepeats = 1;
  int _delaySeconds = 1;

  TabController? tabController;

  // Getters
  List<File> get files => _files;
  List<VocabularyEntry> get vocabulary => _vocabulary;
  int get currentCardIndex => _currentCardIndex;
  VocabularyEntry? get currentCard =>
      _vocabulary.isEmpty ? null : _vocabulary[_currentCardIndex];
  String? get activeFilePath => _activeFilePath;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  int get jpRepeats => _jpRepeats;
  int get enRepeats => _enRepeats;
  int get delaySeconds => _delaySeconds;

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

  // NEW: Scans the app's documents directory for .json files
  Future<void> scanForLocalVocabulary() async {
    _isLoading = true;
    notifyListeners();

    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(documentsDir.path);
    final List<File> jsonFiles = [];

    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: false)) {
        if (entity is File && entity.path.endsWith('.json')) {
          jsonFiles.add(entity);
        }
      }
    }

    _files = jsonFiles;
    if (_files.isNotEmpty) {
      await loadVocabulary(_files.first);
    }
    _isLoading = false;
    notifyListeners();
  }

  // NEW: The core download and unzip logic
  Future<void> downloadAndUnzipVocabulary() async {
    _isLoading = true;
    _statusMessage = 'Starting download...';
    notifyListeners();

    try {
      // 1. Get directory to save files
      final documentsDir = await getApplicationDocumentsDirectory();

      // 2. Download the ZIP file
      _statusMessage = 'Downloading from $DOWNLOAD_URL...';
      notifyListeners();
      final response = await http.get(Uri.parse(DOWNLOAD_URL));

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
      final bytes = response.bodyBytes;

      // 3. Unzip the file
      _statusMessage = 'Extracting files...';
      notifyListeners();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        final filePath = p.join(documentsDir.path, filename);

        if (file.isFile) {
          final data = file.content as List<int>;
          final f = File(filePath);
          await f.create(recursive: true);
          await f.writeAsBytes(data);
        } else {
          // It's a directory
          await Directory(filePath).create(recursive: true);
        }
      }

      _statusMessage = 'Download and extraction complete!';
      _isLoading = false;
      notifyListeners();

      // 4. Rescan for the new files
      await scanForLocalVocabulary();
    } catch (e) {
      _statusMessage = 'An error occurred: $e';
      _isLoading = false;
      notifyListeners();
    }
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

    if (_activeFilePath == null && _files.isNotEmpty) {
      await loadVocabulary(_files.first);
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

  // Methods for settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _jpRepeats = prefs.getInt('jpRepeats') ?? 2;
    _enRepeats = prefs.getInt('enRepeats') ?? 1;
    _delaySeconds = prefs.getInt('delaySeconds') ?? 1;
    notifyListeners();
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
