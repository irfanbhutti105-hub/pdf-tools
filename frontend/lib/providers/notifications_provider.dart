import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });
}

class NotificationsProvider extends ChangeNotifier {
  final List<AppNotification> _items = [];

  NotificationsProvider() {
    _seed();
  }

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.read).length;

  void markAllRead() {
    for (final n in _items) {
      n.read = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _items[idx].read = true;
    notifyListeners();
  }

  void add(AppNotification n) {
    _items.insert(0, n);
    notifyListeners();
  }

  void _seed() {
    if (_items.isNotEmpty) return;
    _items.addAll([
      AppNotification(
        id: 'welcome',
        title: 'Welcome',
        message: 'Thanks for using PDF Tools. Try Merge, Split, Compress and more.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      AppNotification(
        id: 'privacy',
        title: 'Privacy reminder',
        message: 'Processed files are available for 24 hours in History.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);
  }
}

