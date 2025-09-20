import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:heavy_new/core/api/api_handler.dart';
import 'package:heavy_new/core/models/admin/notifications_model.dart';
import 'package:heavy_new/core/models/firebase/crud_service.dart';
import 'package:heavy_new/foundation/ui/app_icons.dart';
import 'package:heavy_new/foundation/ui/ui_extras.dart';
import 'package:go_router/go_router.dart';
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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<_NotifItem> _items;
  Map payload = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //   Notifications.instance.wireOpenHandlers();
    });
  }

  void _go(_NotifItem n) {
    switch (n.type) {
      case 'chat_message':
        context.push('/chats/${n.entityId}');
        break;
      case 'contract_open':
        context.push('/contracts');
        break;
      case 'request_updated':
        context.push('/requests');
        break;
      default:
        // Stay here or future detail screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments;
    if (data is RemoteMessage) {
      payload = data.data;
    }
    if (data is NotificationResponse) {
      payload = jsonDecode(data.payload!);
    }
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _items[i];
          return Glass(
            radius: 16,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: AIcon(AppGlyph.bell, color: cs.onPrimaryContainer),
              ),
              title: Text(
                n.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(n.body),
              trailing: Text(
                _fmtAgo(n.createdAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () => _go(n),
            ),
          );
        },
      ),
    );
  }

  String _fmtAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _NotifItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final int? entityId;
  const _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    // ignore: unused_element_parameter
    this.entityId,
  });
}
