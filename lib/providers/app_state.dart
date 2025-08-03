import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_jp/models/vocabulary_entry.dart';

class AppState with ChangeNotifier {
  List<File> _files = [];
  List<VocabularyEntry> _vocabulary = [];
  int _currentCardIndex = 0;
  String? _activeFilePath;
  bool _isLoading = false;

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
  int get jpRepeats => _jpRepeats;
  int get enRepeats => _enRepeats;
  int get delaySeconds => _delaySeconds;

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
      // Switch to the practice tab automatically
      if (tabController != null) {
        tabController!.animateTo(1);
      }
    } catch (e) {
      print("Error loading or parsing JSON file: $e");
      _vocabulary = [];
      _activeFilePath = null;
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
