import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int myInf = 999;

class DisplayItemCountNotifier extends ChangeNotifier {
  int _displayItemCount = myInf;
  static const String _displayItemCountKey = 'displayItemCount';

  int get displayItemCount => _displayItemCount;

  DisplayItemCountNotifier() {
    _init();
  }

  Future<void> _init() async {
    await _loadDisplayItemCount();
    notifyListeners(); // Notify listeners after loading the theme mode
  }

  Future<void> setDisplayItemCount(int i) async {
    _displayItemCount = i;
    await _saveDisplayItemCount();
    notifyListeners();
  }

  Future<void> _saveDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_displayItemCountKey, _displayItemCount);
  }

  Future<void> _loadDisplayItemCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int displayItemCount = prefs.getInt(_displayItemCountKey)!;
    _displayItemCount = displayItemCount;
  }
}
