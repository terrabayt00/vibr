import 'package:flutter/material.dart';

class AppData with ChangeNotifier {
  int _indexMenu = 0;

  int get getIndexMenu => _indexMenu;

  void updateSelectedMenu(int selectedIndex) {
    _indexMenu = selectedIndex;
    notifyListeners();
  }
}
