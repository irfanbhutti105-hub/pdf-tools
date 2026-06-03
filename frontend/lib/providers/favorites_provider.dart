import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/tools_data.dart';
import '../models/pdf_tool.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _storageKey = 'favorite_tool_ids';

  Set<String> _ids = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<PdfTool> get favoriteTools {
    final tools = <PdfTool>[];
    for (final id in _ids) {
      final tool = allTools.where((t) => t.id == id).firstOrNull;
      if (tool != null) tools.add(tool);
    }
    return tools;
  }

  bool isFavorite(String toolId) => _ids.contains(toolId);

  FavoritesProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _ids = (prefs.getStringList(_storageKey) ?? []).toSet();
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(String toolId) async {
    if (_ids.contains(toolId)) {
      _ids.remove(toolId);
    } else {
      _ids.add(toolId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _ids.toList());
  }
}
