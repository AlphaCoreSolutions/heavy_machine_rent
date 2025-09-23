import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api;

/// UI model used by the bell & list
class NotifItem {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type; // 'chat_message', 'request_updated', ...
  final int? entityId;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.entityId,
  });

  factory NotifItem.fromRemoteMessage(RemoteMessage m) {
    final d = m.data;
    final id = int.tryParse('${d['id'] ?? d['message_id'] ?? 0}') ?? 0;
    final type = (d['type'] ?? '').toString();
    final entityId = int.tryParse('${d['entityId'] ?? d['entity_id'] ?? ''}');
    return NotifItem(
      id: id,
      title: d['title']?.toString() ?? m.notification?.title ?? 'Notification',
      body: d['message']?.toString() ?? m.notification?.body ?? '',
      createdAt: DateTime.now(),
      type: type.isEmpty ? 'generic' : type,
      entityId: entityId,
    );
  }

  /// If your backend returns notifications, adapt this:
  factory NotifItem.fromJson(Map<String, dynamic> j) {
    return NotifItem(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? 0}') ?? 0,
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? j['message'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${j['createdAt'] ?? j['created_at'] ?? ''}') ??
          DateTime.now(),
      type: (j['type'] ?? 'generic').toString(),
      entityId: (j['entityId'] ?? j['entity_id']) == null
          ? null
          : int.tryParse('${j['entityId'] ?? j['entity_id']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
    'entityId': entityId,
  };
}

class NotificationsStore extends ChangeNotifier {
  NotificationsStore({api.Api? apiClient})
    : _api = apiClient ?? api.Api(),
      _fcm = FirebaseMessaging.instance;

  final api.Api _api;
  final FirebaseMessaging _fcm;

  final List<NotifItem> _items = <NotifItem>[];
  List<NotifItem> get items => List.unmodifiable(_items);

  bool _initialized = false;

  /// Call once during app startup
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Try to hydrate from backend (if your API supports it)
    await _hydrateFromBackend();

    // 2) Wire FCM streams
    FirebaseMessaging.onMessage.listen((m) {
      try {
        _addOrReplace(NotifItem.fromRemoteMessage(m));
      } catch (e) {
        log('onMessage parse error: $e');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      try {
        _addOrReplace(NotifItem.fromRemoteMessage(m));
      } catch (e) {
        log('onMessageOpenedApp parse error: $e');
      }
    });

    // 3) If app opened from a terminated state via a notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      try {
        _addOrReplace(NotifItem.fromRemoteMessage(initial));
      } catch (e) {
        log('initialMessage parse error: $e');
      }
    }
  }

  /// Fetch last N notifications from your backend
  Future<void> _hydrateFromBackend() async {
    try {
      // Replace with your actual endpoint if available.
      // For example: final list = await _api.getUserNotifications();
      // Here we attempt a dynamic call; if not present, we skip gracefully.
      final client = _api;
      final dynamic maybe = await (client as dynamic).getUserNotifications
          ?.call();
      if (maybe is List) {
        final parsed = maybe
            .whereType<Map<String, dynamic>>()
            .map(NotifItem.fromJson)
            .toList();
        _items
          ..clear()
          ..addAll(parsed);
        _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (_) {
      // No endpoint? fine—live only from FCM.
    }
  }

  /// If you want to push from anywhere (e.g. when handling a local tap)
  void addLocal(NotifItem n) => _addOrReplace(n);

  /// Helper: keep newest first; replace same id
  void _addOrReplace(NotifItem n) {
    final i = _items.indexWhere((e) => e.id == n.id && n.id != 0);
    if (i >= 0) {
      _items[i] = n;
    } else {
      _items.insert(0, n);
      // (optional) cap list length
      if (_items.length > 100) _items.removeRange(100, _items.length);
    }
    notifyListeners();
  }

  /// For the bell dropdown
  List<NotifItem> recent([int n = 6]) =>
      (_items..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(n)
          .toList();

  void removeById(int id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
