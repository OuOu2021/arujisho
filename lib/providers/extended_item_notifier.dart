import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpandedItemCountNotifier extends ChangeNotifier {
  int _expandedItemCount = 3;
  static const String _expandedItemCountKey = 'expandedItemCount';

  int get expandedItemCount => _expandedItemCount;

  ExpandedItemCountNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadExpandedItemCount();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setExpandedItemCount(int i) async {
    _expandedItemCount = i;
    await _saveExpandedItemCount();
    notifyListeners();
  }

  Future<void> _saveExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_expandedItemCountKey, _expandedItemCount);
  }

  Future<void> _loadExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int expandedItemCount = prefs.getInt(_expandedItemCountKey)!;
    _expandedItemCount = expandedItemCount;
  }
}
