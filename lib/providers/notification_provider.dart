import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _service = NotificationService();
  final _sb = SupabaseService.instance;
  StreamSubscription? _sub;

  List<AppNotification> _items = [];
  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  NotificationProvider() {
    _bind();
  }

  /// (Re)subscribe to the realtime stream for the current user. Call after
  /// login so a freshly signed-in user starts receiving notifications.
  void _bind() {
    _sub?.cancel();
    if (_sb.uid == null) {
      _items = [];
      notifyListeners();
      return;
    }
    _sub = _service.stream().listen((list) {
      _items = list;
      notifyListeners();
    }, onError: (_) {});
  }

  void refreshBinding() => _bind();

  Future<void> markRead(String id) async {
    // Optimistic update.
    final i = _items.indexWhere((n) => n.id == id);
    if (i != -1 && !_items[i].read) {
      _items[i] = AppNotification(
        id: _items[i].id,
        userId: _items[i].userId,
        kind: _items[i].kind,
        title: _items[i].title,
        body: _items[i].body,
        route: _items[i].route,
        routeArg: _items[i].routeArg,
        read: true,
        createdAt: _items[i].createdAt,
      );
      notifyListeners();
    }
    await _service.markRead(id);
  }

  Future<void> markAllRead() async {
    _items = _items
        .map((n) => AppNotification(
              id: n.id,
              userId: n.userId,
              kind: n.kind,
              title: n.title,
              body: n.body,
              route: n.route,
              routeArg: n.routeArg,
              read: true,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
    await _service.markAllRead();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
