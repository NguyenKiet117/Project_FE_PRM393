import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;

  void setDark(bool dark) {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
