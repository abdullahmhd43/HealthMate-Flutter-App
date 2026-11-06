import 'package:flutter/foundation.dart';

/// Holds the selected bottom-navigation tab so any screen can switch tabs
/// (for example "See all" on the dashboard jumps to History).
class ShellController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void goTo(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}
