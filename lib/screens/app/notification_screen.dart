import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/core/api/api_handler.dart' as api show Api;
import 'package:heavy_new/core/models/admin/notifications_model.dart';
import 'package:heavy_new/core/models/firebase/crud_service.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:go_router/go_router.dart';
import 'package:heavy_new/foundation/widgets/notifications_store.dart';
import 'package:heavy_new/main.dart';

class Notifications {
  final api = Api();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  //register notification permissions
  Future<void> init() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    log('message permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
    }
  }

  Future getDeviceToken() async {
    String? token = await _messaging.getToken();
    log('device Token: $token');
    await CrudService.saveUserToken(token ?? '');
    log('token saved to database');

    _messaging.onTokenRefresh.listen((event) async {
      log('device Token refreshed: $event');
      await CrudService.saveUserToken(event);
      log('refreshed token saved to database');
    });
  }

  Future<UserMessage> sendNotification() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('No FCM token available for this device.');
    }
    User? user = FirebaseAuth.instance.currentUser;

    final msg = UserMessage(
      userId: int.tryParse(user?.uid ?? '0'),
      messageArabic: 'من زمان عنك!',
      messageEnglish: 'It\'s been a long time, welcome back!',
      titleArabic: 'أهلاً وسهلاً',
      titleEnglish: 'Welcome Back!',
      token: token,
      screenId: 1,
      screenPath: 'home',
      senderId: 1,
      modelId: 0,
      platformId: 1,
      userMessageId: 0,
      imagePath: '',
      mainMessageId: 0,
      screenArabic: '',
      screenEnglish: '',
    );

    return Api.sendNotif(msg);
  }

  void handleMessage(RemoteMessage message) {
    log('Message data: ${message.data}');
    if (message.notification != null) {
      log('Message also contained a notification: ${message.notification}');
    }

    final data = message.data;
    final title = data['title'] ?? message.notification?.title ?? 'no title';
    final body = data['message'] ?? message.notification?.body ?? 'no message';

    log('Notification: $title / $body');
  }

  //initialize local notifications
  Future<void> initLocalNotifications() async {
    const AndroidInitializationSettings androidinitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDrawIn =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const LinuxInitializationSettings linuxInitializationSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidinitializationSettings,
          iOS: initializationSettingsDrawIn,
          linux: linuxInitializationSettings,
        );

    _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!
        .requestNotificationsPermission();

    _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  static void onNotificationTap(NotificationResponse response) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (response.payload == null) {
      nav.pushNamed('/notifications');
      return;
    }
    try {
      // OK: your NotificationsScreen already jsonDecodes this too.
      nav.pushNamed('/notifications', arguments: response);
    } catch (e) {
      log('payload decode error: $e');
      nav.pushNamed('/notifications');
    }
  }

  static Future showSimpleNotifications({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await Notifications._localNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _query = '';
  String?
  _typeFilter; // 'chat_message' | 'contract_open' | 'request_updated' | null
  StreamSubscription<User?>? _authSub;

  // ---- lifecycle / auth wiring ----
  @override
  void initState() {
    super.initState();
    _ensureLoadedForCurrentUser(unreadOnly: true);

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // logged out -> clear in-memory list
        notificationsStore.clear();
        if (mounted) setState(() {});
      } else {
        // logged in -> load unseen for this user
        await _ensureLoadedForCurrentUser(unreadOnly: true);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Resolve your backend's numeric userId. Prefer your own session/user model.
  Future<int?> _resolveAppUserId() async {
    // TODO: If your app already knows the numeric user id, return it here, e.g.:
    // return api.Api.currentUser?.userId;

    // Fallback: sometimes your Firebase UID is numeric in your environment.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fromUid = int.tryParse(uid ?? '');
    return fromUid; // may be null
  }

  Future<void> _ensureLoadedForCurrentUser({bool unreadOnly = false}) async {
    try {
      final userId = await _resolveAppUserId();

      if (userId == null) {
        // If you can load "current user" notifs by token on server side,
        // keep this call; otherwise nothing to do here.
        await notificationsStore.refresh(unreadOnly: unreadOnly);
        if (mounted) setState(() {});
        return;
      }

      // 🔹 You asked to use this endpoint: validate/token-hydrate by userId
      try {
        await api.Api.getNotfTokenById(userId);
      } catch (_) {
        // If token lookup fails, we still attempt to load notifs below.
      }

      // Load unseen (or all) for that user
      await notificationsStore.loadForUser(
        userId: userId,
        unreadOnly: unreadOnly,
      );
    } catch (_) {
      // Ignore; FCM live updates will still populate the store.
    }

    if (mounted) setState(() {});
  }

  // --- utils ---
  String _fmtAgo(DateTime t) {
    final now = DateTime.now();
    final d = now.difference(t);
    if (d.inSeconds < 5) return 'now';
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d2 = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d2';
  }

  AppGlyph _iconFor(String type) {
    switch (type) {
      case 'chat_message':
        return AppGlyph.chat;
      case 'contract_open':
        return AppGlyph.fileText;
      case 'request_updated':
        return AppGlyph.refresh;
      default:
        return AppGlyph.bell;
    }
  }

  Color _tintFor(BuildContext ctx, String type) {
    final cs = Theme.of(ctx).colorScheme;
    switch (type) {
      case 'chat_message':
        return cs.primaryContainer;
      case 'contract_open':
        return cs.tertiaryContainer;
      case 'request_updated':
        return cs.secondaryContainer;
      default:
        return cs.surfaceVariant;
    }
  }

  Map<String, List<NotifItem>> _group(List<NotifItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: today.weekday % 7));

    final Map<String, List<NotifItem>> out = {
      'Today': [],
      'Yesterday': [],
      'This week': [],
      'Earlier': [],
    };

    for (final n in items) {
      final t = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (t.isAtSameMomentAs(today)) {
        out['Today']!.add(n);
      } else if (t.isAtSameMomentAs(yesterday)) {
        out['Yesterday']!.add(n);
      } else if (t.isAfter(weekStart)) {
        out['This week']!.add(n);
      } else {
        out['Earlier']!.add(n);
      }
    }
    out.removeWhere((_, v) => v.isEmpty);
    return out;
  }

  List<NotifItem> _filter(List<NotifItem> items) {
    final q = _query.trim().toLowerCase();
    return items.where((n) {
      final okType = _typeFilter == null || n.type == _typeFilter;
      final okQuery =
          q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q);
      return okType && okQuery;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _refresh() async {
    try {
      await notificationsStore.refresh(unreadOnly: false);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _go(NotifItem n) async {
    // 1) mark as read (best-effort) — only on tap, so it **stays** until pressed
    try {
      await notificationsStore.markAsRead(n.id);
    } catch (_) {}

    // 2) route by screenPath if present
    final sp = (n.screenPath ?? '').trim();
    if (sp.isNotEmpty) {
      final route = sp.startsWith('/') ? sp : '/$sp';
      if (mounted) context.push(route);
      return;
    }

    // 3) fallback: type-based routing
    switch (n.type) {
      case 'chat_message':
        if (mounted) context.push('/chats/${n.entityId}');
        break;
      case 'contract_open':
        if (mounted) context.push('/contracts');
        break;
      case 'request_updated':
        if (mounted) context.push('/requests');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // handle payload if navigated via local notification tap
    final data = ModalRoute.of(context)!.settings.arguments;
    if (data is NotificationResponse) {
      final payload = data.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          // ignore: unused_local_variable
          final _ = jsonDecode(payload);
        } catch (_) {}
      }
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: notificationsStore,
        builder: (_, __) {
          final filtered = _filter(notificationsStore.items);
          final grouped = _group(filtered);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 16,
                  title: const Text('Notifications'),
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () {},
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    const SizedBox(width: 4),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(78),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search notifications',
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant.withOpacity(.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 34,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _FilterChip(
                                  icon: AppGlyph.all,
                                  label: 'All',
                                  selected: _typeFilter == null,
                                  onTap: () =>
                                      setState(() => _typeFilter = null),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  icon: AppGlyph.chat,
                                  label: 'Chat',
                                  selected: _typeFilter == 'chat_message',
                                  onTap: () => setState(
                                    () => _typeFilter = 'chat_message',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  icon: AppGlyph.fileText,
                                  label: 'Contracts',
                                  selected: _typeFilter == 'contract_open',
                                  onTap: () => setState(
                                    () => _typeFilter = 'contract_open',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  icon: AppGlyph.refresh,
                                  label: 'Requests',
                                  selected: _typeFilter == 'request_updated',
                                  onTap: () => setState(
                                    () => _typeFilter = 'request_updated',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (filtered.isEmpty) ...[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onRefresh: _refresh),
                  ),
                ] else ...[
                  for (final entry in grouped.entries) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    SliverList.separated(
                      itemCount: entry.value.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = entry.value[i];
                        final tint = _tintFor(context, n.type);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Glass(
                            radius: 16,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _go(n),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // leading icon
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: tint,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: AIcon(
                                          _iconFor(n.type),
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // time
                                    Text(
                                      _fmtAgo(n.createdAt),
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- small, reusable widgets (unchanged) ---

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppGlyph icon;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? cs.primaryContainer
        : cs.surfaceVariant.withOpacity(.6);
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withOpacity(.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AIcon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Glass(
              radius: 24,
              child: Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You’re all caught up',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'When you receive notifications, they’ll show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
