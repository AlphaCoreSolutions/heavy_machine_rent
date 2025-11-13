import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ajjara/core/api/api_handler.dart' as api;

/// UI model used by the bell & list
class NotifItem {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type; // 'chat_message', 'request_updated', ...
  final int? entityId;

  /// NEW: whether user has opened/read this notif
  final bool opened;

  /// NEW: route to navigate when tapped (preferred over type)
  final String? screenPath;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.entityId,
    this.opened = false,
    this.screenPath,
  });

  NotifItem copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? createdAt,
    String? type,
    int? entityId,
    bool? opened,
    String? screenPath,
  }) {
    return NotifItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      opened: opened ?? this.opened,
      screenPath: screenPath ?? this.screenPath,
    );
  }

  factory NotifItem.fromRemoteMessage(RemoteMessage m) {
    final d = m.data;
    final id = int.tryParse('${d['id'] ?? d['message_id'] ?? 0}') ?? 0;
    final type = (d['type'] ?? '').toString();
    final entityId = int.tryParse('${d['entityId'] ?? d['entity_id'] ?? ''}');
    final screenPath = (d['screenPath'] ?? d['screen_path'] ?? '')
        .toString()
        .trim();

    return NotifItem(
      id: id,
      title: d['title']?.toString() ?? m.notification?.title ?? 'Notification',
      body: d['message']?.toString() ?? m.notification?.body ?? '',
      createdAt: DateTime.now(),
      type: type.isEmpty ? 'generic' : type,
      entityId: entityId,
      opened: false,
      screenPath: screenPath.isEmpty ? null : screenPath,
    );
  }

  /// If your backend returns notifications, adapt this:
  factory NotifItem.fromJson(Map<String, dynamic> j) {
    final created = (j['createdAt'] ?? j['created_at'] ?? '').toString();
    final sp = (j['screenPath'] ?? j['screen_path'] ?? '').toString().trim();

    return NotifItem(
      id: j['id'] is int ? j['id'] : int.tryParse('${j['id'] ?? 0}') ?? 0,
      title: (j['title'] ?? '').toString(),
      body: (j['body'] ?? j['message'] ?? '').toString(),
      createdAt: DateTime.tryParse(created) ?? DateTime.now(),
      type: (j['type'] ?? 'generic').toString(),
      entityId: (j['entityId'] ?? j['entity_id']) == null
          ? null
          : int.tryParse('${j['entityId'] ?? j['entity_id']}'),
      opened: (j['opened'] ?? j['isRead'] ?? j['seen'] ?? false) == true,
      screenPath: sp.isEmpty ? null : sp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
    'entityId': entityId,
    'opened': opened,
    'screenPath': screenPath,
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
  int? _lastUserId; // remember current user for refresh()

  /// Call once during app startup (e.g., in main after login wiring)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Wire FCM streams
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

    // If app was opened from terminated via a notification
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      try {
        _addOrReplace(NotifItem.fromRemoteMessage(initial));
      } catch (e) {
        log('initialMessage parse error: $e');
      }
    }
  }

  /// Load for a given user. If [unreadOnly] is true, fetch only unseen items.
  Future<void> loadForUser({
    required int userId,
    bool unreadOnly = false,
  }) async {
    _lastUserId = userId;

    // Try backend first; fall back to no-op if endpoint is missing.
    try {
      // TODO: Replace with your real endpoint(s).
      // Examples you might have:
      // final raw = await _api.getUserNotifications(userId, unreadOnly: unreadOnly);
      // or:
      // final raw = await _api.advanceSearchNotifications({'userId': userId, 'unreadOnly': unreadOnly});
      final client = _api as dynamic;

      dynamic raw;
      if (client.getUserNotifications != null) {
        raw = await client.getUserNotifications(
          userId: userId,
          unreadOnly: unreadOnly,
        );
      } else if (client.advanceSearchNotifications != null) {
        raw = await client.advanceSearchNotifications({
          'userId': userId,
          'unreadOnly': unreadOnly,
        });
      }

      if (raw is List) {
        final parsed =
            raw
                .whereType<Map>()
                .map((e) => NotifItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _items
          ..clear()
          ..addAll(parsed);
        notifyListeners();
        return;
      }
    } catch (e) {
      log('loadForUser: backend fetch failed: $e');
    }

    // If we got here, backend isn’t available: keep current list (FCM-only)
    notifyListeners();
  }

  /// Refresh for the last loaded user.
  Future<void> refresh({bool unreadOnly = false}) async {
    if (_lastUserId == null) return;
    await loadForUser(userId: _lastUserId!, unreadOnly: unreadOnly);
  }

  /// Mark a notification as read both locally and (if available) on backend.
  Future<void> markAsRead(int id) async {
    // optimistic local update
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx >= 0 && _items[idx].opened == false) {
      _items[idx] = _items[idx].copyWith(opened: true);
      notifyListeners();
    }

    // backend best-effort
    try {
      final client = _api as dynamic;
      // TODO: Replace with your real endpoints:
      // e.g., await _api.markNotificationRead(id);
      if (client.markNotificationRead != null) {
        await client.markNotificationRead(id);
      } else if (client.updateNotification != null) {
        await client.updateNotification({'id': id, 'opened': true});
      }
    } catch (e) {
      log('markAsRead failed (ignored): $e');
    }
  }

  /// Clear in-memory notifications (call this on logout).
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// For pushing a local item (rarely needed)
  void addLocal(NotifItem n) => _addOrReplace(n);

  /// For the bell dropdown
  List<NotifItem> recent([int n = 6]) =>
      (_items..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(n)
          .toList();

  void removeById(int id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---- internals ----
  void _addOrReplace(NotifItem n) {
    final i = _items.indexWhere((e) => e.id == n.id && n.id != 0);
    if (i >= 0) {
      _items[i] = n;
    } else {
      _items.insert(0, n);
      if (_items.length > 200) _items.removeRange(200, _items.length);
    }
    notifyListeners();
  }
}
