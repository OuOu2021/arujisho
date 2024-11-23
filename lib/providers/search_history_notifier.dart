import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends ChangeNotifier {
  List<String> _history = ['help['];
  static const String _historyCountKey = 'searchHistory';
  // List.generate(10, (index) => 'test${index + 1}');

  List<String> get history => List.unmodifiable(_history);
  bool get isEmpty => _history.isEmpty;
  bool get isNotEmpty => _history.isNotEmpty;
  String get last => _history.last;
  int get length => _history.length;

  SearchHistoryNotifier() {
    _loadHistory().then((_) => notifyListeners());
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_historyCountKey)) {
      List<String> hisotry = prefs.getStringList(_historyCountKey)!;
      _history = hisotry;
    }
  }

  Future<void> _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_historyCountKey, _history);
  }

  Future<void> add(String item) async {
    _history.add(item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> addToHead(String item) async {
    _history.insert(0, item);
    final logger = Logger();
    logger.d(history);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clear() async {
    _history.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> remove(String item) async {
    _history.remove(item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeLast() async {
    if (_history.isNotEmpty) {
      _history.removeLast();
      await _saveHistory();
      notifyListeners();
    }
  }
}
