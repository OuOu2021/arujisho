import 'package:flutter/material.dart';

class SearchHistoryNotifier extends ChangeNotifier {
  final List<String> _history = [""];

  List<String> get history => List.unmodifiable(_history);
  bool get isEmpty => _history.isEmpty;
  bool get isNotEmpty => _history.isNotEmpty;
  String get last => _history.last;
  int get length => _history.length;

  void add(String item) {
    _history.add(item);
    notifyListeners();
  }

  void clear() {
    _history.clear();
    notifyListeners();
  }

  void removeLast() {
    if (_history.isNotEmpty) {
      _history.removeLast();
      notifyListeners();
    }
  }
}
