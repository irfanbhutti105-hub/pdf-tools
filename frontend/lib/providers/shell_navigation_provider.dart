import 'package:flutter/foundation.dart';

/// Lets nested screens (e.g. Home) request a bottom-nav tab switch.
class ShellNavigationProvider extends ChangeNotifier {
  int? _pendingTab;

  int? consumePendingTab() {
    final tab = _pendingTab;
    _pendingTab = null;
    return tab;
  }

  void requestTab(int index) {
    _pendingTab = index;
    notifyListeners();
  }
}

/// Bottom-nav index for the CV Maker tab.
const kCvMakerTabIndex = 2;
