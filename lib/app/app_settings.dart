import 'package:flutter/foundation.dart';

class AppSettings extends ChangeNotifier {
  bool advancedMode = false;

  void setAdvancedMode(bool value) {
    if (advancedMode == value) return;
    advancedMode = value;
    notifyListeners();
  }
}

final appSettings = AppSettings();