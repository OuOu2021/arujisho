import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int myInf = 999;

class ItemCountNotifier extends ChangeNotifier {
  int _displayItemCount = myInf;
  int _expandedItemCount = 3;
  static const String _displayItemCountKey = 'displayItemCount';
  static const String _expandedItemCountKey = 'expandedItemCount';

  int get displayItemCount => _displayItemCount;
  int get expandedItemCount => _expandedItemCount;

  ItemCountNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadDisplayItemCount();
    await _loadExpandedItemCount();
    notifyListeners();
  }

  Future<void> setDisplayItemCount(int i) async {
    _displayItemCount = i;
    await _saveDisplayItemCount();
    if (_displayItemCount < expandedItemCount) {
      _expandedItemCount = i;
      await _saveExpandedItemCount();
    }
    notifyListeners();
  }

  Future<void> setExpandedItemCount(int i) async {
    _expandedItemCount = i;
    await _saveExpandedItemCount();
    if (_expandedItemCount > _displayItemCount) {
      _displayItemCount = i;
      await _saveDisplayItemCount();
    }
    notifyListeners();
  }

  Future<void> _saveDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_displayItemCountKey, _displayItemCount);
  }

  Future<void> _saveExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_expandedItemCountKey, _expandedItemCount);
  }

  Future<void> _loadDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? displayItemCount = prefs.getInt(_displayItemCountKey);
    if (displayItemCount != null && displayItemCount >= 1) {
      _displayItemCount = displayItemCount;
    }
  }

  Future<void> _loadExpandedItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? expandedItemCount = prefs.getInt(_expandedItemCountKey);
    if (expandedItemCount != null && expandedItemCount >= 1) {
      _expandedItemCount = expandedItemCount;
    }
  }
}
